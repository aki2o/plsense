use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $wait = wait_fin_timeout() || "";
ok($wait, "wait $wait for network timeout") or done_mytest();
run_plsense_testcmd("svstart > /dev/null");
ok(is_server_running(), "start server process") or done_mytest();

my @testsrc = grep { -f $_ } @ARGV;
if ( $#testsrc < 0 ) { @testsrc = split m{ : }xms, $ENV{PLSENSE_TEST_SOURCE}; }
if ( $#testsrc < 0 ) { @testsrc = glob("$FindBin::Bin/sample/*.pl"); }

BUILD:
foreach my $f ( @testsrc ) {
    run_plsense_testcmd("open '$f' > /dev/null");
    sleep 1;
    WAIT_READY:
    for ( my $i = 0; $i <= 40; $i++ ) {
        my $readyret = get_plsense_testcmd_result("ready '$f'");
        chomp $readyret;
        if ( $readyret eq "Yes" ) { last WAIT_READY; }
        sleep 3;
    }
}

if ( $#testsrc == 0 ) {
    run_plsense_testcmd("update '".$testsrc[0]."' > /dev/null");
    wait_fin_task(2, 60);
}

WAIT_MDL_READY:
for ( my $i = 0; $i <= 100; $i++ ) {
    my @readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
    my $notyet = 0;
    MDL:
    foreach my $mdl ( qw{ File::Spec File::Basename File::Copy FindBin Class::Std Exporter
                          List::Util List::MoreUtils List::AllUtils IO::File IO::Socket
                          MtdExport BlessParent BlessChild ClassStdParent ClassStdChild } ) {
        if ( ! grep { $_ eq $mdl } @readys ) {
            $notyet = 1;
            last MDL;
        }
    }
    if ( ! $notyet ) { last WAIT_MDL_READY; }
    sleep 6;
}
wait_fin_task();

my $notready;
CHK_READY:
foreach my $f ( @testsrc ) {
    my $readyret = get_plsense_testcmd_result("ready '$f'");
    chomp $readyret;
    is($readyret, "Yes", "check ready $f") or $notready = 1;
}
if ( $notready ) {
    print STDERR "The result of ready\n".get_plsense_testcmd_result("ready")."\n";
}

done_mytest();
exit 0;


sub done_mytest {
    run_plsense_testcmd("svstop > /dev/null");
    ok(is_server_stopping(), "stop server process");
    done_testing();
    exit 0;
}

