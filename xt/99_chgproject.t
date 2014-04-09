use Test::More;
use FindBin;
use lib "$FindBin::Bin/../tlib";
use TestSupport;

my $wait = wait_fin_timeout() || "";
ok($wait, "wait $wait for network timeout") or done_mytest();
run_plsense_testcmd("svstart > /dev/null");
ok(is_server_running(), "start server process") or done_mytest();
wait_fin_task();

my ($projfile, $main_mem, $work_mem, $resolve_mem);


# Basic Project
$projfile = "$FindBin::Bin/sample/01_method.pl";
run_plsense_testcmd("open '$projfile' > /dev/null");
wait_ready($projfile, 3, 20);
wait_fin_task();

my $proj1nm = get_current_project();
is($proj1nm, "SampleProj", "Project1 name is $proj1nm");

my @proj1_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
ok(grep( { $_ eq "List::AllUtils" } @proj1_readys ), "$proj1nm readys installed module");
ok(grep( { $_ eq "BlessChild" } @proj1_readys ), "$proj1nm readys project module");
ok(! grep( { $_ eq "String::Random" } @proj1_readys ), "$proj1nm don't ready carton module");

$main_mem = get_proc_memory_quantity("plsense-server-main");
$work_mem = get_proc_memory_quantity("plsense-server-work");
$resolve_mem = get_proc_memory_quantity("plsense-server-resolve");
ok($main_mem > 0 && $work_mem > 0 && $resolve_mem > 0, "Memory consumption is main[$main_mem] work[$work_mem] resolve[$resolve_mem]");


# Other Project
$projfile = "$FindBin::Bin/sample2/01_chgproject.pl";
run_plsense_testcmd("open '$projfile' > /dev/null");
wait_ready($projfile, 3, 20);
wait_fin_task();

my $proj2nm = get_current_project();
is($proj2nm, "OtherProj", "Project2 name is $proj2nm");

my @proj2_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
ok(grep( { $_ eq "List::AllUtils" } @proj2_readys ), "$proj2nm readys installed module");
ok(! grep( { $_ eq "BlessChild" } @proj2_readys ), "$proj2nm don't ready project module");
ok(! grep( { $_ eq "String::Random" } @proj2_readys ), "$proj2nm don't ready carton module");
ok($#proj2_readys < $#proj1_readys,
   "$proj2nm readys[$#proj2_readys] is less than $proj1nm readys[$#proj1_readys]");

$main_mem = get_proc_memory_quantity("plsense-server-main");
$work_mem = get_proc_memory_quantity("plsense-server-work");
$resolve_mem = get_proc_memory_quantity("plsense-server-resolve");
ok($main_mem > 0 && $work_mem > 0 && $resolve_mem > 0, "Memory consumption is main[$main_mem] work[$work_mem] resolve[$resolve_mem]");


# Local Project
$projfile = "$FindBin::Bin/sample3/01_chgproject.pl";
run_plsense_testcmd("open '$projfile' > /dev/null");
wait_ready($projfile, 3, 20);
wait_fin_task();

my $proj3nm = get_current_project();
is($proj3nm, "LocalProj", "Project3 name is $proj3nm");

my @proj3_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
ok(! grep( { $_ eq "List::AllUtils" } @proj3_readys ), "$proj3nm don't ready installed module");
ok(! grep( { $_ eq "String::Random" } @proj3_readys ), "$proj3nm don't ready carton module");
ok($#proj3_readys >= 0 && $#proj3_readys < $#proj2_readys,
   "$proj3nm readys[$#proj3_readys] is less than $proj2nm readys[$#proj2_readys]");

$main_mem = get_proc_memory_quantity("plsense-server-main");
$work_mem = get_proc_memory_quantity("plsense-server-work");
$resolve_mem = get_proc_memory_quantity("plsense-server-resolve");
ok($main_mem > 0 && $work_mem > 0 && $resolve_mem > 0, "Memory consumption is main[$main_mem] work[$work_mem] resolve[$resolve_mem]");


# Carton Project
$projfile = "$FindBin::Bin/sample4/01_chgproject.pl";
run_plsense_testcmd("open '$projfile' > /dev/null");
wait_ready($projfile, 3, 20);
wait_fin_task();

my $proj4nm = get_current_project();
is($proj4nm, "CartonProj", "Project4 name is $proj4nm");

my @proj4_readys = split m{ \s+ }xms, get_plsense_testcmd_result("ready");
ok(grep( { $_ eq "String::Random" } @proj4_readys ), "$proj4nm readys carton module");
# At present, Carton means local = 1
ok($#proj4_readys < $#proj2_readys, "$proj4nm readys[$#proj4_readys] is less than $proj2nm readys[$#proj2_readys]");

$main_mem = get_proc_memory_quantity("plsense-server-main");
$work_mem = get_proc_memory_quantity("plsense-server-work");
$resolve_mem = get_proc_memory_quantity("plsense-server-resolve");
ok($main_mem > 0 && $work_mem > 0 && $resolve_mem > 0, "Memory consumption is main[$main_mem] work[$work_mem] resolve[$resolve_mem]");


done_mytest();
exit 0;


sub done_mytest {
    run_plsense_testcmd("svstop > /dev/null");
    ok(is_server_stopping(), "stop server process");
    done_testing();
    exit 0;
}

