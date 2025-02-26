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
package Gene2phenotype::Controller::GenomicFeatureDiseaseComment;
use base qw(Gene2phenotype::Controller::BaseController);

sub add {

  my $self = shift;
  my $GFD_id = $self->param('GFD_id'); 
  my $GFD_comment = $self->param('GFD_comment'); 
  my $GFDC_public = $self->param('submit_public');
  my $GFDC_private = $self->param('submit_private');

  if ($GFD_comment && $GFDC_private) {
    my $email = $self->session('email');
    my $model = $self->model('genomic_feature_disease_comment');
    my $is_public = 0;
    $model->add($GFD_id, $GFD_comment,  $is_public, $email);
    $self->feedback_message('ADDED_PRIVATE_COMMENT_SUC');
  } 
  if ($GFD_comment && $GFDC_public) {
     my $email = $self->session('email');
    my $model = $self->model('genomic_feature_disease_comment');
    my $is_public = 1;
    $model->add($GFD_id, $GFD_comment,$is_public, $email);
    $self->feedback_message('ADDED_PUBLIC_COMMENT_SUC');
  }

  $self->feedback_message('EMPTY_COMMENT');
  
  return $self->redirect_to("/gene2phenotype/legacy/gfd?GFD_id=$GFD_id");
}

sub delete {
  my $self = shift;
  my $GFD_comment_id = $self->param('GFD_comment_id');
  my $GFD_id = $self->param('GFD_id');
  my $email = $self->session('email');  
  my $model = $self->model('genomic_feature_disease_comment');
  $model->delete($GFD_comment_id, $email);
  $self->feedback_message('DELETED_COMMENT_SUC');
  return $self->redirect_to("/gene2phenotype/legacy/gfd?GFD_id=$GFD_id");
}

1;
