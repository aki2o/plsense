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

my $first_main_mem = get_proc_memory_quantity("plsense-server-main");
my $first_work_mem = get_proc_memory_quantity("plsense-server-work");
my $first_resolve_mem = get_proc_memory_quantity("plsense-server-resolve");
ok($first_main_mem > 0, "consume $first_main_mem mem in main server after first action");
ok($first_work_mem > 0, "consume $first_work_mem mem in work server after first action");
ok($first_resolve_mem > 0, "consume $first_resolve_mem mem in resolve server after first action");

my @first_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
ok($#first_readys > 0, "ready $#first_readys modules after first action") or done_mytest();

REFRESH:
for ( my $i = 1; $i <= 3; $i++ ) {

    OPEN:
    foreach my $f ( glob("$FindBin::Bin/sample/*.pl") ) {
        run_plsense_testcmd("open '$f' > /dev/null");
        wait_ready($f, 3, 20);
        CODEADD:
        for my $ii ( 1..100 ) {
            run_plsense_testcmd("codeadd my \$dummy_var$ii = { hoge => 'hoge$ii', fuga => 'fuga$ii' };");
        }
    }
    run_plsense_testcmd("open '$src' > /dev/null");
    wait_fin_task();

    my $before_main_mem = get_proc_memory_quantity("plsense-server-main");
    my $before_work_mem = get_proc_memory_quantity("plsense-server-work");
    my $before_resolve_mem = get_proc_memory_quantity("plsense-server-resolve");

    my @before_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
    ok($#before_readys > $#first_readys, "ready $#before_readys modules before refresh[$i]");

    run_plsense_testcmd("refresh > /dev/null");
    wait_fin_task();
    ok(is_server_running(), "all server alive after refresh[$i]") or done_mytest();

    my $after_main_mem = get_proc_memory_quantity("plsense-server-main");
    my $after_work_mem = get_proc_memory_quantity("plsense-server-work");
    my $after_resolve_mem = get_proc_memory_quantity("plsense-server-resolve");
    ok($after_main_mem < $before_main_mem, "refresh[$i] main server. mem:[$before_main_mem]->[$after_main_mem]");
    ok($after_work_mem < $before_work_mem, "refresh[$i] work server. mem:[$before_work_mem]->[$after_work_mem]");
    ok($after_resolve_mem < $before_resolve_mem, "refresh[$i] resolve server. mem:[$before_resolve_mem]->[$after_resolve_mem]");

    my @after_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
    is($#after_readys, $#first_readys, "refresh[$i] ready modules. $#before_readys -> $#after_readys");

    my $loc = get_plsense_testcmd_result("loc");
    my $currfilepath = $loc =~ m{ ^ File: \s+ ([^\n]*?) $ }xms ? $1 : "";
    is($currfilepath, $src, "restore[$i] location in refresh");

}

done_mytest();
exit 0;


sub done_mytest {
    run_plsense_testcmd("svstop > /dev/null");
    ok(is_server_stopping(), "stop server process");
    done_testing();
    exit 0;
}

