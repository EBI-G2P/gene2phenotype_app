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

package Gene2phenotype::Model::Search;
use Mojo::Base 'MojoX::Model';

=head2 identify_search_type

  Arg [1]    : String $search_term
  Description: Based on the search term identifies the search type.
  Returntype : String which describes the search type: gene_symbol, disease_name, contains_search_term or no_entry_in_db. 
  Exceptions : None
  Caller     : Gene2phenotype::Controller::Search::results 
  Status     : Stable

=cut

sub identify_search_type {
  my $self = shift;
  my $search_term = shift;

  my $registry = $self->app->defaults('registry');
  my $gf_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeature');

  if ($gf_adaptor->fetch_by_gene_symbol($search_term) || $gf_adaptor->fetch_by_synonym($search_term)) {
    return 'gene_symbol';
  }
  my $disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'disease');
  if ($disease_adaptor->fetch_by_name($search_term)) {
    return 'disease_name';
  }
  my $phenotype_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'phenotype');
  if ($phenotype_adaptor->fetch_by_name($search_term)) {
    return 'phenotype_name';
  }
  my $diseases = $disease_adaptor->fetch_all_by_substring($search_term);
  my $genomic_features = $gf_adaptor->fetch_all_by_substring($search_term);
  if (@$diseases || @$genomic_features) {
    return 'contains_search_term';
  }

  return 'no_entry_in_db';
}

=head2 fetch_all_by_substring

  Arg [1]    : String $search_term
  Arg [2]    : Arrayref of panels $search_panels for which to return search results
  Arg [3]    : Boolean $is_authorised - indicates if user is logged in.
  Description: This is search by substring and we use the methods Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureAdaptor::fetch_all_by_substring and
               Bio::EnsEMBL::G2P::DBSQL::DiseaseAdaptor::fetch_all_by_substring to get all gene symbols and disease names which
               contain the given search term. With the set of gene symbols we use Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseAdaptor::fetch_all_by_GenomicFeature_panels
               to get all GenomicFeatureDiseases by gene symbol and Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseAdaptor::fetch_all_by_Disease_panels
               to get all GenomicFeatureDiseases by disease name.   
               We create a search result hash for each GenomicFeatureDisease.
  Returntype : Hashref with one key gfd_results which holds an arrayref of
               hashref results where each hashref represents a GenomicFeatureDisease
               search result: 
                   {
                      'gfd_results' => [
                                         {
                                           'mechanism' => 'loss of function',
                                           'dbID' => 916,
                                           'panels' => 'DD',
                                           'genotype' => 'monoallelic',
                                           'gene_symbol' => 'CRYBA1',
                                           'disease_name' => 'CATARACT CONGENITAL ZONULAR WITH SUTURAL OPACITIES',
                                           'search_type' => 'gfd'
                                         },
                                         {
                                           'mechanism' => 'loss of function',
                                           'dbID' => 2505,
                                           'panels' => 'Eye',
                                           'genotype' => 'monoallelic',
                                           'gene_symbol' => 'CRYBA1',
                                           'disease_name' => 'CATARACT 10, MULTIPLE TYPES',
                                           'search_type' => 'gfd'
                                         }
                                       ]
                    };
  Exceptions : None
  Caller     : Gene2phenotype::Controller::Search::results 
  Status     : Stable

=cut

sub fetch_all_by_substring {
  my $self = shift;
  my $search_term = shift; 
  my $search_panels = shift;
  my $is_authorised = shift; 

  my $registry = $self->app->defaults('registry');
  my $disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'disease');
  my $gfd_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease'); 
  my $gf_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeature'); 

  my $diseases = $disease_adaptor->fetch_all_by_substring($search_term);
  my @gfd_results = ();
  my %keys;
  my @gfd_no_dup = ();
  foreach my $disease ( sort { $a->name cmp $b->name } @$diseases) {
    my $gfds = $gfd_adaptor->fetch_all_by_Disease_panels($disease, $search_panels, $is_authorised);
    push @gfd_results, @{$self->_get_gfd_results($gfds)};

  }

  my $genes = $gf_adaptor->fetch_all_by_substring($search_term);
  foreach my $gene ( sort { $a->gene_symbol cmp $b->gene_symbol } @$genes) {
    my $gfds = $gfd_adaptor->fetch_all_by_GenomicFeature_panels($gene, $search_panels, $is_authorised);
    foreach my $gfd_result (@{$self->_get_gfd_results($gfds)}) {
      if (! grep {$gfd_result->{dbID} eq $_->{dbID}} @gfd_results) {
        push @gfd_results, $gfd_result;
      }
    }
  }

  # Remove duplicates
  foreach my $gfd (@gfd_results) {
    my $key = $gfd->{dbID}."-".$gfd->{mechanism}."-".$gfd->{disease_name}."-".$gfd->{genotype}."-".$gfd->{gene_symbol}."-".$gfd->{panels};
    if(!defined $keys{$key}) {
      push @gfd_no_dup, $gfd;
      $keys{$key} = 1;
    }
  }

  return {gfd_results => \@gfd_no_dup};

}

=head2 fetch_all_by_gene_symbol

  Arg [1]    : String $search_term
  Arg [2]    : Arrayref of panels $search_panels for which to return search results
  Arg [3]    : Boolean $is_authorised - indicates if user is logged in.
  Description: This is a exact search by gene symbol and we use the method Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureAdaptor::fetch_by_gene_symbol to get
               the GenomicFeature for the gene symbol search term. We use Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseAdaptor::fetch_all_by_GenomicFeature_panels
               to get all GenomicFeatureDiseases by GenomicFeature. 
               We create a search result hash for each GenomicFeatureDisease.
  Returntype : Hashref with one key gfd_results which holds an arrayref of
               hashref results where each hashref represents a GenomicFeatureDisease
               search result: 
                   {
                      'gfd_results' => [
                                         {
                                           'mechanism' => 'loss of function',
                                           'dbID' => 916,
                                           'panels' => 'DD',
                                           'genotype' => 'monoallelic',
                                           'gene_symbol' => 'CRYBA1',
                                           'disease_name' => 'CATARACT CONGENITAL ZONULAR WITH SUTURAL OPACITIES',
                                           'search_type' => 'gfd'
                                         },
                                         {
                                           'mechanism' => 'loss of function',
                                           'dbID' => 2505,
                                           'panels' => 'Eye',
                                           'genotype' => 'monoallelic',
                                           'gene_symbol' => 'CRYBA1',
                                           'disease_name' => 'CATARACT 10, MULTIPLE TYPES',
                                           'search_type' => 'gfd'
                                         }
                                       ]
                    };
  Exceptions : None
  Caller     : Gene2phenotype::Controller::Search::results 
  Status     : Stable

=cut

sub fetch_all_by_gene_symbol {
  my $self = shift;
  my $search_term = shift;
  my $search_panels = shift;
  my $is_authorised = shift;

  my $registry = $self->app->defaults('registry');
  my $gfd_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease'); 
  my $gf_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeature'); 
 
  my $gene = $gf_adaptor->fetch_by_gene_symbol($search_term); 
  if (!$gene) {
    $gene = $gf_adaptor->fetch_by_synonym($search_term);
  }

  my $gfds = $gfd_adaptor->fetch_all_by_GenomicFeature_panels($gene, $search_panels, $is_authorised);
  my $gfd_results = $self->_get_gfd_results($gfds);
  return {gfd_results => $gfd_results};
}

=head2 fetch_all_by_disease_name

  Arg [1]    : String $search_term
  Arg [2]    : Arrayref of panels $search_panels for which to return search results
  Arg [3]    : Boolean $is_authorised - indicates if user is logged in.
  Description: This is a exact search by disease name and we use the method Bio::EnsEMBL::G2P::DBSQL::DiseaseNameAdaptor::fetch_by_name to get
               the Disease for the disease name search term. We use Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseAdaptor::fetch_all_by_Disease_panels
               to get all GenomicFeatureDiseases by Disease. This method also searches by phenotypes using Bio::EnsEMBL::G2P::DBSQL::PhenotypeAdaptor::fetch_by_name
               We create a search result hash for each GenomicFeatureDisease.
  Returntype : Hashref with one key gfd_results which holds an arrayref of
               hashref results where each hashref represents a GenomicFeatureDisease
               search result: 
                   {
                      'gfd_results' => [
                                         {
                                           'mechanism' => 'loss of function',
                                           'dbID' => 916,
                                           'panels' => 'DD',
                                           'genotype' => 'monoallelic',
                                           'gene_symbol' => 'CRYBA1',
                                           'disease_name' => 'CATARACT CONGENITAL ZONULAR WITH SUTURAL OPACITIES',
                                           'search_type' => 'gfd'
                                         },
                                         {
                                           'mechanism' => 'loss of function',
                                           'dbID' => 2505,
                                           'panels' => 'Eye',
                                           'genotype' => 'monoallelic',
                                           'gene_symbol' => 'CRYBA1',
                                           'disease_name' => 'CATARACT 10, MULTIPLE TYPES',
                                           'search_type' => 'gfd'
                                         }
                                       ]
                    };
  Exceptions : None
  Caller     : Gene2phenotype::Controller::Search::results 
  Status     : Stable

=cut

sub fetch_all_by_disease_name {
  my $self = shift;
  my $search_term = shift;
  my $search_panels = shift;
  my $is_authorised = shift;
  my $registry = $self->app->defaults('registry');
  my $disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'disease');
  my $gfd_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
  my $phenotype_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'phenotype');
  my $gfdp_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturediseasephenotype');
  my $panel_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'panel');

  my $disease = $disease_adaptor->fetch_by_name($search_term);

  my $gfds = $gfd_adaptor->fetch_all_by_Disease_panels($disease, $search_panels, $is_authorised);
  my $gfd_results = $self->_get_gfd_results($gfds);

  # Search by phenotypes
  my $gfdps;
  my $phenotype = $phenotype_adaptor->fetch_by_name_substring($search_term);
  my @pheno_ids;
  foreach my $pheno (@{$phenotype}) {
    push (@pheno_ids, $pheno->phenotype_id);
  }
  $gfdps = $gfdp_adaptor->fetch_all_by_phenotype_ids(\@pheno_ids) if(scalar @pheno_ids > 0);
  my $gfdp_results = $self->_get_gfdp_results($gfdps, $panel_adaptor, $search_panels, $is_authorised, $gfd_results);

  # Merge results
  my @final = (@{$gfd_results}, @{$gfdp_results});

  return {gfd_results => \@final};
}


sub fetch_all_by_phenotype_name {
  my $self = shift;
  my $search_term = shift;
  my $search_panels = shift;
  my $is_authorised = shift;
  my $registry = $self->app->defaults('registry');
  my $phenotype_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'phenotype');
  my $gfdp_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturediseasephenotype');
  my $panel_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'panel');

  my $phenotype = $phenotype_adaptor->fetch_by_name_substring($search_term);
  my @pheno_ids;
  foreach my $pheno (@{$phenotype}) {
    push (@pheno_ids, $pheno->phenotype_id);
  }
  my $gfdps = $gfdp_adaptor->fetch_all_by_phenotype_ids(\@pheno_ids);
  my $gfdp_results = $self->_get_gfdp_results($gfdps, $panel_adaptor, $search_panels, $is_authorised);

  return {gfd_results => $gfdp_results};
}

=head2 _get_gfd_results

  Arg [1]    : Arrayref of GenomicFeatureDisease $gfds
  Description: Creates a hasref with key properties of a GenomicFeatureDisease
  Returntype : Arrayref of hashref where each hasref represents key attributes of a GenomicFeatureDisease 
                  [
                     {
                       'mechanism' => 'loss of function',
                       'dbID' => 916,
                       'panels' => 'DD',
                       'genotype' => 'monoallelic',
                       'gene_symbol' => 'CRYBA1',
                       'disease_name' => 'CATARACT CONGENITAL ZONULAR WITH SUTURAL OPACITIES',
                       'search_type' => 'gfd'
                     },
                     {
                       'mechanism' => 'loss of function',
                       'dbID' => 2505,
                       'panels' => 'Eye',
                       'genotype' => 'monoallelic',
                       'gene_symbol' => 'CRYBA1',
                       'disease_name' => 'CATARACT 10, MULTIPLE TYPES',
                       'search_type' => 'gfd'
                     }
                   ];
  Exceptions : None
  Caller     : fetch_all_by_disease_name, fetch_all_by_gene_symbol, fetch_all_by_substring
  Status     : Stable

=cut

sub _get_gfd_results {
  my $self = shift;
  my $gfds = shift;
  my @gfd_results = ();
  foreach my $gfd (@{$gfds}) {
    my $genomic_feature = $gfd->get_GenomicFeature;
    my $gene_symbol = $genomic_feature->gene_symbol;
    my $disease = $gfd->get_Disease;
    my $disease_name = $disease->name;
    my $dbID = $gfd->dbID;
    my $panels = join(',', sort @{$gfd->panels});
    my $allelic_requirement = $gfd->allelic_requirement || 'not specified';
    my $mutation_consequence = $gfd->mutation_consequence || 'not specified';  
    push @gfd_results, {
      gene_symbol => $gene_symbol,
      disease_name => $disease_name,
      genotype => $allelic_requirement,
      mechanism => $mutation_consequence,
      search_type => 'gfd',
      dbID => $dbID,
      panels => $panels};
  }
  return \@gfd_results;
}


=head2 _get_gfdp_results

  Arg [1]    : Arrayref of GenomicFeatureDiseasePhenotype $gfdps
  Arg [2]    : Panel adaptor
  Arg [3]    : Arrayref of panels $search_panels for which to return search results
  Arg [4]    : Boolean $is_authorised - indicates if user is logged in.
  Arg [5]    : Arrayref of hashref where each hasref represents key attributes of a GenomicFeatureDisease (optional)
  Description: Creates a hasref with key properties of a GenomicFeatureDisease
  Returntype : Arrayref of hashref where each hasref represents key attributes of a GenomicFeatureDisease 
                  [
                     {
                       'mechanism' => 'loss of function',
                       'dbID' => 916,
                       'panels' => 'DD',
                       'genotype' => 'monoallelic',
                       'gene_symbol' => 'CRYBA1',
                       'disease_name' => 'CATARACT CONGENITAL ZONULAR WITH SUTURAL OPACITIES',
                       'search_type' => 'gfd'
                     },
                     {
                       'mechanism' => 'loss of function',
                       'dbID' => 2505,
                       'panels' => 'Eye',
                       'genotype' => 'monoallelic',
                       'gene_symbol' => 'CRYBA1',
                       'disease_name' => 'CATARACT 10, MULTIPLE TYPES',
                       'search_type' => 'gfd'
                     }
                   ];
  Exceptions : None
  Caller     : fetch_all_by_disease_name
  Status     : Stable

=cut

sub _get_gfdp_results {
  my $self = shift;
  my $gfds = shift;
  my $panel_adaptor = shift;
  my $search_panels = shift;
  my $is_authorised = shift;
  my $disease_results = shift;

  my @gfd_results = ();
  my %gfd_list;
  my %found_by_disease;

  # Check which GenomicFeatureDisease IDs were returned by the disease name search
  foreach my $gfdisease (@{$disease_results}) {
    $found_by_disease{$gfdisease->{dbID}} = 1;
  }

  foreach my $gfdp (@$gfds) {
    my $gfd = $gfdp->get_GenomicFeatureDisease;
    my $gfd_id = $gfd->dbID();
    
    # If result was found by disease search then skip it
    next if(defined $found_by_disease{$gfd_id});
    
    my $is_visible = 0;
    my $gfd_panels = $gfd->panels(); # match the panels and check if it has permissions to access the panel
    foreach my $panel_name (@{$gfd_panels}) {
      my $panel = $panel_adaptor->fetch_by_name($panel_name);
      $is_visible = 1 if($panel && $panel->is_visible());
    }

    my $show_panel = 0;
    my $find_panel = _find_in_arrays($gfd_panels, $search_panels);

    if( $search_panels && $find_panel && ($is_authorised || (!$is_authorised && $is_visible)) ) {
      $show_panel = 1;
    }
    elsif(!$search_panels && ($is_authorised || (!$is_authorised && $is_visible))) {
      $show_panel = 1;
    }

    my $genomic_feature = $gfd->get_GenomicFeature;
    my $gene_symbol = $genomic_feature->gene_symbol;
    my $disease = $gfd->get_Disease;
    my $disease_name = $disease->name;
    my $dbID = $gfd->dbID;
    my $panels = join(',', sort @{$gfd->panels});
    my $allelic_requirement = $gfd->allelic_requirement || 'not specified';
    my $mutation_consequence = $gfd->mutation_consequence || 'not specified';

    if( scalar @{$gfd_panels} > 0 && $show_panel && !$gfd_list{$dbID}) {
      push @gfd_results, {
        gene_symbol => $gene_symbol,
        disease_name => $disease_name,
        genotype => $allelic_requirement,
        mechanism => $mutation_consequence,
        search_type => 'gfd',
        dbID => $dbID,
        panels => $panels};

        $gfd_list{$dbID} = 1;
    }
  }
  return \@gfd_results;
}

sub _find_in_arrays {
  my $gfd_panels = shift;
  my $search_panels = shift;
  
  my $flag = 0;
  
  foreach my $search_panel (@{$search_panels}) {
    foreach my $gfd_panel (@{$gfd_panels}) {
      if($search_panel eq $gfd_panel) {
        return 1;
      }
    }
  }
  
  return $flag;
}

1;
