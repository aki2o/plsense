package PlSense::Configure;

use strict;
use warnings;
use Config::Tiny;
use File::Basename;
use File::Spec;
use PlSense::Logger;
use Exporter 'import';
our @EXPORT = qw( setup_config get_config );
{
    my $global_config_path = File::Spec->rel2abs( $ENV{HOME}."/.plsense" );
    my @gkeys = qw( cachedir port1 port2 port3 maxtasks loglevel logfile );
    my @pkeys = qw( name lib-path );
    my %desc_of = ( cachedir => "cache directory path",
                    port1    => "port number for main server",
                    port2    => "port number for work server",
                    port3    => "port number for resolve server",
                    maxtasks => "limit count of task on server", );
    my %default_of = ( cachedir => File::Spec->rel2abs( $ENV{HOME}."/.plsense.d" ),
                       port1    => 33333,
                       port2    => 33334,
                       port3    => 33335,
                       maxtasks => 20, );
    my $gcnf;
    my $pcnf;
    my %pcnf_of = ();

    sub setup_config {
        my ($filepath, $reload) = @_;
        if ( ! $gcnf ) {
            $gcnf = {};
            $gcnf = load_config($global_config_path, @gkeys) or return;
        }
        $pcnf = {};
        my $pconfpath = get_config_path($filepath) or return 1;
        if ( exists $pcnf_of{$pconfpath} && ! $reload ) {
            $pcnf = $pcnf_of{$pconfpath};
            return 1;
        }
        $pcnf = load_config($pconfpath, @pkeys) or return;
        $pcnf->{confpath} = $pconfpath;
        if ( $pcnf->{"lib-path"} ) {
            $pcnf->{"lib-path"} = dirname($pconfpath)."/".$pcnf->{"lib-path"};
        }
        $pcnf_of{$pconfpath} = $pcnf;
        return 1;
    }

    sub get_config {
        my $confignm = shift || "";
        if ( ! $pcnf || ! $gcnf ) {
            logger->error("Not yet setup_config done");
            return;
        }
        if ( ! exists $pcnf->{$confignm} && ! exists $gcnf->{$confignm} ) {
            logger->error("Invalid config name : $confignm");
            return;
        }
        return $pcnf->{$confignm} || $gcnf->{$confignm};
    }

    sub exist_config {
        my ($filepath, $global) = @_;
        if ( $global ) {
            return -f $global_config_path ? 1 : 0;
        }
        else {
            return -f get_config_path($filepath) ? 1 : 0;
        }
    }

    sub load_config {
        my ($confpath, @keys) = @_;
        my $fh;
        if ( ! open $fh, '<:utf8', $confpath ) {
            logger->error("Failed open conffile[$confpath] : $!");
            return;
        }
        my $c = Config::Tiny->read_string( do { local $/; <$fh> } );
        if ( ! close $fh ) {
            logger->error("Failed close conffile[$confpath] : $!");
            return;
        }
        my $cnf = {};
        CONFIG:
        foreach my $confignm ( @keys ) {
            my $v = $c->{_}{$confignm} || "";
            $v =~ s{ ^ \s+ }{}xms;
            $v =~ s{ \s+ $ }{}xms;
            $cnf->{$confignm} = $v;
        }
        return $cnf;
    }

    sub get_config_path {
        my ($filepath) = @_;
        if ( ! -f $filepath ) { return; }
        my $dirpath = dirname($filepath);
        my $confpath;
        DIR:
        while ( -d $dirpath ) {
            my $curr = $dirpath."/.plsense";
            if ( -f $curr ) {
                $confpath = $curr;
                last DIR;
            }
            $dirpath =~ s{ / [^/]+ $ }{}xms or last DIR;
        }
        return $confpath;
    }
}

1;

__END__

