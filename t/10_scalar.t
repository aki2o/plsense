use Test::More;
use PlSense::Entity::Scalar;

my $e = PlSense::Entity::Scalar->new();
ok($e->isa("PlSense::Entity::Scalar"), "new");
is($e->get_type, "scalar", "get type");
is($e->to_string, "S<>", "to string");

$e->set_value("hoge");
is($e->get_value, "hoge", "get value");
is($e->to_string, "S<hoge>", "to string after set value");

my $ee = $e->clone;
ok($ee->isa("PlSense::Entity::Scalar"), "clone");
is($ee->get_value, "hoge", "get value of clone");
is($ee->to_string, "S<hoge>", "to string of clone");

done_testing();
