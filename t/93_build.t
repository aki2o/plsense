use Test::More;
use FindBin;
use List::AllUtils qw{ first };
use lib "$FindBin::Bin/lib";
use TestSupport;

my $workpath = get_work_dir();
my $addpath = "PATH=$FindBin::Bin/../bin:\${PATH} ; export PATH";
my $chhome = "HOME=$workpath ; export HOME";
my ($stat, $mainstat, $workstat, $resolvestat);

system "$addpath ; $chhome ; plsense svstart > /dev/null";
$stat = qx{ $addpath ; $chhome ; plsense svstat };
$mainstat = $stat =~ m{ ^ Main \s+ Server \s+ is \s+ Running\. $ }xms;
$workstat = $stat =~ m{ ^ Work \s+ Server \s+ is \s+ Running\. $ }xms;
$resolvestat = $stat =~ m{ ^ Resolve \s+ Server \s+ is \s+ Running\. $ }xms;
ok($mainstat && $workstat && $resolvestat, "start server process") or done_mytest();

BUILD:
foreach my $f ( glob "$FindBin::Bin/sample/*.pl" ) {
    system "$addpath ; $chhome ; plsense open $f > /dev/null";
}

my $count = 0;
WAIT_IDLE:
while ( $count < 100 ) {
    my $ps = qx{ $addpath ; $chhome ; plsense ps };
    $ps =~ s{ ^\s+ }{}xms;
    $ps =~ s{ \s+$ }{}xms;
    if ( ! $ps ) { last WAIT_IDLE; }
    sleep 10;
    $count++;
}

my $readyret = qx{ $addpath ; $chhome ; plsense ready };
$readyret =~ s{ \n }{ }xmsg;
my @readys = split m{ \s+ }xms, $readyret;
CHK_READY:
foreach my $pkgnm ( qw{ IO::File FindBin File::Spec ClassStdParent IO::Handle Class::Std } ) {
    my $include = first { $_ eq $pkgnm } @readys;
    ok($include, "build sample : $pkgnm");
}


done_mytest();
exit 0;


sub done_mytest {
    my ($stat, $mainstat, $substat);

    system "$addpath ; $chhome ; plsense svstop > /dev/null";
    $stat = qx{ $addpath ; $chhome ; plsense svstat };
    $mainstat = $stat =~ m{ ^ Main \s+ Server \s+ is \s+ Not \s+ running\. $ }xms;
    $workstat = $stat =~ m{ ^ Work \s+ Server \s+ is \s+ Not \s+ running\. $ }xms;
    $resolvestat = $stat =~ m{ ^ Resolve \s+ Server \s+ is \s+ Not \s+ running\. $ }xms;
    ok($mainstat && $workstat && $resolvestat, "stop server process");

    done_testing();
    exit 0;
}

