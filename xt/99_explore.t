use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $wait = wait_fin_timeout() || "";
ok($wait, "wait $wait for network timeout") or done_mytest();
run_plsense_testcmd("svstart > /dev/null");
ok(is_server_running(), "start server process") or done_mytest();

FILE:
foreach my $f ( glob("$FindBin::Bin/sample/*.pl") ) {
    run_plsense_testcmd("onfile '$f' > /dev/null");
    last FILE;
}
sleep 2;

WAIT_SWITCH:
for ( my $i = 0; $i <= 50; $i++ ) {
    if ( is_server_running() ) { last WAIT_SWITCH; }
    sleep 6;
}

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

my $cmdret = get_plsense_testcmd_result("explore ^Bless[A-Z]");
like( $cmdret, qr{ \A $expect \z }xms, "explore match" );

$cmdret = get_plsense_testcmd_result("explore");
like( $cmdret, qr{ .+ $expect .+ }xms, "explore all" );

$cmdret = get_plsense_testcmd_result("explore ^HogeFugaBar\$");
is( $cmdret, "", "explore no match" );

done_mytest();
exit 0;


sub done_mytest {
    run_plsense_testcmd("svstop > /dev/null");
    ok(is_server_stopping(), "stop server process");
    done_testing();
    exit 0;
}

