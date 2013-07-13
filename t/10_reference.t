use Test::More;
use PlSense::Entity::Reference;
use PlSense::Entity::Null;

my $e = PlSense::Entity::Reference->new();
ok($e->isa("PlSense::Entity::Reference"), "new");
is($e->get_type, "reference", "get type");
is($e->to_string, "R<>", "to string");

$e->set_entity();

done_testing();













