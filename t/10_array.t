use Test::More;
use PlSense::Entity::Array;
use PlSense::Entity::Null;

my $e = PlSense::Entity::Array->new();
ok($e->isa("PlSense::Entity::Array"), "new");
is($e->get_type, "array", "get type");
is($e->to_string, "A<>", "to string");

$e->set_element(PlSense::Entity::Null->new());
is($e->to_string, "A<NULL>", "to string in null");
$e->push_address('$PlSense::VERSION');
is($e->to_string, "A<NULL | $PlSense::VERSION>", "to string in address");

my $ee = $e->clone;
ok($ee->isa("PlSense::Entity::Array"), "clone");
is($ee->to_string, "A<NULL | $PlSense::VERSION>", "to string of clone");

done_testing();
