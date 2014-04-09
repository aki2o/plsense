use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $wait = wait_fin_timeout() || "";
ok($wait, "wait $wait for network timeout") or done_mytest();
run_plsense_testcmd("svstart > /dev/null");
ok(is_server_running(), "start server process") or done_mytest();
wait_fin_task();

my $leeway = 300; # KB
my @testsrcs = ( "$FindBin::Bin/sample/01_var.pl",
                 "$FindBin::Bin/sample2/01_chgproject.pl",
                 "$FindBin::Bin/sample3/01_chgproject.pl",
                 "$FindBin::Bin/sample4/01_chgproject.pl" );
REFRESH:
for ( my $i = 1; $i <= $#testsrcs + 1; $i++ ) {

    my $src = $testsrcs[$i-1];
    run_plsense_testcmd("open '$src' > /dev/null");
    wait_ready($src, 3, 20);
    wait_fin_task();
    is(get_current_file(), $src, "[Unit$i] Target Location is $src") or done_mytest();

    my $target_main_mem = get_proc_memory_quantity("plsense-server-main");
    my $target_work_mem = get_proc_memory_quantity("plsense-server-work");
    my $target_resolve_mem = get_proc_memory_quantity("plsense-server-resolve");
    my @target_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
    ok($target_main_mem > 0 && $target_work_mem > 0 && $target_resolve_mem > 0 && $#target_readys >= 0,
       "[Unit$i] Target location resource :"
       ." MainMem[$target_main_mem]"
       ." WorkMem[$target_work_mem]"
       ." ResolveMem[$target_resolve_mem]"
       ." Readys[$#target_readys]") or done_mytest();

    SRC:
    foreach my $f ( @testsrcs ) {
        run_plsense_testcmd("open '$f' > /dev/null");
        wait_ready($f, 3, 20);
        wait_fin_task();
    }
    run_plsense_testcmd("open '$src' > /dev/null");
    wait_fin_task();
    is(get_current_file(), $src, "[Unit$i] Open all project file") or done_mytest();

    my $before_main_mem = get_proc_memory_quantity("plsense-server-main");
    my $before_work_mem = get_proc_memory_quantity("plsense-server-work");
    my $before_resolve_mem = get_proc_memory_quantity("plsense-server-resolve");
    my @before_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
    ok($before_main_mem > $target_main_mem &&
       $before_work_mem >= $target_work_mem &&
       $before_resolve_mem > $target_resolve_mem &&
       $#before_readys >= $#target_readys,
       "[Unit$i] All location resource :"
       ." MainMem[$before_main_mem]"
       ." WorkMem[$before_work_mem]"
       ." ResolveMem[$before_resolve_mem]"
       ." Readys[$#before_readys]");

    run_plsense_testcmd("refresh > /dev/null");
    wait_fin_task();
    ok(is_server_running(), "[Unit$i] Refresh all server") or done_mytest();

    my $after_main_mem = get_proc_memory_quantity("plsense-server-main");
    my $after_work_mem = get_proc_memory_quantity("plsense-server-work");
    my $after_resolve_mem = get_proc_memory_quantity("plsense-server-resolve");
    my @after_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
    ok($after_main_mem < $before_main_mem &&
       $after_work_mem < $before_work_mem + $leeway &&
       $after_resolve_mem < $before_resolve_mem &&
       $#after_readys == $#target_readys,
       "[Unit$i] Resource is refreshed :"
       ." MainMem[$after_main_mem]"
       ." WorkMem[$after_work_mem]"
       ." ResolveMem[$after_resolve_mem]"
       ." Readys[$#after_readys]");

    is(get_current_file(), $src, "[Unit$i] Location is refreshed") or done_mytest();

}

done_mytest();
exit 0;


sub done_mytest {
    run_plsense_testcmd("svstop > /dev/null");
    ok(is_server_stopping(), "stop server process");
    done_testing();
    exit 0;
}

