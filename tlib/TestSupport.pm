#!/usr/bin/perl

package TestSupport;

use strict;
use warnings;
use Exporter 'import';
use File::Path;
use IO::Socket;
our @EXPORT = qw( get_tmp_dir get_work_dir create_tmp_dir get_unused_port );
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
}

1;

__END__
