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
package Gene2phenotype::Controller::GenomicFeatureDiseasePhenotype;
use base qw(Gene2phenotype::Controller::BaseController);

sub add {
  my $self = shift;
  my $phenotype_names = $self->every_param('phenotype'); 
  my $GFD_id = $self->param('GFD_id'); 
  my $email = $self->session('email');
  my $model = $self->model('genomic_feature_disease_phenotype');
  my $phenotype_model = $self->model('phenotype');
  my @added = ();
  my @already_in_db = ();
  my @unknown_phenotypes = ();
  foreach my $phenotype_name (@$phenotype_names) {
    next if (length($phenotype_name) == 0);
    my $phenotype = $phenotype_model->fetch_by_name($phenotype_name); 
    if (!$phenotype) {
      push @unknown_phenotypes, $phenotype_name;
    } else {
      my $phenotype_id = $phenotype->dbID;
      my $GFDP = $model->fetch_by_GFD_id_phenotype_id($GFD_id, $phenotype_id);
      if ($GFDP) {
        push @already_in_db, $phenotype_name;    
      } else {
        $model->add_phenotype($GFD_id, $phenotype_id, $email);
        push @added, $phenotype_name;
      }
    }
  }
   
  my $info = 'PHENOTYPE_INFO';
  my @values = ();
  if (@added) {
    $info .= '_ADDED';
    push @values, join(', ', @added);
  }
  if (@already_in_db) {
    $info .= '_IN_DB';
    push @values, join(', ', @already_in_db);
  }
  if (@unknown_phenotypes) {
    $info .= '_ERROR';
    push @values, join(', ', @unknown_phenotypes);
  }
  $self->add_phenotypes_message($info, \@values);

  return $self->redirect_to("/gene2phenotype/legacy/gfd?GFD_id=$GFD_id#phenotypes");
}

sub delete_from_tree {
  my $self = shift;
  my $phenotype_id = $self->param('phenotype_id');
  my $GFD_id = $self->param('GFD_id');
  my $email = $self->session('email');
  my $model = $self->model('genomic_feature_disease_phenotype');
  my $phenotype_model = $self->model('phenotype');
  my $phenotype = $phenotype_model->fetch_by_dbID($phenotype_id); 
  my $phenotype_name = $phenotype->name;

  $model->delete_phenotype($GFD_id, $phenotype_id, $email);
  $self->edit_phenotypes_message('SUCC_DELETED_PHENOTYPE', $phenotype_name);
  $self->render(text => 'ok');
}

sub update {
  my $self = shift;
  my $phenotype_ids = $self->param('phenotype_ids');
  my $GFD_id = $self->param('GFD_id');
  my $email = $self->session('email');
  my $model = $self->model('genomic_feature_disease_phenotype');
  $model->update_phenotype_list($GFD_id, $email, $phenotype_ids);
  $self->feedback_message('UPDATED_PHENOTYPES_SUC');
  return $self->redirect_to("/gene2phenotype/legacy/gfd?GFD_id=$GFD_id#phenotypes");
}

sub delete {
  my $self = shift;
  my $GFD_id = $self->param('GFD_id');
  my $GFD_phenotype_id = $self->param('GFD_phenotype_id');
  my $email = $self->session('email');  
  my $model = $self->model('genomic_feature_disease_phenotype');
  my $GFDP = $model->fetch_by_dbID($GFD_phenotype_id);
  my $phenotype_name = $GFDP->get_Phenotype->name;
  $model->delete($GFD_phenotype_id, $email);
  $self->edit_phenotypes_message('SUCC_DELETED_PHENOTYPE', $phenotype_name);
  return $self->redirect_to("/gene2phenotype/legacy/gfd?GFD_id=$GFD_id#phenotypes");
}

sub add_comment {
  my $self = shift;
  my $GFD_phenotype_comment = $self->param('GFD_phenotype_comment');
  my $GFD_phenotype_id = $self->param('GFD_phenotype_id');
  my $GFD_id = $self->param('GFD_id');
  my $email = $self->session('email');  
  my $model = $self->model('genomic_feature_disease_phenotype');
  $model->add_comment($GFD_phenotype_id, $GFD_phenotype_comment, $email);
  $self->feedback_message('ADDED_COMMENT_SUC');
  return $self->redirect_to("/gene2phenotype/legacy/gfd?GFD_id=$GFD_id#phenotypes");
}

sub delete_comment {
  my $self = shift;
  my $GFD_phenotype_comment_id = $self->param('GFD_phenotype_comment_id');
  my $GFD_id = $self->param('GFD_id');
  my $email = $self->session('email');  
  my $model = $self->model('genomic_feature_disease_phenotype');
  $model->delete_comment($GFD_phenotype_comment_id, $email);
  $self->feedback_message('DELETED_COMMENT_SUC');
  return $self->redirect_to("/gene2phenotype/legacy/gfd?GFD_id=$GFD_id#phenotypes");
}


1;
