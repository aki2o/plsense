use strict;
use inc::Module::Install;

all_from 'lib/PlSense.pm';
repository 'https://github.com/aki2o/plsense';
bugtracker 'https://github.com/aki2o/plsense/issues';

requires 'Cache::FileCache';
requires 'Class::Std' => 0.011;
requires 'Class::Std::Storable';
requires 'Config::Tiny' => 2.14;
requires 'List::AllUtils' => 0.03;
requires 'Log::Handler' => 0.76;
requires 'Module::Pluggable' => 3.9;
requires 'PPI::Document' => 1.215;
requires 'PPI::Dumper' => 1.215;
requires 'PPI::Lexer' => 1.215;
requires 'Time::Piece' => 1.20_01;
requires 'Try::Tiny' => 0.11;

test_requires('Class::Std');
test_requires('List::AllUtils');

auto_include_deps();

install_script 'bin/plsense';
install_script 'bin/plsense-server-main';
install_script 'bin/plsense-server-resolve';
install_script 'bin/plsense-server-work';
install_script 'bin/plsense-worker-build';
install_script 'bin/plsense-worker-find';

WriteAll;

