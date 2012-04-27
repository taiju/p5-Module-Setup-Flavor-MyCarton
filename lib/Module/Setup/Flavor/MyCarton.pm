package Module::Setup::Flavor::MyCarton;
use strict;
use warnings;
use base 'Module::Setup::Flavor';
1;

=head1

Module::Setup::Flavor::MyCarton - carton plugin for me

=head1 SYNOPSIS

  $ module-setup --init --flavor-class=MyCarton new_flavor

=cut

__DATA__

---
file: .gitignore
template: |
  MYMETA.*
  META.yml
  Makefile
  inc/
  pm_to_blib
  *~
  .carton/
  local/
  carton.lock
---
file: .shipit
template: |
  steps = FindVersion, ChangeVersion, CheckChangeLog, DistTest, Commit, Tag, MakeDist, UploadCPAN
  git.push_to = origin
---
file: Changes
template: |
  Revision history for Perl extension [% module %]
  
  0.01    [% localtime %]
          - original version
---
file: Makefile.PL
template: |
  use inc::Module::Install;
  name '[% dist %]';
  all_from 'lib/[% module_unix_path %].pm';
  [% IF config.readme_from -%]
  readme_from 'lib/[% module_unix_path %].pm';
  [% END -%]
  [% IF config.readme_markdown_from -%]
  readme_markdown_from 'lib/[% module_unix_path %].pm';
  [% END -%]
  [% IF config.readme_pod_from -%]
  readme_pod_from 'lib/[% module_unix_path %].pm';
  [% END -%]
  [% IF config.githubmeta -%]
  githubmeta;
  [% END -%]
  
  # requires '';
  
  tests 't/*.t';
  author_tests 'xt';
  
  build_requires 'Test::More';
  auto_set_repository;
  auto_include;
  WriteAll;
---
file: MANIFEST.SKIP
template: |
  \bRCS\b
  \bCVS\b
  \.svn/
  \.git/
  ^MANIFEST\.
  ^Makefile$
  ~$
  \.old$
  ^blib/
  ^pm_to_blib
  ^MakeMaker-\d
  \.gz$
  \.cvsignore
  \.shipit
  MYMETA
  local/
  \.carton
  carton.lock
---
file: README
template: |
  This is Perl module [% module %].
  
  INSTALLATION
  
  [% module %] installation is straightforward. If your CPAN shell is set up,
  you should just be able to do
  
      % cpan [% module %]
  
  Download it, unpack it, then build it as per the usual:
  
      % perl Makefile.PL
      % make && make test
  
  Then install it:
  
      % make install
  
  DOCUMENTATION
  
  [% module %] documentation is available as in POD. So you can do:
  
      % perldoc [% module %]
  
  to read the documentation online with your favorite pager.
  
  [% config.author %]
---
file: lib/____var-module_path-var____.pm
template: |
  package [% module %];
  use strict;
  use warnings;
  our $VERSION = '0.01';
  
  1;
  __END__
  
  =head1 NAME
  
  [% module %] -
  
  =head1 SYNOPSIS
  
    use [% module %];
  
  =head1 DESCRIPTION
  
  [% module %] is
  
  =head1 AUTHOR
  
  [% config.author %] E<lt>[% config.email %]E<gt>
  
  =head1 SEE ALSO
  
  =head1 LICENSE
  
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
  
  =cut
---
file: t/00_compile.t
template: |
  use strict;
  use Test::More tests => 1;
  
  BEGIN { use_ok '[% module %]' }
---
file: xt/01_podspell.t
template: |
  use Test::More;
  eval q{ use Test::Spelling };
  plan skip_all => "Test::Spelling is not installed." if $@;
  add_stopwords(map { split /[\s\:\-]/ } <DATA>);
  $ENV{LANG} = 'C';
  all_pod_files_spelling_ok('lib');
  __DATA__
  [% config.author %]
  [% config.email %]
  [% module %]
---
file: xt/02_perlcritic.t
template: |
  use strict;
  use Test::More;
  eval {
      require Test::Perl::Critic;
      Test::Perl::Critic->import( -profile => 'xt/perlcriticrc');
  };
  plan skip_all => "Test::Perl::Critic is not installed." if $@;
  all_critic_ok('lib');
---
file: xt/03_pod.t
template: |
  use Test::More;
  eval "use Test::Pod 1.00";
  plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
  all_pod_files_ok();
---
file: xt/perlcriticrc
template: |
  [TestingAndDebugging::ProhibitNoStrict]
  allow=refs
---
plugin: VC/Git/UseCustomIgnore.pm
template: |
  package VC::Git::UseCustomIgnore;
  use strict;
  use warnings;
  use base 'Module::Setup::Plugin';
  use Data::Dumper;
  
  sub register {
      my($self, ) = @_;
      $self->add_trigger( check_skeleton_directory => \&check_skeleton_directory );
      $self->add_trigger( append_template_file     => \&append_template_file );
  }
  
  sub check_skeleton_directory {
      my $self = shift;
      return unless $self->dialog("Git init? [Yn] ", 'y') =~ /[Yy]/;
  
      !$self->system('git', 'init')              or die $?;
      !$self->system('git', 'add', '.gitignore') or die $?;
  
      my $dir = Module::Setup::Path::Dir->new('.');
      while (my $path = $dir->next) {
          next if $path eq '.' || $path eq '..' || $path eq '.git';
          $self->system('git', 'add', $path);
      }
      !$self->system('git', 'commit', '-m', 'initial commit') or die $?;
  }
  
  sub append_template_file {
      my $self = shift;
      my @template = Module::Setup::Flavor::loader(__PACKAGE__);
  
      for my $tmpl (@template) {
          if (exists $tmpl->{dir}) {
              Module::Setup::Path::Dir->new($self->distribute->dist_path, split('/', $tmpl->{dir}))->mkpath;
              next;
          } elsif (-e $self->distribute->dist_path->file(split('/', $tmpl->{file}))) { # add this
              next;
          }
          my $options = {
              dist_path => $self->distribute->dist_path->file(split('/', $tmpl->{file})),
              template  => $tmpl->{template},
              vars      => $self->distribute->template_vars,
              content   => undef,
          };
          $options->{chmod} = $tmpl->{chmod} if $tmpl->{chmod};
          $self->distribute->write_template($self, $options);
      }
  }
  
  1;
  
  
  =head1 NAME
  
  VC::Git::UseCustomIgnore - Just a little bit customized Git plugin
  
  =head1 What's difference Module::Setup::Plugin::VC::Git?
  
  L<VC::Git::UseCustomIgnore> is to give priority to your template of .gitignore.
  If exist your template of gitignore, not ask overwrite to template of gitignore.
  
  =head1 SYNOPSIS
  
    module-setup --init --plugin=VC::Git::CustomIgnore
  
  =head1 SEE ALSO
  
  L<Module::Setup::Plugin::VC::Git>
  
  =cut
  
  __DATA__
  
  ---
   file: .gitignore
   template: |
    cover_db
    META.yml
    Makefile
    blib
    inc
    pm_to_blib
    MANIFEST
    Makefile.old
    nytprof.out
    MANIFEST.bak
    *.sw[po]
---
config:
  class: Module::Setup::Flavor::GitHub
  plugins:
    - Config::Basic
    - Template
    - Test::Makefile
    - Additional
    - +VC::Git::UseCustomIgnore
    - Site::GitHub
