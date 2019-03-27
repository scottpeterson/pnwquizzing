requires 'Config::App', '>= 1.09';

requires 'Mojolicious', '>= 8.12';
requires 'Role::Tiny::With', '>= 2.000006';
requires 'MojoX::ConfigAppStart', '>= 1.01';
requires 'MojoX::Log::Dispatch::Simple', '>= 1.06';
requires 'Mojolicious::Plugin::AccessLog', '>= 0.010';
requires 'Mojolicious::Plugin::RequestBase', '>= 0.3';
requires 'Mojolicious::Plugin::ToolkitRenderer', '>= 1.08';

requires 'Carp', '>= 1.50';
requires 'CSS::Sass', '>= 3.4.10';
requires 'Data::Printer', '>= 0.40';
requires 'Digest::Bcrypt', '>= 1.209';
requires 'Email::Mailer', '>= 1.09';
requires 'File::Find', '>= 1.34';
requires 'File::Path', '>= 2.16';
requires 'Log::Dispatch', '>= 2.68';
requires 'Log::Dispatch::Email::Mailer', '>= 1.03';
requires 'Term::ANSIColor', '>= 4.06';
requires 'Text::CSV_XS', '>= 1.38';
requires 'Text::Markdown', '>= 1.000031';
requires 'TryCatch', '>= 1.003002';

requires 'DBIx::Query', '>= 1.06';
requires 'DBD::SQLite', '>= 1.62';

feature 't', 'Testing' => sub {
    requires 'Test::Most', '>= 0.35';
};

feature 'tools', 'Tools' => sub {
    requires 'Data::Printer', '>= 0.40';
};

feature 'deploy', 'Deployment' => sub {
    requires 'App::Dest', '>= 1.21';
};
