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
package Gene2phenotype::Controller::Curator;
use Mojo::Base 'Mojolicious::Controller';

sub no_publication {
  my $self = shift;
  my $logged_in = $self->stash('logged_in');
  my $is_authorised = ($logged_in) ? 1 : 0;

  if ($is_authorised) {
    my $user_model = $self->model('user');
    my $gfd_model = $self->model('genomic_feature_disease');
    my $email = $self->session('email');  

    my $user = $user_model->fetch_by_email($email); 
    my @panels = split(',', $user->panel);
    my @results = ();    
    foreach my $panel (@panels) {
# OUTDATED
#      my $gfds = $gfd_model->fetch_all_by_panel_without_publication($panel);
      push @results, {
        panel => $panel,
        gfds => [],
      };
    }
    $self->stash( gfds_no_publication => \@results);
    $self->render(template => 'curation_no_publication');
  } else {
    return $self->redirect_to("/gene2phenotype/legacy/");
  }
}

sub show_all_duplicated_LGM_by_panel {
  my $self = shift;
  my $logged_in = $self->stash('logged_in');
  my $is_authorised = ($logged_in) ? 1 : 0;

  if ($is_authorised) {
    my $user_model = $self->model('user');
    my $gfd_model = $self->model('genomic_feature_disease');
    my $email = $self->session('email');  

    my $user = $user_model->fetch_by_email($email); 
    my @panels = split(',', $user->panel);
    my @results = ();    
    foreach my $panel (@panels) {
# OUTDATED
#      my $merge_list = $gfd_model->fetch_all_duplicated_LGM_entries_by_panel($panel);
      my $merge_list = [];

      push @results, {
        panel => $panel,
        merge_list => $merge_list,
      };
    }
    $self->stash(gfs_merge_LGM => \@results);
    $self->render(template => 'curation_all_duplicated_LGM_by_panel');
  } else {
    return $self->redirect_to("/gene2phenotype/legacy/");
  }

}

sub show_all_duplicated_LGM_by_gene {
  my $self = shift;
  my $logged_in = $self->stash('logged_in');
  my $is_authorised = ($logged_in) ? 1 : 0;
  if ($is_authorised) {
    my $gf_id = $self->param('gf_id');
    my $panel = $self->param('panel');
    my $allelic_requirement_attrib = $self->param('allelic_requirement_attrib');
    my $mutation_consequence_attrib = $self->param('mutation_consequence_attrib');

    my $gfd_model = $self->model('genomic_feature_disease');

    my $duplicated_gfds = $gfd_model->fetch_all_duplicated_LGM_entries_by_gene($gf_id, $panel, $allelic_requirement_attrib, $mutation_consequence_attrib);
    $self->stash(duplicated_gfds => $duplicated_gfds);
    $self->render(template => 'curation_all_duplicated_LGM_by_gene');
  } else {
    return $self->redirect_to("/gene2phenotype/legacy/");
  }
}

sub restricted {
  my $self = shift;
  my $logged_in = $self->stash('logged_in');
  my $is_authorised = ($logged_in) ? 1 : 0;

  if ($is_authorised) {
    my $user_model = $self->model('user');
    my $gfd_model = $self->model('genomic_feature_disease');
    my $email = $self->session('email');  

    my $user = $user_model->fetch_by_email($email); 
    my @panels = split(',', $user->panel);
    my @results = ();    
    foreach my $panel (@panels) {
# OUTDATED
#      my $gfds = $gfd_model->fetch_all_by_panel_restricted($panel);
      push @results, {
        panel => $panel,
        gfds => [],
      };
    }
    $self->stash( gfds_restricted => \@results);
    $self->render(template => 'curation_restricted');
  } else {
    return $self->redirect_to("/gene2phenotype/legacy/");
  }
}

1;
