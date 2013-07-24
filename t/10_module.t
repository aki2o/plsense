use Test::More;
use FindBin;
use PlSense::Symbol::Module;

my $filepath = $FindBin::Bin."/../tlib/TestSupport.pm";
my $mdl = PlSense::Symbol::Module->new({ name => "TestSupport", filepath => $filepath, lastmodified => 0, });
ok($mdl->isa("PlSense::Symbol::Module"), "new");
is($mdl->get_name, "TestSupport", "get name");


done_testing();

