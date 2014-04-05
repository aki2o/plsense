use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $wait = wait_fin_timeout() || "";
ok($wait, "wait $wait for network timeout") or done_mytest();
run_plsense_testcmd("svstart > /dev/null");
ok(is_server_running(), "start server process") or done_mytest();
wait_fin_task();

my $src = "$FindBin::Bin/sample/01_var.pl";
run_plsense_testcmd("open '$src' > /dev/null");
wait_ready($src, 3, 20);
wait_fin_task();

my @before_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
ok($#before_readys > 0, "ready $#before_readys modules before refresh") or done_mytest();

BUILD:
foreach my $f ( glob("$FindBin::Bin/sample/*.pl") ) {
    run_plsense_testcmd("open '$f' > /dev/null");
    wait_ready($f, 3, 20);
}
run_plsense_testcmd("open '$src' > /dev/null");
wait_fin_task();

my $before_main_mem = get_proc_memory_quantity("plsense-server-main");
my $before_work_mem = get_proc_memory_quantity("plsense-server-work");
my $before_resolve_mem = get_proc_memory_quantity("plsense-server-resolve");

run_plsense_testcmd("refresh > /dev/null");
wait_fin_task();

ok(is_server_running(), "server alive after refresh") or done_mytest();

my $after_main_mem = get_proc_memory_quantity("plsense-server-main");
my $after_work_mem = get_proc_memory_quantity("plsense-server-work");
my $after_resolve_mem = get_proc_memory_quantity("plsense-server-resolve");
ok($after_main_mem < $before_main_mem, "main server is refreshed. mem:[$before_main_mem]->[$after_main_mem]");
ok($after_work_mem < $before_work_mem, "work server is refreshed. mem:[$before_work_mem]->[$after_work_mem]");
ok($after_resolve_mem < $before_resolve_mem, "resolve server is refreshed. mem:[$before_resolve_mem]->[$after_resolve_mem]");

my @after_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
is($#after_readys, $#before_readys, "ready modules is refreshed");

my $loc = get_plsense_testcmd_result("loc");
my $currfilepath = $loc =~ m{ ^ File: \s+ ([^\n]*?) $ }xms ? $1 : "";
is($currfilepath, $src, "location is restored");

done_mytest();
exit 0;


sub done_mytest {
    run_plsense_testcmd("svstop > /dev/null");
    ok(is_server_stopping(), "stop server process");
    done_testing();
    exit 0;
}

