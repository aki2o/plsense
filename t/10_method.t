use Test::More;
use PlSense::Symbol::Method;

my $mtd = PlSense::Symbol::Method->new({ name => "fuga", });
ok($mtd->isa("PlSense::Symbol::Method"), "new");
is($mtd->get_name, "fuga", "get name");


done_testing();

