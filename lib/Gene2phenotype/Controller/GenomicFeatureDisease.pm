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
    return $self->redirect_to("/gene2phenotype/legacy/");
  }
  $self->stash(gfd => $gfd);
  my $disease_id = $gfd->{disease_id};
  my $disease_attribs = $disease_model->fetch_by_dbID($disease_id);
  $self->stash(disease => $disease_attribs);

  my $gene_id = $gfd->{gene_id};
  my $gene_attribs = $genomic_feature_model->fetch_by_dbID($gene_id);
  $self->stash(gene => $gene_attribs);

  $self->session(last_url => "/gene2phenotype/legacy/gfd?GFD_id=$dbID");

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
               Request: GET /gene2phenotype/legacy/gfd/show_add_new_entry_form
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
    
    my $cross_cutting_modifiers = $gfd_model->get_cross_cutting_modifiers;
    $self->stash(cross_cutting_modifiers => $cross_cutting_modifiers);
    
    my $mutation_consequences =  $gfd_model->get_mutation_consequences;
    $self->stash(mutation_consequences => $mutation_consequences);

    my $mutation_consequences_flags = $gfd_model->get_mutation_consequence_flags;
    $self->stash(mutation_consequences_flags => $mutation_consequences_flags);
    
    my $variant_consequences = $gfd_model->get_variant_consequence;
    $self->stash(variant_consequences => $variant_consequences);
    $self->render(template => 'add_new_entry');
  } else {
    $self->flash(message => 'You have been signed out', alert_class => 'alert-danger');
    return $self->redirect_to("/gene2phenotype/legacy/");
  }

}

=head2 edit_allelic_mutation_form
  Description: Setup the form for editing a GFD entry. Shows the values for:
               allelic requirement, mutation consequence, mutation consequence flag and cross cutting modifiers if defined, allows users to be able to edit/add attribs.
               Only if users are  allowed to edit the panels.
  Returntype : If the user is logged in and allowed to edit the panel  edit_entry.html.ep
  Exceptions : None
  Caller     : Template: user/gfd.html.ep
               Request: GET /gene2phenotype/legacy/gfd/edit_entry
               Template : show_attribs.html.ep
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
 
  $self->render(template => 'show_attribs');
}

=head2 update_allelic_requirement_temp
  Description: Setup the form for editing a GFD entry. Shows the values for possible :
               allelic requirements and the already selected allelic requirement.
               Only if users are  allowed to edit the panels.
  Returntype : If the user is logged in and allowed to edit the panel  allelic.html.ep
  Exceptions : None
  Caller     : Template: show_attribs.html.ep
               Request: GET /gene2phenotype/legacy/gfd/update_allelic
               Template : allelic.html.ep
  Status     : Stable
=cut
sub update_allelic_requirement_temp {
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

  $self->render('allelic');
}

=head2 update_allelic_requirement
  Description: Updating the allelic requirement  of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Template: allelic.html.ep
               Request : GET /gene2phenotype/legacy/gfd/allelic_requirement/update
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
    my $allelic_requirement_attrib_id = $self->param('allelic_requirement_attrib_id');
    $allelic_requirement = $gfd_model->get_value('allelic_requirement', $allelic_requirement_attrib_id);
  }
  my $email = $self->session('email');
  if ($allelic_requirement eq $gfd->{allelic_requirement}) {
    $self->feedback_message('SELECTED_ALLELIC_REQUIREMENT');
    return $self->redirect_to("/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
  }
  my $gfds = $gfd_model->fetch_all_by_GenomicFeature_constraints($gf, {
    'mutation_consequence' => $gfd->{mutation_consequence},
    'allelic_requirement' => $allelic_requirement
  });
  if (scalar @$gfds == 0) {
    $gfd_model->update_allelic_requirement($email, $GFD_id, $allelic_requirement);
    $self->session(last_url => "/gene2phenotype/legacy/gfd/edit_entry?GFD_id=$GFD_id");
    $self->feedback_message("UPDATED_ALLELIC_REQUIREMENT_SUC");
    return $self->redirect_to("/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
  }
  else {
    $self->feedback_message("GFD_ALREADY_EXISTS");
    return $self->redirect_to("/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
  }
}

=head2 update_cross_cutting_modifier_temp
  Description: Setup the form for editing a GFD entry. Shows the values for possible :
               cross cutting modifiers and the already selected cross cutting modifier (if any) 
               Only if users are  allowed to edit the panels.
  Returntype : If the user is logged in and allowed to edit the panel  ccm.html.ep
  Exceptions : None
  Caller     : Template: show_attribs.html.ep
               Request: GET /gene2phenotype/legacy/gfd/update_ccm
               Template : ccm.html.ep
  Status     : Stable
=cut
sub update_cross_cutting_modifier_temp {
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

  my $cross_cutting_modifiers = $gfd_model->get_cross_cutting_modifiers;
  $self->stash(cross_cutting_modifiers => $cross_cutting_modifiers);

  $self->render('ccm');
} 

=head2 update_cross_cutting_modifier
  Description: Updating the cross cutting modifier  of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Template: ccm.html.ep
               Request : GET /gene2phenotype/legacy/gfd/cross_cutting_modifier/update
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
  my $authorised_panels = $self->stash('authorised_panels');
  $gfd = $model->fetch_by_dbID($GFD_id, $logged_in, $authorised_panels);
  if (!defined $cross_cutting_modifier) {
    my $cross_cutting_modifier_attrib_ids= join(',', sort@{$self->every_param('cross_cutting_modifier_attrib_id')});
    $cross_cutting_modifier = $model->get_value('cross_cutting_modifier', $cross_cutting_modifier_attrib_ids);
  }
  if ($cross_cutting_modifier eq $gfd->{cross_cutting_modifier}) {
     $self->feedback_message('SELECTED_CROSS_CUTTING_MODIFIER');
     return $self->redirect_to("/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
  }
  $model->update_cross_cutting_modifier($email, $GFD_id, $cross_cutting_modifier);
  $self->session(last_url => "/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
  $self->feedback_message("UPDATED_CROSS_CUT_SUC");
  return $self->redirect_to("/gene2phenotype/legacy/gfd?GFD_id=$GFD_id");
}

=head2 update_mutation_consequence_temp
  Description: Setup the form for editing a GFD entry. Shows the values for possible :
               mutation consequences and the already selected mutation consequence.
               Only if users are  allowed to edit the panels.
  Returntype : If the user is logged in and allowed to edit the panel  mutation.html.ep
  Exceptions : None
  Caller     : Template: show_attribs.html.ep
               Request: GET /gene2phenotype/legacy/gfd/update_mutation_con
               Template : mutation.html.ep
  Status     : Stable
=cut
sub update_mutation_consequence_temp {
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

  my $mutation_consequences =  $gfd_model->get_mutation_consequences;
  $self->stash(mutation_consequences => $mutation_consequences);
  
  $self->render(template => 'mutation');
}
=head2 update_mutation_consequence
  Description: Updating the mutation consequence  of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Template: mutation.html.ep
               Request : GET /gene2phenotype/legacy/gfd/mutation_consequence/update
               Params  : 
                   mutation_consequence - The mutation consequence to be updated to 
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
    my $mutation_consequence_attribs_id = join(',', sort@{$self->every_param('mutation_consequence_attrib_id')});
    $mutation_consequence = $gfd_model->get_value('mutation_consequence', $mutation_consequence_attribs_id);
  }

  my $email = $self->session('email');
  if ($mutation_consequence eq $gfd->{mutation_consequence}) {
    $self->feedback_message('SELECTED_MUTATION_CONSEQ');
    return $self->redirect_to("/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
  }

  my $gfds = $gfd_model->fetch_all_by_GenomicFeature_constraints($gf, {
    'mutation_consequence' => $mutation_consequence,
    'allelic_requirement'  => $gfd->{allelic_requirement},
    'disease_id'           => $gfd->{disease_id}
  });

  if (scalar @$gfds == 0) {
    $gfd_model->update_mutation_consequence($email, $GFD_id, $mutation_consequence);
    $self->session(last_url => "/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
    $self->feedback_message("UPDATED_MUTATION_CONSEQ_SUC");
    return $self->redirect_to("/gene2phenotype/legacy/gfd?GFD_id=$GFD_id");
  } 
  else {
    $self->feedback_message("GFD_ALREADY_EXISTS");
    return $self->redirect_to("/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
  }

}

=head2 update_mutation_consequence_flag_temp
  Description: Setup the form for editing a GFD entry. Shows the values for possible :
               mutation consequence flags and the already selected cross cutting modifier (if any) 
               Only if users are  allowed to edit the panels.
  Returntype : If the user is logged in and allowed to edit the panel  ccm.html.ep
  Exceptions : None
  Caller     : Template: show_attribs.html.ep
               Request: GET /gene2phenotype/legacy/gfd/update_mcf
               Template : mcf.html.ep
  Status     : Stable
=cut
sub update_mutation_consequence_flag_temp {
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

  my $mutation_consequence_flags = $gfd_model->get_mutation_consequence_flags;
  $self->stash(mutation_consequence_flags => $mutation_consequence_flags);

  $self->render(template => 'mcf');
}


=head2 update_mutation_consequence_flag
  Description: Updating the mutation consequence flag of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Template: show_attribs.html.ep
               Request : GET /gene2phenotype/legacy/gfd/mutation_consequence_flag/update
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
     return $self->redirect_to("/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
  }
  $model->update_mutation_consequence_flag($email, $GFD_id, $mutation_consequence_flag);
  $self->session(last_url => "/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
  $self->feedback_message("UPDATED_MUT_CON_FLAG_SUC");
  return $self->redirect_to("/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
}

=head2 update_variant_consequence_temp
  Description: Setup the form for editing a GFD entry. Shows the values for possible :
               variant consequence and the already selected variant consequence(if any) 
               Only if users are  allowed to edit the panels.
  Returntype : If the user is logged in and allowed to edit the panel  ccm.html.ep
  Exceptions : None
  Caller     : Template: show_attribs.html.ep
               Request: GET /gene2phenotype/legacy/gfd/update_vc
               Template : var_con.html.ep
  Status     : Stable
=cut
sub update_variant_consequence_temp {
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

  my $variant_consequence = $gfd_model->get_variant_consequence;
  $self->stash(variant_consequence => $variant_consequence);

  $self->render('var_con');
} 

=head2 update_variant_consequence
  Description: Updating the variant consequence of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Template: show_attribs.html.ep
               Request : GET /gene2phenotype/legacy/gfd/variant_consequence/update
               Params  : 
                   mutation_consequence_flag - The mutation consequence flag to be updated to 
                   GFD_id - The database id of the GenomicFeatureDisease.
  Status     : Stable 
=cut
sub update_variant_consequence {
  my $self = shift;
  my $variant_consequence = $self->param('variant_consequence');
  my $GFD_id = $self->param("GFD_id");
  my $model = $self->model("genomic_feature_disease");
  my $email = $self->session("email");
  my $gfd;
  my $logged_in = 1;
  my $authorized_panels = $self->stash('authorized_panels');
  $gfd = $model->fetch_by_dbID($GFD_id, $logged_in, $authorized_panels);

  if (!defined $variant_consequence) {
    my $variant_consequence_attrib_ids = join(',', sort@{$self->every_param('variant_consequence_attrib_id')});
    $variant_consequence = $model->get_value('variant_consequence', $variant_consequence_attrib_ids);
  }
  if ($variant_consequence eq $gfd->{variant_consequence})  {
     $self->feedback_message('SELECTED_VARIANT_CONSEQUENCE');
     return $self->redirect_to("/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
  }
  $model->update_variant_consequence($email, $GFD_id, $variant_consequence);
  $self->session(last_url => "/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
  $self->feedback_message("UPDATED_VAR_CON_SUCCESSFULLY");
  return $self->redirect_to("/gene2phenotype/legacy/gfd/show_attribs?GFD_id=$GFD_id");
}

sub update_organ_list {
  my $self = shift;
  my $GFD_id = $self->param('GFD_id');
  my $organ_id_list = join(',', @{$self->every_param('organ_id')});
  my $model = $self->model('genomic_feature_disease');  
  my $email = $self->session('email');
  $model->update_organ_list($email, $GFD_id, $organ_id_list);
  $self->session(last_url => "/gene2phenotype/legacy/gfd?GFD_id=$GFD_id");
  $self->feedback_message('UPDATED_ORGAN_LIST');
  return $self->redirect_to("/gene2phenotype/legacy/gfd?GFD_id=$GFD_id");
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
  $self->session(last_url => "/gene2phenotype/legacy/gfd?GFD_id=$GFD_id");
  $self->feedback_message('UPDATED_DISEASE_ATTRIBS_SUC');
  return $self->redirect_to("/gene2phenotype/legacy/gfd?GFD_id=$GFD_id");
}


1;
