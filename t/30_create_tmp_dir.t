use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $tmpdir = create_tmp_dir();
ok(-d $tmpdir, "create tmp directory");

done_testing();

