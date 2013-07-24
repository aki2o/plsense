use Test::More;
use PlSense::Entity::Null;

my $e = PlSense::Entity::Null->new();
ok($e->isa("PlSense::Entity::Null"), "new");
is($e->get_type, "null", "get type");
is($e->to_string, "NULL", "to string");

my $ee = $e->clone;
ok($ee->isa("PlSense::Entity::Null"), "clone");
is($ee->to_string, "NULL", "to string of clone");


done_testing();
