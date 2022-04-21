=head1 LICENSE

See the NOTICE file distributed with this work for additional information
regarding copyright ownership.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Gene2phenotype::Controller::GenomicFeatureDiseasePanel;
use base qw(Gene2phenotype::Controller::BaseController);
use strict;
use warnings;

=head2 add
  Description: Add a GenomicFeatureDisease to a panel in the G2P database.
               Based on the user input we check if we already store an
               entry in the database that fits the description and can be annotated
               rather than creating a new entry. If that is the case the user
               will be presented with all exisiting entries based on the same
               gene symbol, allelic requirement and mutation consequence and
               the user can then make a final decision on how to proceed:
               - choose to add an exisiting GFD to the target panel
               - create a new GFD and add to the target panel
               If there are no GFDs that already fit the user input
               a new GFD is created, added to the target panel and the user
               is directed to the new page.
  Returntype :
  Exceptions : None
  Caller     : Template: add_new_entry.html.ep
               Request: GET /gene2phenotype/gfd_panel/add
               Params:
                   Add button:
                     panel                          - Add new entry to this panel
                     gene_symbol                    - Gene symbol representing gene in the GFD
                     disease_name                   - Disease name representing the disease in the GFD
                     confidence_attrib_id           - Confidence attrib for the GFDPanel
                     allelic_requirement_attrib_id  - Allelic requirement attrib of the GFD. Can be more than one.
                     mutation_consequence_attrib_id - Mutation consequence attrib of the GFD. Can be more than one

                   Add exisiting GFD to target panel button:
                     add_existing_entry_to_panel  - This is set to 1 if the GFD is already in the database
                                                    and should be added to the specified panel.
                     gfd_id                       - Database id of the exisiting GFD.
                     confidence_value_to_be_added - Confidence value for the GFDPanel
                     panel                        - Add new entry to this panel

                   Create new GFD and add to target panel button:
                     create_new_gfd                   - This is set to 1 if we need to create a new GFD first before adding
                                                        it to the panel.
                     gene_symbol                      - Gene symbol representing gene in the GFD
                     disease_name                     - Disease name representing the disease in the GFD
                     allelic_requirement_to_be_added  - Allelic requirement value of the GFD. Can be more than one.
                     mutation_consequence_to_be_added - Mutation consequence value of the GFD
                     confidence_value_to_be_added     - Confidence value for the GFDPanel
                     panel                            - Add new entry to this panel
  Status     : Stable
=cut

sub add {
  my $self = shift;

  my $target_panel                   = $self->param('panel');
  my $gene_symbol                    = $self->param('gene_symbol');
  my $disease_name                   = $self->param('disease_name');
  my $confidence_attrib_id           = $self->param('confidence_attrib_id');
  my $allelic_requirement_attrib_ids = join(',', sort @{$self->every_param('allelic_requirement_attrib_id')});
  my $mutation_consequence_attrib_ids = join(',', sort @{$self->every_param('mutation_consequence_attrib_id')});

  my $email = $self->session('email');
  my $gfd_model = $self->model('genomic_feature_disease');  
  my $gfd_panel_model = $self->model('genomic_feature_disease_panel');
  my $user_model = $self->model('user');

  if (defined $self->param('add_existing_entry_to_panel') && $self->param('add_existing_entry_to_panel') == 1) {
    my $gfd_id = $self->param('gfd_id');
    $self->add_gfd_to_panel($gfd_id);
    return;
  } 
 
  if (defined $self->param('create_new_gfd') && $self->param('create_new_gfd') == 1) {
    my $gfd = $self->create_gfd();
    my $gfd_id = $gfd->dbID;
    $self->add_gfd_to_panel($gfd_id);
    return;
  } 

  my $gf_model = $self->model('genomic_feature');
  my $gf = $gf_model->fetch_by_gene_symbol($gene_symbol); 
  if (!$gf) {
    $self->feedback_message('GF_NOT_IN_DB');
    return $self->redirect_to("/gene2phenotype/gfd/show_add_new_entry_form");
  }

  my $disease_model = $self->model('disease');
  my $disease = $disease_model->fetch_by_name($disease_name);
  if (!$disease) {
    $disease = $disease_model->add($disease_name);
  }
  # Find exisiting GFDs with the same gene symbol, allelic requirement and mutation consequence
  my $gfds = $gfd_model->fetch_all_by_GenomicFeature_constraints($gf, {
    'mutation_consequence_attrib' => $mutation_consequence_attrib_ids,
    'allelic_requirement_attrib' => $allelic_requirement_attrib_ids,
  });
  if (scalar @$gfds == 0) {
    # No GFDs with the same gene symbol, allelic requirement and mutation consequence exist
    # We will create a new GFD
    my $gfd = $self->create_gfd();
    my $gfd_id = $gfd->dbID;
    $self->add_gfd_to_panel($gfd_id);
    return;
  } else {
    # Check if a GFD with same gene symbol, allelic requirement, mutation consequence and disease name exists
    my $existing_gfds = _get_existing_gfds($gfds, $disease->dbID, $target_panel);
    if ($existing_gfds->{same_disease_target_panel}) {
      # If GFD already exists and is also already in the target panel
      # send user to GFD page
      my $gfd = $existing_gfds->{same_disease_target_panel};
      my $gfd_id = $gfd->dbID;
      $self->feedback_message('GFD_IN_DB');
      return $self->redirect_to("/gene2phenotype/gfd?GFD_id=$gfd_id");   
    } else {
      # Send user back to add new entry page
      # And show the existing GFDs
      # User can then choose to add an exisiting GFD to the target panel
      # Or create a new GFD and add the new GFD to the target panel
      my $allelic_requirement_to_be_added = $gfd_model->get_value('allelic_requirement', $allelic_requirement_attrib_ids);
      my $mutation_consequence_to_be_added = $gfd_model->get_value('mutation_consequence', $mutation_consequence_attrib_ids);
      my $confidence_value_to_be_added = $gfd_model->get_value('confidence_category', $confidence_attrib_id);
      my $user = $user_model->fetch_by_email($email);
      my @panels = split(',', $user->panel);
      $self->stash(
        existing_gfds => $existing_gfds,
        new_gfd => {
          mutation_consequence_to_be_added => $mutation_consequence_to_be_added,
          allelic_requirement_to_be_added => $allelic_requirement_to_be_added,
          gene_symbol => $gene_symbol,
          disease_name => $disease_name,
        },
        confidence_value_to_be_added => $confidence_value_to_be_added,
        confidence_values => $gfd_model->get_confidence_values,
        mutation_consequences =>  $gfd_model->get_mutation_consequences,
        mutation_consequence_to_be_added => $mutation_consequence_to_be_added,
        allelic_requirements => $gfd_model->get_allelic_requirements,
        allelic_requirement_to_be_added => $allelic_requirement_to_be_added,
        gene_symbol => $gene_symbol,
        disease_name => $disease_name,
        panel => $target_panel,
        panels => \@panels
      );
      return $self->render(template => 'add_new_entry');
    }
  }
}

=head2 create_gfd
  Description: Create a new GenomicFeatureDisease from user input parameters
  Returntype : GenomicFeatureDisease
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDiseasePanel::add
  Status     : Stable
=cut

sub create_gfd {
  my $self = shift;
  my $email = $self->session('email');
  my $gfd_model = $self->model('genomic_feature_disease');  

  my $allelic_requirement = $self->param('allelic_requirement_to_be_added');
  if (!defined $allelic_requirement) {
    my $allelic_requirement_attrib_ids = join(',', sort @{$self->every_param('allelic_requirement_attrib_id')});
    $allelic_requirement = $gfd_model->get_value('allelic_requirement', $allelic_requirement_attrib_ids);
  }
  my $mutation_consequence = $self->param('mutation_consequence_to_be_added');
  if (!defined $mutation_consequence) {
    my $mutation_consequence_attrib_ids = join(',', sort @{$self->every_param('mutation_consequence_attrib_id')});
    $mutation_consequence = $gfd_model->get_value('mutation_consequence', $mutation_consequence_attrib_ids);
  }

  my $gfd = $gfd_model->add(
    $self->param('gene_symbol'),
    $self->param('disease_name'),
    $allelic_requirement,
    $mutation_consequence,
    $email
  );
  return $gfd;
}

=head2 add_gfd_to_panel
  Description: Add GenomicFeatureDisease to panel
  Returntype : Redirect to GenomicFeatureDisease page
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDiseasePanel::add
  Status     : Stable
=cut

sub add_gfd_to_panel {
  my $self = shift;
  my $gfd_id = shift;
  my $email = $self->session('email');
  my $gfd_panel_model = $self->model('genomic_feature_disease_panel');
  my $gfd_model = $self->model('genomic_feature_disease');

  my $confidence_value = $self->param('confidence_value_to_be_added');
  if (!defined $confidence_value) {
    my $confidence_attrib_id = $self->param('confidence_attrib_id');
    $confidence_value = $gfd_model->get_value('confidence_category', $confidence_attrib_id);
  }

  my $gfd_panel = $gfd_panel_model->add(
    $gfd_id,
    $self->param('panel'),
    $confidence_value,
    $email
  );
  $self->feedback_message('ADDED_GFD_SUC');

  $self->redirect_to("/gene2phenotype/gfd?GFD_id=$gfd_id");
}

=head2 _get_exisiting_gfds
  Arg[1]     : Arrayref of GenomicFeatureDisease $gfds
  Arg[2]     : Integer $new_disease_id - Database id of target disease as
               provided by the user
  Arg[3]     : String $target_panel - Panel is provided by the user and
               the new entry should be added to that panel.
  Description: All $gfds have the same gene symbol, allelic requirement
               and mutation consequence as defined by the user. This method
               categorises them in the following way:
               Identify GFDs with:
               - same disease and target panel
               - same disease and non-target panel
               - different disease and target panel
               - different disease and non-target panel
  Returntype : Hashref where keys are the different categories:
               - same_disease_target_panel
               - same_disease_non_target_panel
               - different_disease_target_panel
               - different_disease_non_target_panel
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDiseasePanel::add
  Status     : Stable
=cut

sub _get_existing_gfds {
  my $gfds = shift;
  my $new_disease_id = shift;
  my $target_panel = shift;
  my $existing_gfds;
  foreach my $gfd (@$gfds) {
    my @disease_name_synonyms = map {$_->get_Disease->name } @{$gfd->get_all_GFDDiseaseSynonyms};
    my $is_target_panel = grep {$target_panel eq $_} @{$gfd->panels};
    my $disease_id = $gfd->get_Disease->dbID;
    my $exisiting_gfd = {
      mutation_consequence =>  $gfd->mutation_consequence,
      allelic_requirement => $gfd->allelic_requirement,
      gene_symbol => $gfd->get_GenomicFeature->gene_symbol,
      disease_name => $gfd->get_Disease->name,
      disease_name_synonyms => \@disease_name_synonyms,
      panels => $gfd->panels,
      gfd_id => $gfd->dbID,
    };
    if ($disease_id == $new_disease_id && $is_target_panel) {
      $existing_gfds->{same_disease_target_panel} = $gfd;
    } elsif ($disease_id == $new_disease_id && !$is_target_panel) {
      push @{$existing_gfds->{same_disease_non_target_panel}}, $exisiting_gfd;
    } elsif ($disease_id != $new_disease_id && $is_target_panel) {
      push @{$existing_gfds->{different_disease_target_panel}}, $exisiting_gfd;
    } else {
      push @{$existing_gfds->{different_disease_non_target_panel}}, $exisiting_gfd;
    }
  }
  return $existing_gfds;
}

=head2 update_visibility
  Description: Update the visibility setting of a GenomicFeatureDiseasePanel
  Exceptions : None
  Caller     : Template: user/gfd_attributes.html.ep
               Request: GET /gene2phenotype/gfd_panel/authorised/update
               Params:
                   visibility - The value is either authorised or restricted
                   GFD_id - database id of the GenomicFeatureDisease
                   GFD_panel_id - database id the GenomicFeatureDiseasePanel
  Status     : Stable
=cut

sub update_visibility {
  my $self = shift;
  my $GFD_id = $self->param('GFD_id');
  my $GFD_panel_id = $self->param('GFD_panel_id');
  my $visibility = $self->param('visibility'); #restricted, authorised 
  my $model = $self->model('genomic_feature_disease_panel');  
  my $email = $self->session('email');
  $model->update_visibility($email, $GFD_panel_id, $visibility);
  $self->session(last_url => "/gene2phenotype/gfd?GFD_id=$GFD_id");
  $self->feedback_message('UPDATED_VISIBILITY_STATUS_SUC');
  return $self->redirect_to("/gene2phenotype/gfd?GFD_id=$GFD_id");
}

=head2 update_confidence_category
  Description: Update the confidence value of a GenomicFeatureDiseasePanel
  Exceptions : None
  Caller     : Template: user/gfd_attributes.html.ep
               Request: GET /gene2phenotype/gfd_panel/confidence_category/update
               Params:
                   category_attrib_id - The new confidence category attrib
                   GFD_id - database id of the GenomicFeatureDisease
                   GFD_panel_id - database id the GenomicFeatureDiseasePanel
  Status     : Stable
=cut

sub update_confidence_category {
  my $self = shift;
  my $category_attrib_id = $self->param('category_attrib_id'); 
  my $GFD_id = $self->param('GFD_id');
  my $GFD_panel_id = $self->param('GFD_panel_id');
  my $model = $self->model('genomic_feature_disease_panel');  
  my $email = $self->session('email');
  $model->update_confidence_category($email, $GFD_panel_id, $category_attrib_id);
  $self->session(last_url => "/gene2phenotype/gfd?GFD_id=$GFD_id");
  $self->feedback_message('UPDATED_CONFIDENCE_CATEGORY_SUC');
  return $self->redirect_to("/gene2phenotype/gfd?GFD_id=$GFD_id");
}

=head2 delete
  Description: Delete the GenomicFeatureDiseasePanel
  Exceptions : None
  Caller     : Template: user/gfd_attributes.html.ep
               Request: GET /gene2phenotype/gfd_panel/delete
               Params:
                   GFD_id - database id of the GenomicFeatureDisease
                   GFD_panel_id - database id the GenomicFeatureDiseasePanel
  Status     : Stable
=cut

sub delete {
  my $self = shift;
  my $GFD_id = $self->param('GFD_id');
  my $GFD_panel_id = $self->param('GFD_panel_id');
  my $model = $self->model('genomic_feature_disease_panel');
  my $email = $self->session('email');
  $model->delete($email, $GFD_panel_id);
  $self->feedback_message('DELETED_GFD_PANEL_SUC');
  return $self->redirect_to("/gene2phenotype/gfd?GFD_id=$GFD_id");
}

1;
