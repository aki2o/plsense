use strict;
use inc::Module::Install;

all_from 'lib/PlSense.pm';
repository 'https://github.com/aki2o/plsense';
bugtracker 'https://github.com/aki2o/plsense/issues';

auto_include_deps();

install_script 'bin/plsense';
install_script 'bin/plsense-server-main';
install_script 'bin/plsense-server-resolve';
install_script 'bin/plsense-server-work';
install_script 'bin/plsense-worker-build';
install_script 'bin/plsense-worker-find';

tests_recursive;

cpanfile;

WriteAll;

