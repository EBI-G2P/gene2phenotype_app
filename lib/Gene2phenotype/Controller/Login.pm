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

package Gene2phenotype::Controller::Login;
use Digest::MD5 qw/md5_hex/;
use base qw(Gene2phenotype::Controller::BaseController);

=head2 on_user_login
  Description: Gets email and password arguments and uses the authenticate method to check if
               the password is correct for the given user. After authentication we update the
               session with the logged_in flag set to 1, session expiration time, user email
               and all panels that can be curated by the user.
  Returntype : Redirect to the last page visited by the user before going to the login page
               or if that page wasn't stored redirect to the homepage.
  Exceptions : If the authentication fails, we show an error message and redirect the user
               back to the login page.
  Caller     : Template: login/login.html.ep
               Request: POST /gene2phenotype/legacy/login
               Params:
                   email - The user's email address entered into the login form
                   password - The user's password entered into the login form
  Status     : Stable
=cut

sub on_user_login {
  my $self = shift;
  my $email = $self->param('email');
  my $password = $self->param('password');

  if ($self->authenticate($email, $password)) {
    $self->session(logged_in => 1);
    $self->session(expiration => 3600);
    $self->session(email => $email);
    my $model = $self->model('user');
    my $user = $model->fetch_by_email($email);
    my @panels = split(',', $user->panel);
    $self->session(panels => \@panels);
    my $last_page = $self->session('last_url') || '/gene2phenotype/legacy';
    return $self->redirect_to($last_page);
  }
  $self->feedback_message('LOGIN_FAILED');
  return $self->redirect_to('/gene2phenotype/legacy/login');
}


=head2 on_user_logout
  Description: Updates the session with the logged_in flag set to 0, resets
               panels that can be curated to an empty list and also triggers
               the expiry of the session.
  Returntype : Redirect to the last page visited by the user before logging out
               or if that page wasn't stored redirect to the homepage.
  Exceptions : None
  Caller     : Template: header.html.ep
               Request: GET /gene2phenotype/legacy/logout
  Status     : Stable
=cut

sub on_user_logout {
  my $self = shift;
  $self->session(logged_in => 0);
  $self->session(panels => []);
  $self->session(expires => 1);
  my $last_page = $self->session('last_url') || '/gene2phenotype/legacy';
  return $self->redirect_to($last_page);
}

sub is_logged_in {
  my $self = shift;
  return 1 if $self->session('logged_in');
}

=head2 send_recover_pwd_mail
  Description: Creates a URL which is sent to the user's email address. The URL contains
               a code which is later used for verification. The code is a md5 digest in
               hexadecimal form calculated from a timestamp. The code is stored as part
               of the session. This guarantees that only the user of that session can
               follow the link and reset the password. If someonelse would get hold of
               the link, they could not update the password because the code couldn't
               be varified.
  Returntype : Show a message that the email has been sent and then redirect to the
               homepage.
  Exceptions : None
  Caller     : Template: login/recovery.html.ep
               Request: POST /gene2phenotype/legacy/login/recovery/mail
               Params: email - The user's email address
  Status     : Stable
=cut

sub send_recover_pwd_mail {
  my $self = shift;
  my $email = $self->param('email');

  my $model = $self->model('user');
  my $user = $model->fetch_by_email($email);
  

  my $autologin_code = md5_hex( time + rand(time) );
  my $url = $self->url_for('/gene2phenotype/legacy/login/recovery/reset')->query(code => $autologin_code)->to_abs;
  my $message = "Hi $user->{username}, This is the url to change your password, Kindly follow the link, $url";
  my $mes_join = join(",\n", (split ',', $message) ), "\n"; 
  
  $self->session(email => $email);
  $self->session(code => $autologin_code);
  $self->session(send_recover_email_mail => 1);

  if($user) {
    $self->mail(
      to      => $email,
      subject => 'Reset your password for gene2phenotype website',
      data    => $mes_join,
    );

    $self->flash(message => "An email with instructions for how to reset your email has been sent to $email", alert_class => 'alert-info');
  }
  else {
    $self->flash(message => "No account registered with email $email. Please contact g2p-help\@ebi.ac.uk for help.", alert_class => 'alert-danger');
  }

  return $self->redirect_to('/gene2phenotype');
}

=head2 validate_pwd_recovery
  Description: Sends the user to the page for resetting the password.
               The page will have set the email address of the user and
               have the code stored as a hidden variable.
  Returntype : Redirects to template login/reset_password for resetting
               the password.
  Exceptions : None
  Caller     : Request: POST /gene2phenotype/legacy/login/recovery/reset
                        The request comes from the URL that has been
                        sent to the user.
               Params: code that was generated in send_recover_pwd_mail
  Status     : Stable
=cut

sub validate_pwd_recovery {
  my $self = shift;
  my $code = $self->param('code');
  my $email = $self->session('email');
  $self->render(template => 'login/reset_password', email => $email, authcode => "$code");
}

=head2 account_info
  Description: Retrieves the email from the session and then using the email
               gets user specific information including all panels that can be edited
               by the user. The information is shown on the account info page.
  Returntype : If the user is logged in then we redirect to the login/account_info.
               And if the user is not logged in we show a message telling the user
               to login first and redirect to the homepage.
  Exceptions : None
  Caller     : Template header.html.ep
               Request: GET /gene2phenotype/legacy/account
  Status     : Stable
=cut

sub account_info {
  my $self = shift;
  if ($self->session('logged_in')) {
    my $email = $self->session('email');
    my $registry = $self->app->defaults('registry');
    my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
    my $user = $user_adaptor->fetch_by_email($email);

    my $username = $user->username; 
    my $panel = $user->panel;

    $self->stash(email => $email, username => $username, panel => $panel);
    $self->render(template => 'login/account_info');
  } else {
    $self->feedback_message('LOGIN_FOR_ACCOUNT_INFO');
    return $self->redirect_to('/gene2phenotype');
  }
}

1;
