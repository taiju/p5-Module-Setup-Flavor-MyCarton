use inc::Module::Install;
name 'Module-Setup-Flavor-MyCarton';
all_from 'lib/Module/Setup/Flavor/MyCarton.pm';

requires 'Module::Setup', 0.09;

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
