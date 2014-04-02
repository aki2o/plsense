use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;
use PlSense::Configure;
use PlSense::ModuleKeeper;
use PlSense::Symbol::Module;

my $tmpdir = get_tmp_dir();
ok(-d $tmpdir, "get tmp directory");

set_primary_config(cachedir => $tmpdir);
setup_config();
my $mdlkeeper = PlSense::ModuleKeeper->new();
ok($mdlkeeper->isa("PlSense::ModuleKeeper"), "new");

my $filepath = $FindBin::Bin."/../tlib/TestSupport.pm";
$mdlkeeper->store_module(PlSense::Symbol::Module->new({ name => "hoge", filepath => $filepath, lastmodified => 0, }));
$mdlkeeper->store_module(PlSense::Symbol::Module->new({ name => "fuga", filepath => $filepath, lastmodified => 0, }));
$mdlkeeper->store_module(PlSense::Symbol::Module->new({ name => "hoge", filepath => $filepath, lastmodified => 0, }));
$mdlkeeper->store_module(PlSense::Symbol::Module->new({ name => "bar", filepath => $filepath, lastmodified => 0, }));

my @mdls = $mdlkeeper->get_packages();
is( $#mdls, 2, "number of package" );
is( $mdls[0]->get_name(), "bar", "name of package 1" );
is( $mdls[1]->get_name(), "fuga", "name of package 2" );
is( $mdls[2]->get_name(), "hoge", "name of package 3" );

done_testing();

