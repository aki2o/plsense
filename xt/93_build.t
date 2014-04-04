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

wait_fin_task();
done_mytest();
exit 0;


sub done_mytest {
    run_plsense_testcmd("svstop > /dev/null");
    ok(is_server_stopping(), "stop server process");
    done_testing();
    exit 0;
}

