use Test::More;
use PlSense::Entity::Reference;
use PlSense::Entity::Scalar;

my $e = PlSense::Entity::Reference->new();
ok($e->isa("PlSense::Entity::Reference"), "new");
is($e->get_type, "reference", "get type");
is($e->to_string, "R<>", "to string");

$e->set_entity(PlSense::Entity::Scalar->new({ value => "hoge", }));
is($e->to_string, "R<S<hoge>>", "to string after set");

my $ee = $e->clone();
ok($ee->isa("PlSense::Entity::Reference"), "clone");
my $entity = $ee->get_entity;
is($entity->to_string, "S<hoge>", "to string of entity in clone");

done_testing();













