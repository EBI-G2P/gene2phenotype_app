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

package Gene2phenotype::Model::GenomicFeatureDiseasePanel; 
use Mojo::Base 'MojoX::Model';

=head2 add
  Arg [1]    : Integer $gfd_id - Database id of GenomicFeatureDisease
  Arg [2]    : String $panel - Panel to which the GenomicFeatureDisease
               is added
  Arg [3]    : String $confidence_value - Confidence value for new
               GenomicFeatureDiseasePanel
  Arg [4]    : String $email - Email of user who creates the new
               GenomicFeatureDiseasePanel
  Description: Add GenomicFeatureDisease to panel and thereby
               create a new GenomicFeatureDiseasePanel
  Returntype : None
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDiseasePanel::add
  Status     : Stable
=cut

sub add {
  my $self = shift;
  my $gfd_id = shift;
  my $panel = shift;
  my $confidence_value = shift;
  my $email = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_panel_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePanel');
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');

  my $gfd_panel =  Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel->new(
    -genomic_feature_disease_id => $gfd_id,
    -panel => $panel,
    -confidence_category => $confidence_value,
    -adaptor => $GFD_panel_adaptor,
  );
  my $user = $user_adaptor->fetch_by_email($email);
  $gfd_panel = $GFD_panel_adaptor->store($gfd_panel, $user);
  return $gfd_panel;
}

=head2 update_visibility
  Arg [1]    : String $email - Email of user who updates the visibility
               of the GenomicFeatureDiseasePanel
  Arg [2]    : Integer $GFD_panel_id - Database id of GenomicFeatureDiseasePanel
  Arg [3]    : String $visibility - Value is either authorised or restricted
  Description: Update visibility of GenomicFeatureDiseasePanel
  Returntype : None
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDiseasePanel::update_visibility
  Status     : Stable
=cut

sub update_visibility {
  my $self = shift;
  my $email = shift;
  my $GFD_panel_id = shift;
  my $visibility = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_panel_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePanel');
  my $GFD_panel = $GFD_panel_adaptor->fetch_by_dbID($GFD_panel_id);
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
  my $user = $user_adaptor->fetch_by_email($email);
  my $is_visible = $visibility eq 'authorised' ? 1 : 0;
  $GFD_panel->is_visible($is_visible);
  $GFD_panel_adaptor->update($GFD_panel, $user);
}

=head2 update_confidence_category
  Arg [1]    : String $email - Email of user who updates the confidence
               category
  Arg [2]    : Integer $GFD_panel_id - Database id of GenomicFeatureDiseasePanel
  Arg [3]    : String $category_attrib_id - The new confidence category attrib
  Description: Update the confidence category of the GenomicFeatureDiseasePanel
  Returntype : None
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDiseasePanel::update_confidence_category
  Status     : Stable
=cut

sub update_confidence_category {
  my $self = shift;
  my $email = shift;
  my $GFD_panel_id = shift;
  my $category_attrib_id = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_panel_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePanel');
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
  my $user = $user_adaptor->fetch_by_email($email);
  my $GFD_panel = $GFD_panel_adaptor->fetch_by_dbID($GFD_panel_id);
  $category_attrib_id = 49 if ($category_attrib_id == 53);
  if ($category_attrib_id == 51 || $category_attrib_id == 49) {
    $GFD_panel->clinical_review(1);
  }
  else {
    $GFD_panel->clinical_review(0);
  }
  $GFD_panel->confidence_category_attrib($category_attrib_id);
  $GFD_panel_adaptor->update($GFD_panel, $user); 
} 

=head2 delete
  Arg [1]    : String $email - Email of user who runs the delete action.
  Arg [2]    : Integer $GFD_panel_id - database id of GenomicFeatureDiseasPanel
               that needs to be deleted
  Description: Delete GenomicFeatureDiseasePanel
  Returntype : None
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDiseasePanel::delete
  Status     : Stable
=cut

sub delete {
  my $self = shift;
  my $email = shift;
  my $GFD_panel_id = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_panel_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePanel');
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
  my $user = $user_adaptor->fetch_by_email($email);
  my $GFD_panel = $GFD_panel_adaptor->fetch_by_dbID($GFD_panel_id);
  $GFD_panel_adaptor->delete($GFD_panel, $user); 
}

1;
