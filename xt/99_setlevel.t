use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $workpath = get_work_dir();
my $confpath = "$workpath/.plsense";
my $logpath = "$workpath/plsense.log";
my $fh;

open $fh, '<', "$confpath";
ok($fh, "read config") or done_mytest();
my @confvalues = <$fh>;
$confvalues[2] = "logfile=$logpath\n";
$confvalues[3] = "loglevel=debug\n";
close $fh;

open $fh, '>', "$confpath";
ok($fh, "write config") or done_mytest();
print $fh join("", @confvalues);
close $fh;

my $wait = wait_fin_timeout() || "";
ok($wait, "wait $wait for network timeout") or done_mytest();
run_plsense_testcmd("svstart > /dev/null");
ok(is_server_running(), "start server process") or done_mytest();
sleep 5;

WAIT_SWITCH:
for ( my $i = 0; $i <= 50; $i++ ) {
    if ( is_server_running() ) { last WAIT_SWITCH; }
    sleep 6;
}

my (@logs, @founds);

system "rm -f $logpath > /dev/null";
run_plsense_testcmd("loglevel info all > /dev/null");
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : info") >= 0 } @logs;
is( $#founds, 2, "up log level of all server" );

system "rm -f $logpath > /dev/null";
run_plsense_testcmd("loglevel debug all > /dev/null");
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : debug") >= 0 } @logs;
is( $#founds, -1, "no logging down log level of all server" );

run_plsense_testcmd("loglevel info main > /dev/null");
system "rm -f $logpath > /dev/null";
run_plsense_testcmd("loglevel debug all > /dev/null");
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : debug") >= 0 } @logs;
is( $#founds, 1, "logging down log level of other than main server" );

run_plsense_testcmd("loglevel info work > /dev/null");
system "rm -f $logpath > /dev/null";
run_plsense_testcmd("loglevel debug all > /dev/null");
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : debug") >= 0 } @logs;
is( $#founds, 1, "logging down log level of other than work server" );

run_plsense_testcmd("loglevel info resolve > /dev/null");
system "rm -f $logpath > /dev/null";
run_plsense_testcmd("loglevel debug all > /dev/null");
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : debug") >= 0 } @logs;
is( $#founds, 1, "logging down log level of other than resolve server" );

system "rm -f $logpath > /dev/null";
run_plsense_testcmd("loglevel debug > /dev/null");
open $fh, '<', "$logpath";
ok($fh, "read logfile") or done_mytest();
@logs = <$fh>;
close $fh;
@founds = grep { index($_, "Update log level : debug") >= 0 } @logs;
is( $#founds, 0, "update log level of local" );

done_mytest();
exit 0;


sub done_mytest {
    run_plsense_testcmd("svstop > /dev/null");
    ok(is_server_stopping(), "stop server process");
    done_testing();
    exit 0;
}

