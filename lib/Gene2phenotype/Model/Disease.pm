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
package Gene2phenotype::Model::Disease;
use Mojo::Base 'MojoX::Model';
use HTTP::Tiny;
use JSON;

sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;
  my $registry = $self->app->defaults('registry');
  my $disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'disease');
  my $disease = $disease_adaptor->fetch_by_dbID($dbID);
  my $name = $disease->name;
  my $mim = $disease->mim;
  my $ontologies = $self->get_Ontology_accession($disease);
  return {
    disease_id => $dbID,
    name => $name,
    mim => $mim,
    ontologies => $ontologies,
  };
}

sub get_Ontology_accession {
  my $self = shift;
  my $disease = shift;

  my @ontologies = ();
  my $registry = $self->app->defaults('registry');
  my $disease_adaptor =  $registry->get_adaptor('human', 'gene2phenotype', 'Disease');
  foreach my $do (@{$disease->get_DiseaseOntology}) {
    my $ontology = $do->get_Ontology;
    push @ontologies, {
      ontology_accession => $ontology->ontology_accession,
      ontology_term_id => $do->ontology_term_id,
      disease_id => $do->disease_id,
    };
  }
  return \@ontologies;
}
sub fetch_by_name {
  my $self = shift;
  my $name = shift;
  my $registry = $self->app->defaults('registry');
  my $disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'disease');
  my $disease = $disease_adaptor->fetch_by_name($name);
  return $disease;
}

sub add {
  my $self = shift;
  my $name = shift;
  my $registry = $self->app->defaults('registry');
  my $disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'disease');

  my $disease =  Bio::EnsEMBL::G2P::Disease->new(
    -name => $name,
    -adaptor => $disease_adaptor,
  );
  $disease = $disease_adaptor->store($disease);
}

sub add_disease_ontology {
  my $self = shift;
  my $disease_mondo = shift; 
  my $disease_name = shift; 

  my $registry = $self->app->defaults('registry');
  my $ontology_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'OntologyTerm');
  my $disease_ontology_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'DiseaseOntology');
   
  my $disease = $self->fetch_by_name($disease_name);
  my $disease_id = $disease->dbID;
  my $ontology_term = $ontology_adaptor->fetch_by_accession($disease_mondo);


  my $http = HTTP::Tiny->new();
  my $url = "https://www.ebi.ac.uk/ols4/api/search?q=" . $disease_mondo . "&ontology=mondo&exact=1";
  my $response = $http->get($url, 
             {headers => { 'Content-type' => 'application/xml' }
  });
  my $result = JSON->new->decode($response->{content});
  
  if (($result->{response}->{numFound} == 1) && (!$ontology_term)) {
    my $ontology = Bio::EnsEMBL::G2P::OntologyTerm->new (
      -ontology_accession => $disease_mondo,
      -adaptor => $ontology_adaptor,
    );
    $ontology = $ontology_adaptor->store($ontology);

    my $DiseaseOntology = $disease_ontology_adaptor->fetch_by_disease_id_ot_id($disease_id, $ontology->dbID);
    if (!$DiseaseOntology) {
      $DiseaseOntology = Bio::EnsEMBL::G2P::DiseaseOntology->new(
        -disease_id => $disease_id,
        -ontology_term_id => $ontology->dbID,
        -adaptor => $disease_ontology_adaptor,
      );
      $disease_ontology_adaptor->store($DiseaseOntology);
    }
  } elsif (($result->{response}->{numFound} == 1) && (defined ($ontology_term))) {
    my $DiseaseOntology = $disease_ontology_adaptor->fetch_by_disease_id_ot_id($disease_id, $ontology_term->dbID);
    if (!$DiseaseOntology) {
      $DiseaseOntology = Bio::EnsEMBL::G2P::DiseaseOntology->new(
        -disease_id => $disease_id,
        -ontology_term_id => $ontology_term->dbID,
        -adaptor => $disease_ontology_adaptor,
      );
      $disease_ontology_adaptor->store($DiseaseOntology);
    }
  }

}

sub already_in_db {
  my $self = shift;
  my $disease_id = shift;
  my $name = shift;

  my $registry = $self->app->defaults('registry');
  my $disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'disease');

  my $disease = $disease_adaptor->fetch_by_name($name);

  if ($disease) {
    return 1;  
  }  
  return 0;
}

sub update {
  my $self = shift;
  my $disease_id = shift;
  my $mim = shift;
  my $name = shift;
  
  my $registry = $self->app->defaults('registry');
  my $disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'disease');
  my $disease = $disease_adaptor->fetch_by_dbID($disease_id);
  if ($disease->name ne $name || ($disease->mim && $disease->mim ne $mim)) {

    $disease =  Bio::EnsEMBL::G2P::Disease->new(
      -name => $name,
      -mim => $mim,
      -adaptor => $disease_adaptor,
    );
    $disease = $disease_adaptor->store($disease);
  }
  return $disease->dbID;
}

1;
