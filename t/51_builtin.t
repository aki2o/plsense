use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;
use PlSense::Builtin;

my $tmpdir = get_tmp_dir();
ok(-d $tmpdir, "get tmp directory");

my $builtin = PlSense::Builtin->new({ cachedir => $tmpdir });
ok($builtin->isa("PlSense::Builtin"), "new");

$builtin->remove();
$builtin->build();

ok($builtin->exist_variable('$ARG'), "exists builtin variable 1");
ok($builtin->exist_variable('%SIG'), "exists builtin variable 2");

ok($builtin->exist_method("abs"), "exists builtin function 1");
ok($builtin->exist_method("write"), "exists builtin function 2");


done_testing();

