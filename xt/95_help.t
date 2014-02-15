use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $workpath = get_work_dir();
my $addpath = "PATH=$FindBin::Bin/../blib/script:$FindBin::Bin/../bin:\${PATH} ; export PATH";
my $chhome = "HOME=$workpath ; export HOME";

system "$addpath ; $chhome ; plsense svstart > /dev/null";
ok(is_running(), "start server process") or done_mytest();

my @testsrc = grep { -f $_ } @ARGV;
if ( $#testsrc < 0 ) { @testsrc = split m{ : }xms, $ENV{PLSENSE_TEST_SOURCE}; }
if ( $#testsrc < 0 ) { @testsrc = (glob("$FindBin::Bin/sample/*.pl") , glob("$FindBin::Bin/sample/lib/*.pm")); }

my ($fh, $cmdret);
BUILD:
foreach my $f ( @testsrc ) {

    my $openret = qx{ $addpath ; $chhome ; plsense open '$f' };
    chomp $openret;
    is($openret, "Done", "do open $f") or next SOURCE;

    my $count = 0;
    WAIT_IDLE:
    while ( $count < 120 ) {
        my $ps = qx{ $addpath ; $chhome ; plsense ps };
        $ps =~ s{ ^\s+ }{}xms;
        $ps =~ s{ \s+$ }{}xms;
        if ( ! $ps && is_running() ) { last WAIT_IDLE; }
        sleep 1;
        $count++;
    }

    open $fh, '<', "$f";
    ok($fh, "open test source : $f") or done_mytest();

    my ($readcode, $testdesc, $testcode, $regexp) = (0, "", "", "");
    LINE:
    while ( my $line = <$fh> ) {

        chomp $line;
        $line =~ s{ ^\s+ }{}xms;

        if ( $line =~ m{ ^ package \s+ ([a-zA-Z0-9:]+) }xms ) {
            my $pkgnm = $1;
            $cmdret = qx{ $addpath ; $chhome ; plsense onmod $pkgnm };
            chomp $cmdret;
            is($cmdret, "Done", "set current module to $pkgnm") or last LINE;
        }

        elsif ( $line =~ m{ ^ sub \s+ ([^\s]+) }xms ) {
            my $subnm = $1;
            $cmdret = qx{ $addpath ; $chhome ; plsense onsub $subnm };
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
            $cmdret = qx{ $addpath ; $chhome ; plsense codehelp '$testcode' };
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

