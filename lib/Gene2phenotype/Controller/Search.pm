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

package Gene2phenotype::Controller::Search;
use base qw(Gene2phenotype::Controller::BaseController);

=head2 results

  Description: Returns search results that match a given search term. Each search result is a GenomicFeatureDisease
               where either the gene symbol or the disease name match the search term. The match can be exact or partial.
               First, the search type (exact or partial) is identified with Gene2phenotype::Model::Search::identify_search_type.
               Then, based on the search type we fetch all search results with Gene2phenotype::Model::Search::fetch_all_by_gene_symbol,
               fetch_all_by_disease_name or fetch_all_by_substring.
               Based on the login status of the user we control how the search results are presented. If the user is not logged in we only return
               results for panels that can be viewed publicly and for panels that can be viewed publicly we only return
               GenomicFeatureDiseases that have been set to visible.
  Returntype : Hashref: Example search result for exact match by gene symbol:
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
               Depending on the login status, the results are directed to
               template user/searchresults when logged in and
               template searchresults when not logged in.
                
  Exceptions : If nothing is provided as search_term we redirect to the homepage /gene2phenotype/legacy/. 
  Caller     : Template: search.html.ep 
               Request: GET /gene2phenotype/legacy/search 
               Params:
                   search_term - String that has been entered as input 
                   panel - The selected panel for which to return the search results
  Status     : Stable

=cut

sub results {
  my $self = shift;
  my $model = $self->model('search');

  my $search_term = $self->param('search_term');
  $search_term =~ s/'/\\'/g;
  my $panel = $self->param('panel');

  if (!$search_term) {
    return $self->redirect_to("/gene2phenotype/legacy/");
  }

  my $search_type = $model->identify_search_type($search_term);

  my $logged_in = $self->stash('logged_in') || 0;
  my $authorised_panels = $self->stash('authorised_panels');

  if (!grep {$panel eq $_} @$authorised_panels) {
    return $self->redirect_to("/gene2phenotype/legacy/");
  }

  my @search_panels = ();
  if ($panel eq 'ALL') {
    @search_panels = grep { $_ ne 'ALL' } @$authorised_panels;
  } else {
    push @search_panels, $panel;
  }
  my $search_results;
  if ($search_type eq 'gene_symbol') {
    $search_results = $model->fetch_all_by_gene_symbol($search_term, \@search_panels, $logged_in);
  } elsif ($search_type eq 'disease_name') {
    $search_results = $model->fetch_all_by_disease_name($search_term, \@search_panels, $logged_in);
  } elsif ($search_type eq 'phenotype_name') {
    $search_results = $model->fetch_all_by_phenotype_name($search_term, \@search_panels, $logged_in);
  } elsif ($search_type eq 'contains_search_term') {
    $search_results = $model->fetch_all_by_substring($search_term, \@search_panels, $logged_in); 
  } else {
    $search_results = undef;
  }

  $self->stash(search_results => $search_results);
  $self->stash(search_term => $search_term);
  $self->session(last_url => "/gene2phenotype/legacy/search?panel=$panel&search_term=$search_term");

  if ($logged_in) {
    $self->render(template => 'user/searchresults');
  } else {
    $self->render(template => 'searchresults');
  }
}

1;
