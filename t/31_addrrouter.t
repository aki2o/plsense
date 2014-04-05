use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;
use PlSense::Configure;
use PlSense::Util;
use PlSense::ModuleKeeper;
use PlSense::AddressRouter;
use PlSense::Entity::Scalar;

my $tmpdir = get_tmp_dir();
ok(-d $tmpdir, "get tmp directory");

set_primary_config(cachedir => $tmpdir);
setup_config();
set_mdlkeeper(PlSense::ModuleKeeper->new());
my $addrrouter = PlSense::AddressRouter->new({ with_build => 0 });
ok($addrrouter->isa("PlSense::AddressRouter"), "new");

my @routes;
@routes = $addrrouter->get_route("addr1");
ok($#routes < 0, "not regist route");

$addrrouter->add_route("addr1", "resolve1");
@routes = $addrrouter->get_route("addr1");
ok($#routes == 0 && $routes[0] eq "resolve1", "registed route 1");

$addrrouter->add_route("addr1", PlSense::Entity::Scalar->new({ value => "resolve2", }));
@routes = $addrrouter->get_route("addr1");
ok($#routes == 1 && $routes[0] eq "resolve1", "registed route 1 of 2");
ok($#routes == 1 && $routes[1]->isa("PlSense::Entity::Scalar") && $routes[1]->get_value eq "resolve2", "registed route 2 of 2");

$addrrouter->store_current_project;

$addrrouter->reset;
@routes = $addrrouter->get_route("addr1");
ok($#routes < 0, "reset route");

$addrrouter->load_current_project;
@routes = $addrrouter->get_route("addr1");
ok($#routes == 1 && $routes[0] eq "resolve1", "stored route 1 of 2");
ok($#routes == 1 && $routes[1]->isa("PlSense::Entity::Scalar") && $routes[1]->get_value eq "resolve2", "stored route 2 of 2");


done_testing();

