use Test::More;
use FindBin;
use List::AllUtils qw{ first };
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $workpath = get_work_dir();
my $confpath = "$workpath/.plsense";
my $logpath = "$workpath/plsense.log";
my $fh;

open $fh, '<', "$confpath";
ok($fh, "read config") or done_mytest();
my @confvalues = <$fh>;
$confvalues[1] = "logfile=$logpath\n";
$confvalues[2] = "loglevel=debug\n";
close $fh;

open $fh, '>', "$confpath";
ok($fh, "write config") or done_mytest();
print $fh join("", @confvalues);
close $fh;

my $addpath = "PATH=$FindBin::Bin/../blib/script:$FindBin::Bin/../bin:\${PATH} ; export PATH";
my $chhome = "HOME=$workpath ; export HOME";

system "$addpath ; $chhome ; plsense svstart > /dev/null";
ok(is_running(), "start server process") or done_mytest();
sleep 2;

my (@logs, @founds);

system "rm -f $logpath > /dev/null";
system "$addpath ; $chhome ; plsense loglevel info all > /dev/null";
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : info") >= 0 } @logs;
is( $#founds, 2, "up log level of all server" );

system "rm -f $logpath > /dev/null";
system "$addpath ; $chhome ; plsense loglevel debug all > /dev/null";
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : debug") >= 0 } @logs;
is( $#founds, -1, "no logging down log level of all server" );

system "$addpath ; $chhome ; plsense loglevel info main > /dev/null";
system "rm -f $logpath > /dev/null";
system "$addpath ; $chhome ; plsense loglevel debug all > /dev/null";
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : debug") >= 0 } @logs;
is( $#founds, 1, "logging down log level of other than main server" );

system "$addpath ; $chhome ; plsense loglevel info work > /dev/null";
system "rm -f $logpath > /dev/null";
system "$addpath ; $chhome ; plsense loglevel debug all > /dev/null";
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : debug") >= 0 } @logs;
is( $#founds, 1, "logging down log level of other than work server" );

system "$addpath ; $chhome ; plsense loglevel info resolve > /dev/null";
system "rm -f $logpath > /dev/null";
system "$addpath ; $chhome ; plsense loglevel debug all > /dev/null";
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : debug") >= 0 } @logs;
is( $#founds, 1, "logging down log level of other than resolve server" );

system "rm -f $logpath > /dev/null";
system "$addpath ; $chhome ; plsense loglevel debug > /dev/null";
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : debug") >= 0 } @logs;
is( $#founds, 0, "update log level of local" );

done_mytest();
exit 0;


sub is_running {
    my ($stat, $mainstat, $workstat, $resolvestat);

    $stat = qx{ $addpath ; $chhome ; plsense svstat };
    $mainstat = $stat =~ m{ ^ Main \s+ Server \s+ is \s+ Running\. $ }xms;
    $workstat = $stat =~ m{ ^ Work \s+ Server \s+ is \s+ Running\. $ }xms;
    $resolvestat = $stat =~ m{ ^ Resolve \s+ Server \s+ is \s+ Running\. $ }xms;
    return $mainstat && $workstat && $resolvestat ? 1 : 0;
}

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

