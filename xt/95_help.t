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
if ( $#testsrc < 0 ) { @testsrc = (glob("$FindBin::Bin/sample/*.pl") , glob("$FindBin::Bin/sample/lib/*.pm")); }

my ($fh, $cmdret);
BUILD:
foreach my $f ( @testsrc ) {

    my $openret = get_plsense_testcmd_result("open '$f'");
    chomp $openret;
    is($openret, "Done", "do open $f") or next SOURCE;

    wait_fin_task(1, 120);

    open $fh, '<', "$f";
    ok($fh, "open test source : $f") or done_mytest();

    my ($readcode, $testdesc, $testcode, $regexp) = (0, "", "", "");
    LINE:
    while ( my $line = <$fh> ) {

        chomp $line;
        $line =~ s{ ^\s+ }{}xms;

        if ( $line =~ m{ ^ package \s+ ([a-zA-Z0-9:]+) }xms ) {
            my $pkgnm = $1;
            $cmdret = get_plsense_testcmd_result("onmod $pkgnm");
            chomp $cmdret;
            is($cmdret, "Done", "set current module to $pkgnm") or last LINE;
        }

        elsif ( $line =~ m{ ^ sub \s+ ([^\s]+) }xms ) {
            my $subnm = $1;
            $cmdret = get_plsense_testcmd_result("onsub $subnm");
            chomp $cmdret;
            is($cmdret, "Done", "set current method to $subnm") or last LINE;
        }

        elsif ( $line =~ m{ ^ \# \s* hstart \s+ (.+) $ }xms ) {
            $testdesc = $1;
            $readcode = 1;
            $testcode = "";
        }

        elsif ( $line =~ m{ ^ \# \s* hend \s+ ([^\n]+) $ }xms ) {
            $regexp = $1;
            $readcode = 0;
            $cmdret = get_plsense_testcmd_result("codehelp '$testcode'");
            if ( ! ok($cmdret =~ m{ $regexp }xms, "help check $testdesc match $regexp") ) {
                print STDERR "$cmdret";
            }
        }

        elsif ( $readcode ) {
            $line =~ s{ ^ \# }{}xms;
            if ( $testcode ) { $testcode .= " "; }
            $testcode .= $line;
        }

    }

    close $fh;
}


done_mytest();
exit 0;


sub done_mytest {
    run_plsense_testcmd("svstop > /dev/null");
    ok(is_server_stopping(), "stop server process");
    done_testing();
    exit 0;
}

