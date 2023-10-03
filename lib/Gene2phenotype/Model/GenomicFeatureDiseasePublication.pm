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
package Gene2phenotype::Model::GenomicFeatureDiseasePublication;
use Mojo::Base 'MojoX::Model';

sub add_publication {
  my ($self, $GFD_id, $email, $source, $pmid, $title) = @_;

  my $registry = $self->app->defaults('registry');  
  my $GFDPublication_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePublication');
  my $publication_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Publication');

  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
  my $user = $user_adaptor->fetch_by_email($email);

  my $publication;
  if ($pmid) {
    $publication = $publication_adaptor->fetch_by_PMID($pmid); 
  } else {
    $publication = $publication_adaptor->fetch_by_title($title) if (defined ($title)); 
  }

  if (!$publication) {
    $publication = Bio::EnsEMBL::G2P::Publication->new(
      -pmid => $pmid,
      -title => $title || undef,
      -source => $source || undef,
    );
    $publication = $publication_adaptor->store($publication);
  }
  
  my $GFDPublication = $GFDPublication_adaptor->fetch_by_GFD_id_publication_id($GFD_id, $publication->dbID);
  if (!$GFDPublication) {
    $GFDPublication = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication->new(
      -genomic_feature_disease_id => $GFD_id,
      -publication_id => $publication->dbID,
      -adaptor => $GFDPublication_adaptor,
    );
    $GFDPublication_adaptor->store($GFDPublication);
  }

}

sub delete {
  my $self = shift;
  my $GFDPublication_id = shift;
  my $email = shift;

  my $registry = $self->app->defaults('registry');  
  my $GFDPublication_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePublication');
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
  my $user = $user_adaptor->fetch_by_email($email);

  my $GFDPublication = $GFDPublication_adaptor->fetch_by_dbID($GFDPublication_id);  
  $GFDPublication_adaptor->delete($GFDPublication, $user);
}

sub fetch_by_pmid {
  my $self = shift;
  my $pmid = shift;
  my $registry = $self->app->defaults('registry');
  my $gfdp_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Publication');
  $pmid = $gfdp_adaptor->fetch_by_PMID($pmid);
  return $pmid;
}


sub add_comment {
  my $self = shift;
  my $GFD_publication_id = shift;
  my $comment = shift;
  my $email = shift;

  my $registry = $self->app->defaults('registry');
  my $GFDPublicationComment_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GFDPublicationComment');
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');

  my $user = $user_adaptor->fetch_by_email($email);

  my $GFDPublicationComment = Bio::EnsEMBL::G2P::GFDPublicationComment->new(
    -comment_text => $comment,
    -genomic_feature_disease_publication_id => $GFD_publication_id,
    -adaptor => $GFDPublicationComment_adaptor,
  );

  $GFDPublicationComment_adaptor->store($GFDPublicationComment, $user);
}

sub delete_comment {
  my $self = shift;
  my $GFD_publication_comment_id = shift;
  my $email = shift;

  my $registry = $self->app->defaults('registry');
  my $GFDPublicationComment_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GFDPublicationComment');
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');

  my $user = $user_adaptor->fetch_by_email($email);

  my $GFD_publication_comment = $GFDPublicationComment_adaptor->fetch_by_dbID($GFD_publication_comment_id);
  $GFDPublicationComment_adaptor->delete($GFD_publication_comment, $user);
}
1;
