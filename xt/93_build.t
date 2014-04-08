use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $wait = wait_fin_timeout() || "";
ok($wait, "wait $wait for network timeout") or done_mytest();
run_plsense_testcmd("svstart > /dev/null");
ok(is_server_running(), "start server process") or done_mytest();

my @testsrcs;
if ( @testsrcs = grep { -f $_ } @ARGV ) {
    do_build_test(\@testsrcs, undef, 1, undef);
}
elsif ( @testsrcs = split m{ : }xms, $ENV{PLSENSE_TEST_SOURCE} ) {
    do_build_test(\@testsrcs, undef, 0, undef);
}
else {
    PROJ:
    foreach my $projdir ( "sample", "sample2", "sample3" ) {
        @testsrcs = glob("$FindBin::Bin/$projdir/*.pl");
        my @usingmdls = used_modules($projdir);
        do_build_test(\@testsrcs, \@usingmdls, 0, $projdir);
    }
}

done_mytest();
exit 0;


sub done_mytest {
    run_plsense_testcmd("svstop > /dev/null");
    ok(is_server_stopping(), "stop server process");
    done_testing();
    exit 0;
}

sub do_build_test {
    my $testsrcs = shift or return;
    my $waited_modules = shift || [];
    my $update = shift || 0;
    my $test_ident = shift || "NoIdent";

    SRC:
    foreach my $f ( @{$testsrcs} ) {
        run_plsense_testcmd("open '$f' > /dev/null");
        wait_ready($f, 3, 40);
    }

    if ( $update ) {
        SRC:
        foreach my $f ( @{$testsrcs} ) {
            run_plsense_testcmd("update '$f' > /dev/null");
            wait_ready($f, 3, 40);
        }
    }

    WAIT_MDL_READY:
    for ( my $i = 0; $i <= 100; $i++ ) {
        my @readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
        my $notyet = 0;
        MDL:
        foreach my $mdl ( @{$waited_modules} ) {
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
    foreach my $f ( @{$testsrcs} ) {
        my $readyret = get_plsense_testcmd_result("ready '$f'");
        chomp $readyret;
        is($readyret, "Yes", "check ready $f") or $notready = 1;
    }
    if ( $notready ) {
        print STDERR "The result of ready in $test_ident\n".get_plsense_testcmd_result("ready")."\n";
    }

}

