#!/usr/bin/perl

package TestSupport;

use strict;
use warnings;
use Exporter 'import';
use FindBin;
use File::Path;
use IO::Socket;
our @EXPORT = qw( get_tmp_dir
                  get_work_dir
                  create_tmp_dir
                  get_unused_port
                  get_any_testcmd_string
                  get_plsense_testcmd_string
                  get_plsense_testcmd_result
                  run_plsense_testcmd
                  is_server_running
                  is_server_stopping
                  wait_fin_task
                  wait_fin_timeout
                  wait_ready
                  get_proc_memory_quantity
                  get_current_project
                  get_current_file
                  used_modules );
{
    sub get_tmp_dir {
        my $ret = $ENV{TMP} || $ENV{TMPDIR} || "/tmp";
        if ( ! -d $ret ) {
            print STDERR "Can't get tmp path";
            return;
        }
        return $ret."/.plsense";
    }

    sub get_work_dir {
        my $ret = $ENV{TMP} || $ENV{TMPDIR} || "/tmp";
        if ( ! -d $ret ) {
            print STDERR "Can't get work path";
            return;
        }
        return $ret."/.plsense.work";
    }

    sub create_tmp_dir {
        my $ret = get_tmp_dir();
        if ( -d $ret ) {
            if ( ! rmtree($ret) ) {
                print STDERR "Can't remove already exist tmp directory";
                return;
            }
        }
        if ( ! mkdir $ret ) {
            print STDERR "Can't create tmp directory";
            return;
        }
        return $ret;
    }

    sub get_unused_port {
        my $s1 = IO::Socket::INET->new(LocalAddr => "localhost",
                                       LocalPort => 0,
                                       Proto => "tcp",
                                       Listen => 1,
                                       ReUse => 1,
                                       );
        if ( ! $s1 ) {
            print STDERR "Can't create socket : $!";
            return;
        }
        if ( ! $s1->listen ) {
            print STDERR "Can't listening port : $!";
            return;
        }

        my $s2 = IO::Socket::INET->new(LocalAddr => "localhost",
                                       LocalPort => 0,
                                       Proto => "tcp",
                                       Listen => 1,
                                       ReUse => 1,
                                       );
        if ( ! $s2 ) {
            print STDERR "Can't create socket : $!";
            return;
        }
        if ( ! $s2->listen ) {
            print STDERR "Can't listening port : $!";
            return;
        }

        my $s3 = IO::Socket::INET->new(LocalAddr => "localhost",
                                       LocalPort => 0,
                                       Proto => "tcp",
                                       Listen => 1,
                                       ReUse => 1,
                                       );
        if ( ! $s3 ) {
            print STDERR "Can't create socket : $!";
            return;
        }
        if ( ! $s3->listen ) {
            print STDERR "Can't listening port : $!";
            return;
        }

        my @ret = ($s1->sockport, $s2->sockport, $s3->sockport);

        $s1->close;
        $s2->close;
        $s3->close;
        return @ret;
    }

    sub get_any_testcmd_string {
        my $cmdstr = shift || "";
        my $workpath = get_work_dir();
        my $addpath = "PATH=$FindBin::Bin/../blib/script:$FindBin::Bin/../bin:\${PATH} ; export PATH";
        my $chhome = "HOME=$workpath ; export HOME";
        return "$addpath ; $chhome ; $cmdstr";
    }

    sub get_plsense_testcmd_string {
        my $cmdstr = shift || "";
        return get_any_testcmd_string("plsense $cmdstr");
    }

    sub get_plsense_testcmd_result {
        my $cmdstr = shift || "";
        $cmdstr = get_plsense_testcmd_string($cmdstr);
        return qx{ $cmdstr };
    }

    sub run_plsense_testcmd {
        my $cmdstr = shift || "";
        system get_plsense_testcmd_string($cmdstr);
    }

    sub is_server_running {
        my $stat = get_plsense_testcmd_result("svstat");
        my $mainstat = $stat =~ m{ ^ Main \s+ Server \s+ is \s+ Running\. $ }xms;
        my $workstat = $stat =~ m{ ^ Work \s+ Server \s+ is \s+ Running\. $ }xms;
        my $resolvestat = $stat =~ m{ ^ Resolve \s+ Server \s+ is \s+ Running\. $ }xms;
        return $mainstat && $workstat && $resolvestat ? 1 : 0;
    }

    sub is_server_stopping {
        my $stat = get_plsense_testcmd_result("svstat");
        my $mainstat = $stat =~ m{ ^ Main \s+ Server \s+ is \s+ Not \s+ running\. $ }xms;
        my $workstat = $stat =~ m{ ^ Work \s+ Server \s+ is \s+ Not \s+ running\. $ }xms;
        my $resolvestat = $stat =~ m{ ^ Resolve \s+ Server \s+ is \s+ Not \s+ running\. $ }xms;
        return $mainstat && $workstat && $resolvestat ? 1 : 0;
    }

    sub wait_fin_task {
        my $chk_interval = shift || 5;
        my $chk_max = shift || 300;
        my $count = 0;
        my $pscmd = get_plsense_testcmd_string("ps");
        WAIT_IDLE:
        while ( $count < $chk_max ) {
            my $ps = qx{ $pscmd };
            $ps =~ s{ ^\s+ }{}xms;
            $ps =~ s{ \s+$ }{}xms;
            if ( ! $ps && is_server_running() ) { last WAIT_IDLE; }
            sleep $chk_interval;
            $count++;
        }
    }

    sub wait_fin_timeout {
        if ( $ENV{PLSENSE_NOT_WAIT_TIMEOUT} ) { return 1; }
        my $sysfile = "/proc/sys/net/ipv4/tcp_fin_timeout";
        if ( ! -f $sysfile ) { return 1; }
        my $value = qx{ cat $sysfile };
        chomp $value;
        my $waitsec = $value =~ m{ \A ([0-9]+) \z }xms ? $1 + 90 : undef;
        if ( ! defined $waitsec ) { return; }
        sleep $waitsec;
        return $waitsec;
    }

    sub wait_ready {
        my $mdl_or_file = shift or return;
        my $chk_interval = shift || 3;
        my $chk_max = shift || 100;
        WAIT_READY:
        for ( my $i = 0; $i <= $chk_max; $i++ ) {
            my $readyret = get_plsense_testcmd_result("ready '$mdl_or_file'");
            chomp $readyret;
            if ( $readyret eq "Yes" ) { last WAIT_READY; }
            sleep $chk_interval;
        }
    }

    sub get_proc_memory_quantity {
        my @keywords = @_;
        my $grepcmdstr = join(" | ", map { "grep $_" } @keywords);
        my $mem = qx{ ps alx | $grepcmdstr | grep -v grep | awk '{printf \$8}' };
        chomp $mem;
        return $mem =~ m{ \A \d+ \z }xms ? $mem : 0;
    }

    sub get_proc_id {
        my @keywords = @_;
        my $grepcmdstr = join(" | ", map { "grep $_" } @keywords);
        my $id = qx{ ps alx | $grepcmdstr | grep -v grep | awk '{printf \$3}' };
        chomp $id;
        return $id =~ m{ \A \d+ \z }xms ? $id : 0;
    }

    sub get_current_project {
        my $loc = get_plsense_testcmd_result("loc");
        return $loc =~ m{ ^ Project: \s+ ([^\n]*?) $ }xms ? $1 : "";
    }

    sub get_current_file {
        my $loc = get_plsense_testcmd_result("loc");
        return $loc =~ m{ ^ File: \s+ ([^\n]*?) $ }xms ? $1 : "";
    }

    sub used_modules {
        my $dir = shift || "";
        if ( $dir eq "sample" ) {
            return qw{ File::Spec File::Basename File::Copy FindBin Class::Std Exporter
                       List::Util List::MoreUtils List::AllUtils IO::File IO::Socket
                       MtdExport BlessParent BlessChild ClassStdParent ClassStdChild };
        }
        elsif ( $dir eq "sample2" ) {
            return qw{ File::Copy };
        }
        elsif ( $dir eq "sample3" ) {
            return qw{ File::Copy };
        }
        else {
            return ();
        }
    }
}

1;

__END__
