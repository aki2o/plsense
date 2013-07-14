use Test::More;
use PlSense::Symbol::Variable;

my $var = PlSense::Symbol::Variable->new({ name => '$hoge', });
ok($var->isa("PlSense::Symbol::Variable"), "new");
is($var->get_name, '$hoge', "get name");


done_testing();

