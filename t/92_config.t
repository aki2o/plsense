use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $tmpdir = get_tmp_dir();
ok(-d $tmpdir, "get tmp directory") or done_mytest();

my @unusedports = get_unused_port();
is($#unusedports, 2, "get unused port") or done_mytest();
my ($mainport, $workport, $resolveport) = @unusedports;

my $workpath = get_work_dir();
if ( ! -d $workpath ) {
    ok(mkdir($workpath), "create work home") or done_mytest();
}

my $confpath = "$workpath/.plsense";
if ( -f $confpath ) {
    ok(unlink($confpath), "init config") or done_mytest();
}

my $addpath = "PATH=$FindBin::Bin/../blib/script:$FindBin::Bin/../bin:\${PATH} ; export PATH";
my $chhome = "HOME=$workpath ; export HOME";

# cancel
my $ret = qx{ $addpath ; $chhome ; echo n | plsense 2> /dev/null };
ok($ret =~ m{ ^ Making\? \s+ \(Y/n\) \s+ Not \s+ create }xms, "show message about not created");
ok(! -f $confpath, "not created config");

my $fh;

# do default
open $fh, '>', "$workpath/.param";
ok($fh, "open parameter") or done_mytest();

print $fh "\n";
print $fh "\n";
print $fh "\n";
print $fh "\n";
print $fh "\n";
print $fh "\n";
close $fh;

$ret = qx{ $addpath ; $chhome ; plsense < '$workpath/.param' };
ok(-f $confpath, "created config");

open $fh, '<', "$confpath";
ok($fh, "open config") or done_mytest();

my @confvalues = <$fh>;
close $fh;

is($#confvalues, 9, "default config entry count");
is($confvalues[0], "cachedir=$workpath/.plsense.d\n", "default config about cache directory");
is($confvalues[1], "clean-env=0\n", "default config about whether clean env");
is($confvalues[2], "logfile=\n", "default config about log file");
is($confvalues[3], "loglevel=\n", "default config about log level");
is($confvalues[4], "maxtasks=20\n", "default config about task limit");
is($confvalues[5], "perl=perl\n", "default config about perl");
is($confvalues[6], "perldoc=perldoc\n", "default config about perldoc");
is($confvalues[7], "port1=33333\n", "default config about main port");
is($confvalues[8], "port2=33334\n", "default config about work port");
is($confvalues[9], "port3=33335\n", "default config about resolve port");

# update
open $fh, '>', "$workpath/.param";
ok($fh, "open parameter") or done_mytest();

print $fh "$tmpdir\n";
print $fh "$mainport\n";
print $fh "$workport\n";
print $fh "$resolveport\n";
print $fh "19\n";
close $fh;

$ret = qx{ $addpath ; $chhome ; plsense config < '$workpath/.param' };
ok(-f $confpath, "created config");

open $fh, '<', "$confpath";
ok($fh, "open config") or done_mytest();

@confvalues = <$fh>;
close $fh;

is($#confvalues, 9, "config entry count");
is($confvalues[0], "cachedir=$tmpdir\n", "config about cache directory");
is($confvalues[1], "clean-env=0\n", "config about whether clean env");
is($confvalues[2], "logfile=\n", "config about log file");
is($confvalues[3], "loglevel=\n", "config about log level");
is($confvalues[4], "maxtasks=19\n", "config about task limit");
is($confvalues[5], "perl=perl\n", "config about perl");
is($confvalues[6], "perldoc=perldoc\n", "config about perldoc");
is($confvalues[7], "port1=$mainport\n", "config about main port");
is($confvalues[8], "port2=$workport\n", "config about work port");
is($confvalues[9], "port3=$resolveport\n", "config about resolve port");


done_testing();
exit 0;


sub done_mytest {
    done_testing();
    exit 0;
}

