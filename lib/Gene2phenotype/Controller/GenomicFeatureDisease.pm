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

package Gene2phenotype::Controller::GenomicFeatureDisease;
use base qw(Gene2phenotype::Controller::BaseController);
use strict;
use warnings;
use Data::Dumper;

sub show {
  my $self = shift;
  my $model = $self->model('genomic_feature_disease');
  my $disease_model = $self->model('disease');
  my $genomic_feature_model = $self->model('genomic_feature');

  my $dbID = $self->param('dbID') || $self->param('GFD_id');

  if (!$dbID) {
    return $self->render(template => 'not_found');
  }
  my $gfd;
  my $authorised_panels = $self->stash('authorised_panels');
  my $logged_in = 0;
  if ($self->session('logged_in')) {
    my $user_panels = $self->stash('user_panels');
    $logged_in = 1;
    $gfd = $model->fetch_by_dbID($dbID, $logged_in, $authorised_panels, $user_panels);
  } else {
    $gfd = $model->fetch_by_dbID($dbID, $logged_in, $authorised_panels);
  }
  if (!defined $gfd) {
    return $self->redirect_to("/gene2phenotype/");
  }
  $self->stash(gfd => $gfd);
  my $disease_id = $gfd->{disease_id};
  my $disease_attribs = $disease_model->fetch_by_dbID($disease_id);
  $self->stash(disease => $disease_attribs);

  my $gene_id = $gfd->{gene_id};
  my $gene_attribs = $genomic_feature_model->fetch_by_dbID($gene_id);
  $self->stash(gene => $gene_attribs);

  $self->session(last_url => "/gene2phenotype/gfd?GFD_id=$dbID");

  if ($self->session('logged_in')) {
    $self->render(template => 'user/gfd');
  } else {
    $self->render(template => 'gfd');
  }
}

=head2 show_add_new_entry_form
  Description: Setup the form for creating a new entry. Get all possible values for:
               confidence values, allelic requirement and mutation consequence.
               Get list of all panels that can be curated by the user. The user will
               only be able to create a new entry on one of those panels.
  Returntype : If the user is logged in then redirect to template add_new_entry.html.ep
  Exceptions : None
  Caller     : Template: user/searchresults.html.ep
               Request: GET /gene2phenotype/gfd/show_add_new_entry_form
  Status     : Stable
=cut

sub show_add_new_entry_form {
  my $self = shift;
  
  if ($self->session('logged_in')) {

    my $email = $self->session('email');

    if (defined $self->param('gene_symbol')) {
      $self->stash(gene_symbol => $self->param('gene_symbol'));
    } else {
      $self->stash(gene_symbol => undef);
    }

    my $user_model = $self->model('user');
    my $user = $user_model->fetch_by_email($email);
    my @panels = split(',', $user->panel);
    $self->stash(panels => \@panels);

    my $gfd_model = $self->model('genomic_feature_disease');

    my $confidence_values = $gfd_model->get_confidence_values;
    $self->stash(confidence_values => $confidence_values);
    

    my $allelic_requirements = $gfd_model->get_allelic_requirements;
    $self->stash(allelic_requirements => $allelic_requirements);

    my $mutation_consequences =  $gfd_model->get_mutation_consequences;
    $self->stash(mutation_consequences => $mutation_consequences);

  }

  $self->render(template => 'add_new_entry');
}

=head2 edit_allelic_mutation_form
  Description: Setup the form for editing a GFD entry. Get all possible values for:
               allelic requirement, mutation consequence, mutation consequence flag and cross cutting modifiers.
               Only if users are  allowed to edit the panels.
  Returntype : If the user is logged in and allowed to edit the panel  edit_entry.html.ep
  Exceptions : None
  Caller     : Template: user/gfd.html.ep
               Request: GET /gene2phenotype/gfd/edit_entry
  Status     : Stable
=cut

sub edit_allelic_mutation_form {
  my $self = shift;
  my $email = $self->session('email');
  my $dbID =  $self->param('GFD_id');
  my $gfd;
  my $authorised_panels = $self->stash('authorised_panels');
  my $logged_in = 0;
  

  my $gfd_model = $self->model('genomic_feature_disease');
  my $disease_model = $self->model('disease');
  if ($self->session('logged_in')) {
    my $user_panels = $self->stash('user_panels');
    $logged_in = 1;
    $gfd = $gfd_model->fetch_by_dbID($dbID, $logged_in, $authorised_panels, $user_panels);
  }
  
  $self->stash(gfd => $gfd);
 
  

  my $allelic_requirements = $gfd_model->get_allelic_requirements;
  $self->stash(allelic_requirements => $allelic_requirements);
 

  my $cross_cutting_modifiers = $gfd_model->get_cross_cutting_modifiers;
  $self->stash(cross_cutting_modifiers => $cross_cutting_modifiers);
  

  my $mutation_consequences =  $gfd_model->get_mutation_consequences;
  $self->stash(mutation_consequences => $mutation_consequences);
 

  my $mutation_consequence_flags = $gfd_model->get_mutation_consequence_flags;
  $self->stash(mutation_consequence_flags => $mutation_consequence_flags);
  
    
  $self->render(template => 'edit_entry');

}

=head2 update_allelic_requirement
  Description: Updating the allelic requirement  of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Template: edit_entry.html.ep
               Request : GET /gene2phenotype/gfd/allelic_requirement/update
               Params  : 
                   allelic_requirement - The allelic requirement to be updated to 
                   GFD_id - The database id of the GenomicFeatureDisease.
  Status     : Stable 
=cut

sub update_allelic_requirement {
  my $self = shift;
  my $GFD_id = $self->param('GFD_id');
  my $allelic_requirement =  $self->param('allelic_requirement');
  my $gfd_model = $self->model('genomic_feature_disease');
  my $gfd;
  my $logged_in = 1;
  my $authorised_panels = $self->stash('authorised_panels');;
  $gfd = $gfd_model->fetch_by_dbID($GFD_id, $logged_in, $authorised_panels);
  my $gf_model = $self->model('genomic_feature');
  my $gene_symbol = $gfd->{gene_symbol};
  my $gf = $gf_model->fetch_by_gene_symbol($gene_symbol); 
  if (!defined $allelic_requirement) {
    my $allelic_requirement_attrib_ids = join(',', sort @{$self->every_param('allelic_requirement_attrib_id')});
    $allelic_requirement = $gfd_model->get_value('allelic_requirement', $allelic_requirement_attrib_ids);
  }
  my $email = $self->session('email');
  if ($allelic_requirement eq $gfd->{allelic_requirement}) {
    $self->feedback_message('SELECTED_ALLELIC_REQUIREMENT');
    return $self->redirect_to("/gene2phenotype/gfd/edit_entry?GFD_id=$GFD_id");
  }
  my $gfds = $gfd_model->fetch_all_by_GenomicFeature_constraints($gf, {
    'mutation_consequence' => $gfd->{mutation_consequence},,
    'allelic_requirement' => $allelic_requirement
  });
  if (scalar @$gfds == 0) {
    $gfd_model->update_allelic_requirement($email, $GFD_id, $allelic_requirement);
    $self->session(last_url => "/gene2phenotype/gfd/edit_entry?GFD_id=$GFD_id");
    $self->feedback_message("UPDATED_ALLELIC_REQUIREMENT_SUC");
    return $self->redirect_to("/gene2phenotype/gfd?GFD_id=$GFD_id");
  }
  else {
    $self->feedback_message("GFD_ALREADY_EXISTS");
    return $self->redirect_to("/gene2phenotype/gfd/edit_entry?GFD_id=$GFD_id");
  }
}

=head2 update_cross_cutting_modifier
  Description: Updating the cross cutting modifier  of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Template: edit_entry.html.ep
               Request : GET /gene2phenotype/gfd/cross_cutting_modifier/update
               Params  : 
                   cross cutting modifier - The cross cutting modifier to be updated to 
                   GFD_id - The database id of the GenomicFeatureDisease.
  Status     : Stable 
=cut

sub update_cross_cutting_modifier {
  my $self = shift;
  my $cross_cutting_modifier = $self->param('cross_cutting_modifier');
  my $GFD_id = $self->param("GFD_id");
  my $model = $self->model("genomic_feature_disease");
  my $email = $self->session("email");
  my $gfd;
  my $logged_in = 1;
  my $authorized_panels = $self->stash('authorized_panels');
  $gfd = $model->fetch_by_dbID($GFD_id, $logged_in, $authorized_panels);
  if (!defined $cross_cutting_modifier) {
    my $cross_cutting_modifier_attrib_id = $self->param('cross_cutting_modifier_attrib_id');
    $cross_cutting_modifier = $model->get_value('cross_cutting_modifier', $cross_cutting_modifier_attrib_id);
  }
  if ($cross_cutting_modifier eq $gfd->{cross_cutting_modifier}) {
     $self->feedback_message('SELECTED_CROSS_CUTTING_MODIFIER');
     return $self->redirect_to("/gene2phenotype/gfd/edit_entry?GFD_id=$GFD_id");
  }
  $model->update_cross_cutting_modifier($email, $GFD_id, $cross_cutting_modifier);
  $self->session(last_url => "/gene2phenotype/gfd/edit_entry?GFD_id=$GFD_id");
  $self->feedback_message("UPDATED_CROSS_CUT_SUC");
  return $self->redirect_to("/gene2phenotype/gfd?GFD_id=$GFD_id");
}

=head2 update_mutation_consequence
  Description: Updating the mutation consequence  of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Template: edit_entry.html.ep
               Request : GET /gene2phenotype/gfd/mutation_consequence/update
               Params  : 
                   mutatiom_consequence - The mutation consequence to be updated to 
                   GFD_id - The database id of the GenomicFeatureDisease.
  Status     : Stable 
=cut

sub update_mutation_consequence {
  my $self = shift; 
  my $mutation_consequence = $self->param('mutation_consequence');
  my $GFD_id = $self->param('GFD_id');
  my $gfd; 
  my $logged_in = 1; 
  my $authorised_panels = $self->stash('authorised_panels');
  my $gfd_model = $self->model('genomic_feature_disease');
  $gfd = $gfd_model->fetch_by_dbID($GFD_id, $logged_in, $authorised_panels);
  my $gf_model = $self->model('genomic_feature');
  my $gene_symbol = $gfd->{gene_symbol};
  my $gf = $gf_model->fetch_by_gene_symbol($gene_symbol);
  if (!defined $mutation_consequence){
    my $mutation_consequence_attrib_id = $self->param('mutation_consequence_attrib_id');
    $mutation_consequence = $gfd_model->get_value('mutation_consequence', $mutation_consequence_attrib_id);
  }
  my $email = $self->session('email');
  if ($mutation_consequence eq $gfd->{mutation_consequence}) {
    $self->feedback_message('SELECTED_MUTATION_CONSEQ');
    return $self->redirect_to("/gene2phenotype/gfd/edit_entry?GFD_id=$GFD_id");
  }
  my $gfds = $gfd_model->fetch_all_by_GenomicFeature_constraints($gf, {
    'mutation_consequence' => $mutation_consequence,
    'allelic_requirement' => $gfd->{allelic_requirement},
  });
  if (scalar @$gfds == 0) {
    $gfd_model->update_mutation_consequence($email, $GFD_id, $mutation_consequence);
    $self->session(last_url => "/gene2phenotype/gfd/edit_entry?GFD_id=$GFD_id");
    $self->feedback_message("UPDATED_MUTATION_CONSEQ_SUC");
    return $self->redirect_to("/gene2phenotype/gfd?GFD_id=$GFD_id");
  } 
  else {
    $self->feedback_message("GFD_ALREADY_EXISTS");
    return $self->redirect_to("/gene2phenotype/gfd/edit_entry?GFD_id=$GFD_id");
  }

}

=head2 update_mutation_consequence_flag
  Description: Updating the mutation consequence flag of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Template: edit_entry.html.ep
               Request : GET /gene2phenotype/gfd/mutation_consequence_flag/update
               Params  : 
                   mutation_consequence_flag - The mutation consequence flag to be updated to 
                   GFD_id - The database id of the GenomicFeatureDisease.
  Status     : Stable 
=cut
sub update_mutation_consequence_flag {
  my $self = shift;
  my $mutation_consequence_flag = $self->param('mutation_consequence_flag');
  my $GFD_id = $self->param("GFD_id");
  my $model = $self->model("genomic_feature_disease");
  my $email = $self->session("email");
  my $gfd;
  my $logged_in = 1;
  my $authorized_panels = $self->stash('authorized_panels');
  $gfd = $model->fetch_by_dbID($GFD_id, $logged_in, $authorized_panels);
  if (!defined $mutation_consequence_flag) {
    my $mutation_consequence_flag_attrib_id = $self->param('mutation_consequence_flag_attrib_id');
    $mutation_consequence_flag = $model->get_value('mutation_consequence_flag', $mutation_consequence_flag_attrib_id);
  }
  if ($mutation_consequence_flag eq $gfd->{mutation_consequence_flag})  {
     $self->feedback_message('SELECTED_MUTATION_CON_FLAG');
     return $self->redirect_to("/gene2phenotype/gfd/edit_entry?GFD_id=$GFD_id");
  }
  $model->update_mutation_consequence_flag($email, $GFD_id, $mutation_consequence_flag);
  $self->session(last_url => "/gene2phenotype/gfd/edit_entry?GFD_id=$GFD_id");
  $self->feedback_message("UPDATED_MUT_CON_FLAG_SUC");
  return $self->redirect_to("/gene2phenotype/gfd?GFD_id=$GFD_id");
}

sub update_organ_list {
  my $self = shift;
  my $GFD_id = $self->param('GFD_id');
  my $organ_id_list = join(',', @{$self->every_param('organ_id')});
  my $model = $self->model('genomic_feature_disease');  
  my $email = $self->session('email');
  $model->update_organ_list($email, $GFD_id, $organ_id_list);
  $self->session(last_url => "/gene2phenotype/gfd?GFD_id=$GFD_id");
  $self->feedback_message('UPDATED_ORGAN_LIST');
  return $self->redirect_to("/gene2phenotype/gfd?GFD_id=$GFD_id");
}

sub update_disease {
  my $self = shift;
  my $GFD_id = $self->param('GFD_id');
  my $disease_id = $self->param('disease_id');
  my $name = $self->param('name');
  my $mim = $self->param('mim');
  my $model = $self->model('genomic_feature_disease');  
  my $email = $self->session('email');
  $model->update_disease($email, $GFD_id, $disease_id, $name, $mim);
  $self->session(last_url => "/gene2phenotype/gfd?GFD_id=$GFD_id");
  $self->feedback_message('UPDATED_DISEASE_ATTRIBS_SUC');
  return $self->redirect_to("/gene2phenotype/gfd?GFD_id=$GFD_id");
}


1;
