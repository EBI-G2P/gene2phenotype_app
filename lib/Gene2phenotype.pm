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
package Gene2phenotype;
use Mojo::Base 'Mojolicious';
use Mojo::Home;
use Mojo::Log;
use HTTP::Tiny;
use Apache::Htpasswd;
use File::Path;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::G2P::Utils::Downloads qw(download_data);
use JSON;

# This method will run once at server start
sub startup {
  my $self = shift;
  $self->sessions->default_expiration(3600);

  my $config = $self->plugin('Config' => {file => $self->app->home .'/etc/gene2phenotype.conf'});
  my $password_file = $config->{password_file};
  my $downloads_dir = $config->{downloads_dir};
  my $registry_file = $config->{registry};
  my $passphrase = $config->{passphrase};
  $self->defaults(http_proxy => $config->{http_proxy});
  $self->defaults(proxy => $config->{proxy});
  my $log_dir = $config->{log_dir};
  my $log = Mojo::Log->new(path => "$log_dir/log_file"); 

  $self->app->secrets([$passphrase]);

  $self->plugin('RemoteAddr');
  $self->plugin('Model');
  $self->plugin('RenderFile');
  $self->plugin(mail => {
    from => 'noreplyG2P@ebi.ac.uk',
    type => 'text/html',
  });

  $self->plugin('authentication' => {
    'load_user' => sub {
      my ($self, $uid) = @_;
      return $uid;
    },
    'validate_user' => sub {
      my ($self, $user, $pw) = @_;
      my $auth = new Apache::Htpasswd({ passwdFile => $password_file, ReadOnly => 1, UseMD5 => 1,});
      return $auth->htCheckPassword($user, $pw);
    },
  });

  $self->defaults(layout => 'base');
  $self->g2p_defaults($registry_file);

  my $r = $self->routes;

  $self->hook(before_dispatch => sub {
    my $c = shift;
    $c->stash(logged_in => $c->session('logged_in'));
    $c->stash(panels => $c->session('panels'));
    my $registry = $c->app->defaults('registry');
    my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
    my $panel_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'panel');
    my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');

    my @visible_panels = map { $_->name } @{$panel_adaptor->fetch_all_visible};
    my @user_panels = (); # all panels that can be changed by the user
    my $logged_in = $c->session('logged_in');
    if ($logged_in) {
      my $email = $c->session('email');
      my $user = $user_adaptor->fetch_by_email($email);
      @user_panels = split(',', $user->panel);
      foreach my $panel (@user_panels) {
        if (!grep {$_ eq $panel} @visible_panels) {
          push @visible_panels, $panel;
        }
      }
    }
    # Add option to search ALL panels
    # ALL will only include panels that are allowed to be seen by the user 
    if (scalar @visible_panels > 1) {
      push @visible_panels, 'ALL';
    } 

    my @panel_imgs = ();
    my $g2p_panels = $attribute_adaptor->get_values_by_type('g2p_panel');
    foreach my $g2p_panel (sort keys %$g2p_panels) {
      if (grep {$g2p_panel eq $_} @visible_panels) {
        push @panel_imgs, [$g2p_panel => $g2p_panel];
      }
    }
    $c->stash(panel_imgs => \@panel_imgs);
    $c->stash(authorised_panels => \@visible_panels);
    $c->stash(user_panels => \@user_panels);
    $c->stash(visible_panels => \@visible_panels);

  });

  $r->get('/gene2phenotype/legacy')->to('home#show');
  $r->get('/gene2phenotype/legacy/disclaimer')->to(template => 'disclaimer');
  $r->get('/gene2phenotype/legacy/documentation')->to(template => 'documentation');
  $r->get('/gene2phenotype/legacy/help')->to(template => 'help');
  $r->get('/gene2phenotype/legacy/updates_to_our_terms')->to(template => 'updates_to_our_terms');


  $r->get('/gene2phenotype/legacy/documentation/enter_new_gene_disease_pair' => sub {
    my $c = shift;
    if ($c->session('logged_in')) {
      $c->render(template => 'enter_new_gene_disease_pair');
    } else {
      $c->redirect_to('/gene2phenotype/legacy');
    }
  });

  $r->get('/gene2phenotype/legacy/account')->to('login#account_info');

  # Called by login/account_info.html.ep
  $r->post('/gene2phenotype/legacy/account/update' => sub {
    my $c = shift;
    my $auth = new Apache::Htpasswd({ passwdFile => $password_file, ReadOnly => 0, UseMD5 => 1,});

    my $email = $c->param('email');
    my $current_pwd = $c->param('current_password');
    my $new_pwd = $c->param('new_password');
    my $retyped_pwd = $c->param('retyped_password');

    if (!$self->authenticate($email, $current_pwd)) { 
      $c->flash({message => 'Your current password is incorrect', alert_class => 'alert-danger'});
      return $c->redirect_to('/gene2phenotype/legacy/account');
    }

    if ($new_pwd ne $retyped_pwd) {
      $c->flash({message => 'Passwords don\'t match. Please ensure retyped password matches your new password.', alert_class => 'alert-danger'});
      return $c->redirect_to('/gene2phenotype/legacy/account');
    }
    my $success = $auth->htpasswd($email, $new_pwd, {'overwrite' => 1});        
    if ($success) {
      $c->flash({message => 'Successfully updated password', alert_class => 'alert-success'});
      return $c->redirect_to('/gene2phenotype/legacy/account');
    } else {
      $c->flash(message => 'Error occurred while resetting your password. Please contact g2p-help@ebi.ac.uk', alert_class => 'alert-danger');
      return $c->redirect_to('/gene2phenotype/legacy/account');
    }
  });
  $r->get('/gene2phenotype/legacy/login')->to(template => 'login/login');
  $r->get('/gene2phenotype/legacy/login/recovery')->to(template => 'login/recovery');
  $r->post('/gene2phenotype/legacy/login/recovery/mail')->to('login#send_recover_pwd_mail');
  $r->get('/gene2phenotype/legacy/login/recovery/reset')->to('login#validate_pwd_recovery');

  # Called by login/reset_password.html.ep
  $r->post('/gene2phenotype/legacy/login/recovery/update' => sub {
    my $c = shift;
    my $auth = new Apache::Htpasswd({ passwdFile => $password_file, ReadOnly => 0, UseMD5 => 1,});
    my $email = $c->param('email');
    my $new_pwd = $c->param('new_password');
    my $retyped_pwd = $c->param('retyped_password');
    my $authcode = $c->param('authcode');
    my $saved_authcode = $c->session('code');
    my $saved_email = $c->session('email');
    if ($authcode eq $saved_authcode) {
      if ($new_pwd eq $retyped_pwd) {
        my $success = $auth->htpasswd($email, $new_pwd, {'overwrite' => 1});        
        if ($success) {
          $c->session(logged_in => 1);
          $c->stash(logged_in => 1);
          $c->flash({message => 'Successfully updated password', alert_class => 'alert-success'});
          return $c->redirect_to('/gene2phenotype/legacy');
        } else {
          $c->flash(message => 'Error occurred while resetting your password. Please contact g2p-help@ebi.ac.uk', alert_class => 'alert-danger');
          return $c->redirect_to('/gene2phenotype/legacy');
        }
      }
    }
    $c->flash(message => 'Error occurred while resetting your password. Please contact g2p-help@ebi.ac.uk', alert_class => 'alert-danger');
    return $c->redirect_to('/gene2phenotype/legacy');
  });

  $r->get('/gene2phenotype/legacy/reset')->to(template => 'login', change_pwd => 1);
  $r->get('/gene2phenotype/legacy/logout')->to('login#on_user_logout');
  
  $r->post('/gene2phenotype/legacy/login')->to('login#on_user_login');
  $r->post('/gene2phenotype/legacy/reset')->to('login#reset_pwd');

  $r->get('/gene2phenotype/legacy/gfd')->to('genomic_feature_disease#show');

# :action=add, delete, update, add_comment, delete_comment
  $r->get('/gene2phenotype/legacy/gfd/organ/update')->to('genomic_feature_disease#update_organ_list');
  $r->get('/gene2phenotype/legacy/gfd/disease/update')->to('genomic_feature_disease#update_disease');
  $r->get('/gene2phenotype/legacy/gfd/phenotype/:action')->to(controller => 'genomic_feature_disease_phenotype');
  $r->get('/gene2phenotype/legacy/gfd/publication/:action')->to(controller => 'genomic_feature_disease_publication');
  $r->get('/gene2phenotype/legacy/gfd/comment/:action')->to(controller => 'genomic_feature_disease_comment');
  $r->get('/gene2phenotype/legacy/gfd/show_add_new_entry_form')->to('genomic_feature_disease#show_add_new_entry_form');
  $r->get('/gene2phenotype/legacy/gfd/add')->to('genomic_feature_disease#add');
  $r->get('/gene2phenotype/legacy/gfd/delete')->to('genomic_feature_disease#delete');
  $r->get('/gene2phenotype/legacy/gfd/show_attribs')->to('genomic_feature_disease#edit_allelic_mutation_form');
  $r->get('/gene2phenotype/legacy/gfd/edit_entry')->to('genomic_feature_disease#edit_allelic_mutation_form');
  $r->get('/gene2phenotype/legacy/gfd/update_allelic')->to('genomic_feature_disease#update_allelic_requirement_temp');
  $r->get('/gene2phenotype/legacy/gfd/update_ccm')->to('genomic_feature_disease#update_cross_cutting_modifier_temp');
  $r->get('/gene2phenotype/legacy/gfd/update_mutation_con')->to('genomic_feature_disease#update_mutation_consequence_temp');
  $r->get('/gene2phenotype/legacy/gfd/update_mcf')->to('genomic_feature_disease#update_mutation_consequence_flag_temp'); 
  $r->get('/gene2phenotype/legacy/gfd/allelic_requirement/update')->to('genomic_feature_disease#update_allelic_requirement');
  $r->get('/gene2phenotype/legacy/gfd/mutation_consequence/update')->to('genomic_feature_disease#update_mutation_consequence');
  $r->get('/gene2phenotype/legacy/gfd/mutation_consequence_flag/update')->to('genomic_feature_disease#update_mutation_consequence_flag');
  $r->get('/gene2phenotype/legacy/gfd/cross_cutting_modifier/update')->to('genomic_feature_disease#update_cross_cutting_modifier');
  $r->get('/gene2phenotype/legacy/gfd/update_vc')->to('genomic_feature_disease#update_variant_consequence_temp'); 
  $r->get('/gene2phenotype/legacy/gfd/variant_consequence/update')->to('genomic_feature_disease#update_variant_consequence');
  $r->get('/gene2phenotype/legacy/gfd_panel/add')->to('genomic_feature_disease_panel#add');
  $r->get('/gene2phenotype/legacy/gfd_panel/delete')->to('genomic_feature_disease_panel#delete');
  $r->get('/gene2phenotype/legacy/gfd_panel/authorised/update')->to('genomic_feature_disease_panel#update_visibility');
  $r->get('/gene2phenotype/legacy/gfd_panel/confidence_category/update')->to('genomic_feature_disease_panel#update_confidence_category');

  $r->get('/gene2phenotype/legacy/gene')->to('genomic_feature#show');
  $r->get('/gene2phenotype/legacy/disease')->to('disease#show');
  $r->get('/gene2phenotype/legacy/disease/update/')->to('disease#update');

  $r->get('/gene2phenotype/legacy/search')->to('search#results');

  $r->get('/gene2phenotype/legacy/ajax/publication')->to('publication#get_description');

  $r->get('/gene2phenotype/legacy/ajax/autocomplete' => sub {
    my $c = shift;
    my $term = $c->param('term');
    my $type = $c->param('query_type');

    my $dbh = $c->app->defaults('dbh');

    my $query = '';

    if ($type eq 'query_phenotype_name') {
      $query = 'select name AS value FROM phenotype where name like ? AND source="HP"';
    }
    elsif ($type eq 'query_gene_name') {
      $query = 'select gene_symbol AS value FROM genomic_feature where gene_symbol like ?';
    }
    elsif ($type eq 'query_disease_name') {
      $query = 'select name AS value FROM disease where name like ?';
    }
    else { # query
      $query = 'select search_term AS value FROM search where search_term like ?';
    }

    my $sth = $dbh->prepare($query);
    $sth->execute('%' . $term . '%') or die $dbh->errstr;
    my @query_output = ();
    while ( my $row = $sth->fetchrow_hashref ) {
      push @query_output, $row;
    }
    $c->render(json => \@query_output);  
  });

  $r->get('/gene2phenotype/legacy/ajax/phenotype/add')->to('genomic_feature_disease_phenotype#add');
  $r->get('/gene2phenotype/legacy/ajax/phenotype/delete_from_tree')->to('genomic_feature_disease_phenotype#delete_from_tree');

  $r->get('/gene2phenotype/legacy/downloads')->to(template => 'downloads');
  $r->get('/gene2phenotype/legacy/about')->to(template => 'about');
  $r->get('/gene2phenotype/legacy/g2p_vep_plugin')->to(template => 'g2p_vep_plugin');
  $r->get('/gene2phenotype/legacy/create_panel')->to(template => 'create_panel');
  $r->get('/gene2phenotype/legacy/terminology')->to(template => 'terminology');

  $r->get('/gene2phenotype/legacy/downloads/#file_name' => sub {
    my $c = shift;

    my $ip = $c->remote_addr;
    my $file_name = $c->stash('file_name');
    my $is_logged_in = $c->session('logged_in');
    my @authorised_panels = @{$c->stash('authorised_panels')};
    my $panel_name = $file_name;
    $panel_name =~ s/G2P\.csv\.gz//;
    $panel_name =~ s/_/ /; # "Hearing_loss" to "Hearing loss"
    $file_name =~ s/\.csv\.gz//;

    # Can the user download data for the specified panel?
    # If the user is not logged check if the panel that the user
    # wants to download is in the list of authorised panels (visible panels)
    if (!$is_logged_in) {
      if (! grep {$panel_name eq $_} @authorised_panels) {
        $c->flash(message => 'Specified panel cannot be downloaded. Please contact g2p-help@ebi.ac.uk', alert_class => 'alert-danger');
        return $c->redirect_to('/gene2phenotype/legacy/downloads');
      }          
    }   

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    $year += 1900;
    $mon++;
    my $stamp = join('_', ($mday, $mon, $hour, $min, $sec));
    my $file_time_stamp = join('_', $mday, $mon, $year);
    $file_name .= "_$file_time_stamp.csv";
    my $tmp_dir = "$downloads_dir/$stamp";
    mkpath($tmp_dir);
    $log->debug("download file $ip $panel_name $year $mon $mday");
    download_data($tmp_dir, $file_name, $registry_file, $is_logged_in, $panel_name);
    $c->render_file('filepath' => "$tmp_dir/$file_name.gz", 'filename' => "$file_name.gz", 'format' => 'zip', 'cleanup' => 1);
  });

  $r->get('/gene2phenotype/legacy/curator/no_publication')->to('curator#no_publication');
  $r->get('/gene2phenotype/legacy/curator/restricted_entries')->to('curator#restricted');
  $r->get('/gene2phenotype/legacy/curator/show_all_duplicated_LGM_by_panel')->to('curator#show_all_duplicated_LGM_by_panel');
  $r->get('/gene2phenotype/legacy/curator/show_all_duplicated_LGM_by_gene')->to('curator#show_all_duplicated_LGM_by_gene');

}

sub g2p_defaults {
  my $self = shift;
  my $registry_file = shift; 
  my $registry = 'Bio::EnsEMBL::Registry';

  $registry->load_all($registry_file);
  my $DBAdaptor = $registry->get_DBAdaptor('human', 'gene2phenotype');
  my $dbh = $DBAdaptor->dbc->db_handle;

  $self->defaults(panel_imgs => []);
  $self->defaults(registry => $registry);
  $self->defaults(dbh => $dbh);
  $self->defaults(panel => 'ALL');
  $self->defaults(panels => ['ALL']);
  $self->defaults(logged_in => 0);
  $self->defaults(alert_class => '');
}

1;
