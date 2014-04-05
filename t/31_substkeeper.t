use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;
use PlSense::Configure;
use PlSense::Util;
use PlSense::ModuleKeeper;
use PlSense::AddressRouter;
use PlSense::SubstituteKeeper;

my $tmpdir = get_tmp_dir();
ok(-d $tmpdir, "get tmp directory");

set_primary_config(cachedir => $tmpdir);
setup_config();
set_mdlkeeper(PlSense::ModuleKeeper->new());
set_addrrouter(PlSense::AddressRouter->new({ with_build => 0 }));
my $substkeeper = PlSense::SubstituteKeeper->new();
ok($substkeeper->isa("PlSense::SubstituteKeeper"), "new");

my $debugstr = $substkeeper->to_string_by_regexp('.+');
is($debugstr, "", "not yet exist subst");

$substkeeper->add_substitute("leftaddr1", "rightaddr1");
$debugstr = $substkeeper->to_string_by_regexp('.+');
is($debugstr, "leftaddr1 -> rightaddr1\n", "regist subst");

$substkeeper->store("Hoge", "/tmp/Hoge.pm");

$substkeeper->reset;
$debugstr = $substkeeper->to_string_by_regexp('.+');
is($debugstr, "", "reset subst");

$substkeeper->load("Hoge", "/tmp/Hoge.pm");
$debugstr = $substkeeper->to_string_by_regexp('.+');
is($debugstr, "leftaddr1 -> rightaddr1\n", "stored subst");


done_testing();

