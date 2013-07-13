use Test::More;
use PlSense::Entity::Hash;
use PlSense::Entity::Null;

my $e = PlSense::Entity::Hash->new({});
ok($e->isa("PlSense::Entity::Hash"), "new");
is($e->get_type, "hash", "get type");
is($e->to_string, "H<>", "to string");

ok(! $e->exist_member("hoge"), "not exist member");
$e->set_membernm("hoge");
$e->set_member(PlSense::Entity::Null->new());
ok($e->exist_member("hoge"), "exist member");
is($e->to_string, "H<hoge => NULL, >", "to string in null");

my $ee = $e->clone;
ok($ee->exist_member("hoge"), "exist member in clone");
is($ee->to_string, "H<hoge => NULL, >", "to string of clone");

done_testing();

