use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;
use PlSense::Configure;
use PlSense::ModuleKeeper;
use PlSense::Symbol::Module;
use PlSense::Symbol::Method;
use PlSense::Symbol::Variable;

my $tmpdir = get_tmp_dir();
ok(-d $tmpdir, "get tmp directory");

set_primary_config(cachedir => $tmpdir);
setup_config();
my $mdlkeeper = PlSense::ModuleKeeper->new();
ok($mdlkeeper->isa("PlSense::ModuleKeeper"), "new");

my $filepath = $FindBin::Bin."/../tlib/TestSupport.pm";
my $mdl = PlSense::Symbol::Module->new({ name => "hoge", filepath => $filepath, lastmodified => 0, });
my $mtd = PlSense::Symbol::Method->new({ name => "met", module => $mdl });
my $var = PlSense::Symbol::Variable->new({ name => '$va', belong => $mtd });

my ($mdl2, $debugstr);
$mdl2 = $mdlkeeper->get_module($mdl->get_name, $mdl->get_filepath);
ok(! $mdl2, "not yet keep");
$mdl2 = $mdlkeeper->load_module($mdl->get_name, $mdl->get_filepath);
ok(! $mdl2, "not yet store");

$mdlkeeper->store_module($mdl);

$mdl2 = $mdlkeeper->get_module($mdl->get_name, $mdl->get_filepath);
ok($mdl2 && $mdl2->isa("PlSense::Symbol::Module"), "get kept");

$debugstr = $mdlkeeper->describe_keep_value;
is($debugstr, "Modules ... 1\n", "keep info");

$mdlkeeper->reset;
$debugstr = $mdlkeeper->describe_keep_value;
is($debugstr, "Modules ... 0\n", "reset");

$mdl2 = $mdlkeeper->load_module($mdl->get_name, $mdl->get_filepath);
ok($mdl2 && $mdl2->isa("PlSense::Symbol::Module") && $mdl2->get_name eq "hoge", "get stored module");
$debugstr = $mdlkeeper->describe_keep_value;
is($debugstr, "Modules ... 1\n", "keep info after loaded");

my $mtd2 = $mdl2->exist_method("met") && $mdl2->get_method("met");
ok($mtd2 && $mtd2->isa("PlSense::Symbol::Method") && $mtd2->get_name eq "met", "get stored method");

my $var2 = $mtd2->exist_variable('$va') && $mtd2->get_variable('$va');
ok($var2 && $var2->isa("PlSense::Symbol::Variable") && $var2->get_name eq '$va', "get stored variable");


done_testing();

