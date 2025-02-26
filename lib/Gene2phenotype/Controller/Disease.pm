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
package Gene2phenotype::Controller::Disease;
use base qw(Gene2phenotype::Controller::BaseController);

sub show {
  my $self = shift;
  my $model = $self->model('disease'); 
  my $disease_id = $self->param('dbID');
        
  my $disease_attribs = $model->fetch_by_dbID($disease_id);
  $self->stash(disease => $disease_attribs);  
  $self->render(template => 'disease_page');
}

sub update {
  my $self = shift;
  my $disease_id = $self->param('disease_id');
  my $mim = $self->param('mim');
  my $name = $self->param('name');

  my $prev_mim = $self->param('prev_mim');
  my $prev_name = $self->param('prev_name');

  my $model = $self->model('disease'); 

  if ($name ne $prev_name || $mim ne $prev_mim) {
    if ($model->already_in_db($disease_id, $name)) {
      $disease_id = $model->update($disease_id, $mim, $name); 
      $self->feedback_message('DISEASE_NAME_IN_DB');
    } else {
      $disease_id = $model->update($disease_id, $mim, $name); 
      $self->feedback_message('UPDATED_DISEASE_ATTRIBS_SUC');
    }
  } else {
    $self->feedback_message('DATA_NOT_CHANGED');
  }
  $self->redirect_to("/gene2phenotype/legacy/disease?dbID=$disease_id");
}

1;
