use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $tmpdir = get_tmp_dir();
ok(-d $tmpdir, "get tmp directory") or done_mytest();

my @unusedports = get_unused_port();
is($#unusedports, 2, "get unused port") or done_mytest();
my ($mainport, $workport, $resolveport) = @unusedports;

my $commonopt = "--cachedir '$tmpdir' --port1 $mainport --port2 $workport --port3 $resolveport";
my $addpath = "PATH=$FindBin::Bin/../blib/script:$FindBin::Bin/../bin:\${PATH} ; export PATH";
my ($stat, $mainstat, $workstat, $resolvestat);

system "$addpath ; plsense $commonopt svstart > /dev/null";
$stat = qx{ $addpath ; plsense $commonopt svstat };
$mainstat = $stat =~ m{ ^ Main \s+ Server \s+ is \s+ Running\. $ }xms;
$workstat = $stat =~ m{ ^ Work \s+ Server \s+ is \s+ Running\. $ }xms;
$resolvestat = $stat =~ m{ ^ Resolve \s+ Server \s+ is \s+ Running\. $ }xms;
ok($mainstat && $workstat && $resolvestat, "start server process");

my $count = 0;
WAIT_IDLE:
while ( $count < 100 ) {
    my $ps = qx{ $addpath ; plsense $commonopt ps };
    $ps =~ s{ ^\s+ }{}xms;
    $ps =~ s{ \s+$ }{}xms;
    if ( ! $ps ) { last WAIT_IDLE; }
    sleep 2;
    $count++;
}

system "$addpath ; plsense $commonopt svstop > /dev/null";
$stat = qx{ $addpath ; plsense $commonopt svstat };
$mainstat = $stat =~ m{ ^ Main \s+ Server \s+ is \s+ Not \s+ running\. $ }xms;
$workstat = $stat =~ m{ ^ Work \s+ Server \s+ is \s+ Not \s+ running\. $ }xms;
$resolvestat = $stat =~ m{ ^ Resolve \s+ Server \s+ is \s+ Not \s+ running\. $ }xms;
ok($mainstat && $workstat && $resolvestat, "stop server process");


done_testing();
exit 0;


sub done_mytest {
    done_testing();
    exit 0;
}

