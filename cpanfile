requires 'Apache::Htpasswd';
requires 'Mojolicious', '== 8.09';
requires 'File::Rsync';
requires 'File::Path';
requires 'Mojolicious::Plugin::ForkCall';
requires 'Mojolicious::Plugin::Mail', '1.5';
requires 'Mojolicious::Plugin::CGI', '0.40';
requires 'Mojolicious::Plugin::Model', '0.11';
requires 'Mojolicious::Plugin::RenderFile', '0.12';
requires 'Mojolicious::Plugin::Authentication', '1.33';
requires 'Mojolicious::Plugin::RemoteAddr';
requires 'namespace::autoclean';
requires 'Moose', '2.2011';
requires 'XML::RSS::Parser';
requires 'XML::Simple';
requires 'FileHandle';
requires 'HTTP::Tiny';
requires 'IO::Socket::SSL';
requires 'HTML::Entities';
requires 'IPC::Cmd';
requires 'Data::Dumper';
requires 'Perl::OSType';
requires 'Crypt::PasswdMD5';
requires 'Net::SSLeay';

on 'build' => sub {
    requires 'Module::Build::Pluggable';
    requires 'Module::Build::Pluggable::CPANfile';
};
