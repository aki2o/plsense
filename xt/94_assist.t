use Test::More;
use FindBin;
use List::AllUtils qw{ first };
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
SOURCE:
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

    my ($readcode, $testdesc, $testcode, $testmethod, $expected) = (0, "", "", "", "");
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

        elsif ( $line =~ m{ ^ \# \s* astart \s+ (.+) $ }xms ) {
            $testdesc = $1;
            $readcode = 1;
            $testcode = "";
        }

        elsif ( $line =~ m{ ^ \# \s* aend \s+ ([a-z]+): \s* (.*) \s* $ }xms ) {
            ($testmethod, $expected) = ($1, $2);
            $readcode = 0;
            $cmdret = qx{ $addpath ; $chhome ; plsense assist '$testcode' };
            $cmdret =~ s{ \n+ }{ }xmsg;
            $cmdret =~ s{ \s+ }{ }xmsg;
            $cmdret =~ s{ \A \s+ }{}xms;
            $cmdret =~ s{ \s+ \z }{}xms;
            if ( $testmethod eq "equal" ) {
                is($cmdret, $expected, "assist check $testmethod $testdesc");
            }
            elsif ( $testmethod eq "include" ) {
                my @rets = split m{ \s+ }xms, $cmdret;
                my $include = 1;
                EXPECT:
                foreach my $e ( split m{ \s+ }xms, $expected ) {
                    my $found = first { $_ eq $e } @rets;
                    if ( ! $found ) {
                        $include = 0;
                        print STDERR "Not included a expected value [$e]\n";
                        last EXPECT;
                    }
                }
                ok($include, "assist check $testmethod $testdesc");
            }
            elsif ( $testmethod eq "exclude" ) {
                my @rets = split m{ \s+ }xms, $cmdret;
                my $exclude = 1;
                EXPECT:
                foreach my $e ( split m{ \s+ }xms, $expected ) {
                    my $found = first { $_ eq $e } @rets;
                    if ( $found ) {
                        $exclude = 0;
                        print STDERR "Not excluded a expected value [$e]\n";
                        last EXPECT;
                    }
                }
                ok($exclude, "assist check $testmethod $testdesc");
            }
        }

        elsif ( $line =~ m{ ^ \# \s* ahelp \s+ ([^\s]+) \s+ : \s+ ([^\n]+) $ }xms ) {
            my ($cand, $regexp) = ($1, $2);
            $cmdret = qx{ $addpath ; $chhome ; plsense assisthelp $cand };
            if ( ! ok($cmdret =~ m{ $regexp }xms, "assist help $cand match '$regexp' at $testdesc") ) {
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

