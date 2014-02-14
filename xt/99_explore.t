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

FILE:
foreach my $f ( glob("$FindBin::Bin/sample/*.pl") ) {
    system "$addpath ; $chhome ; plsense onfile '$f' > /dev/null";
    last FILE;
}
sleep 2;

my $expect = 'BlessChild \s .+/BlessChild\.pm \s 11:1\n';
$expect .= '\s\s &get_bar \s 32:1\n';
$expect .= '\s\s &get_foo \s 41:1\n';
$expect .= '\s\s &new \s 20:1\n';
$expect .= '\s\s &set_bar \s 27:1\n\n';
$expect .= 'BlessParent \s .+/BlessParent\.pm \s 1:1\n';
$expect .= '\s\s &get_fuga \s 40:1\n';
$expect .= '\s\s &get_hoge \s 26:1\n';
$expect .= '\s\s &new \s 6:1\n';
$expect .= '\s\s &set_fuga \s 35:1\n';
$expect .= '\s\s &set_hoge \s 17:1\n\n';

my $cmdret = qx{ $addpath ; $chhome ; plsense explore ^Bless[A-Z] };
like( $cmdret, qr{ \A $expect \z }xms, "explore match" );

$cmdret = qx{ $addpath ; $chhome ; plsense explore };
like( $cmdret, qr{ .+ $expect .+ }xms, "explore all" );

$cmdret = qx{ $addpath ; $chhome ; plsense explore ^HogeFugaBar\$ };
is( $cmdret, "", "explore no match" );

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

