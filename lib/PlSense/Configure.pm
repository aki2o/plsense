package PlSense::Configure;

use strict;
use warnings;
use Config::Tiny;
use File::Basename;
use File::Spec;
use PlSense::Logger;
use Exporter 'import';
our @EXPORT = qw( setup_config
                  init_config
                  set_primary_config
                  get_config
                  get_default_config
                  exist_global_config
                  exist_project_config
                  create_global_config
                  create_project_config );
{
    my $global_config_path = File::Spec->rel2abs( $ENV{HOME}."/.plsense" );
    my @gkeys = qw( cachedir port1 port2 port3 maxtasks loglevel logfile perl perldoc clean-env );
    my @pkeys = qw( name lib-path perl perldoc clean-env local carton );
    my %desc_of = ( cachedir => "cache directory path",
                    port1    => "port number for main server",
                    port2    => "port number for work server",
                    port3    => "port number for resolve server",
                    maxtasks => "limit count of task on server", );
    my %default_of = ( cachedir    => File::Spec->rel2abs( $ENV{HOME}."/.plsense.d" ),
                       port1       => 33333,
                       port2       => 33334,
                       port3       => 33335,
                       maxtasks    => 20,
                       perl        => "perl",
                       perldoc     => "perldoc",
                       "clean-env" => 0,
                       name        => "default",
                       local       => 0,
                       carton      => 0, );
    my $gcnf;
    my $pcnf;
    my %pcnf_of = ();
    my %bkenv_of = ();
    my %primary_of = ();

    sub setup_config {
        my ($filepath, $reload, $interactive) = @_;
        if ( ! $gcnf || $reload ) {
            $gcnf = {};
            $gcnf->{$_} = $primary_of{$_} foreach grep { defined $primary_of{$_} } @gkeys;
            if ( ! exist_global_config() && $interactive ) {
                my $ret = read_string("Not exist config file [$global_config_path]\nMaking? (Y/n) ") || "";
                if ( ! $ret || lc($ret) eq 'y' || lc($ret) eq 'yes' ) {
                    create_global_config();
                }
                else {
                    print "Not create [$global_config_path]\n";
                }
            }
            if ( exist_global_config() ) {
                $gcnf = load_config($global_config_path, @gkeys) or return;
                $gcnf->{$_} = $primary_of{$_} foreach grep { defined $primary_of{$_} } @gkeys;
            }
        }
        $pcnf = {};
        $pcnf->{$_} = $primary_of{$_} foreach grep { defined $primary_of{$_} } @pkeys;
        if ( ! $filepath ) { return 1; }
        my $pconfpath = get_config_path($filepath) or return 1;
        if ( exists $pcnf_of{$pconfpath} && ! $reload ) {
            $pcnf = $pcnf_of{$pconfpath};
        }
        else {
            $pcnf = load_config($pconfpath, @pkeys) or return;
            $pcnf->{$_} = $primary_of{$_} foreach grep { defined $primary_of{$_} } @pkeys;
            $pcnf->{confpath} = $pconfpath;
            makeup_config();
            $pcnf_of{$pconfpath} = $pcnf;
        }
        fix_env();
        return 1;
    }

    sub init_config {
        $gcnf = undef;
        $pcnf = undef;
        %pcnf_of = ();
        %primary_of = ();
    }

    sub set_primary_config {
        my %conf = @_;
        CONFIG:
        foreach my $confignm ( keys %conf ) {
            if ( ! grep { $_ eq $confignm } ( @gkeys, @pkeys ) ) {
                logger->error("Invalid config name : $confignm");
                next CONFIG;
            }
            $primary_of{$confignm} = $conf{$confignm};
        }
    }

    sub get_config {
        my $confignm = shift || "";
        my $not_use_default = shift || 0;
        if ( ! $pcnf || ! $gcnf ) {
            logger->error("Not yet setup_config done");
            return;
        }
        if ( ! grep { $_ eq $confignm } ( @gkeys, @pkeys, "confpath" ) ) {
            logger->error("Invalid config name : $confignm");
            return;
        }
        return exists $pcnf->{$confignm}     ? $pcnf->{$confignm}
             : exists $gcnf->{$confignm}     ? $gcnf->{$confignm}
             : $not_use_default              ? undef
             : exists $default_of{$confignm} ? $default_of{$confignm}
             :                                 undef;
    }

    sub get_default_config {
        my $confignm = shift || "";
        if ( ! grep { $_ eq $confignm } ( @gkeys, @pkeys, "confpath" ) ) {
            logger->error("Invalid config name : $confignm");
            return;
        }
        return $default_of{$confignm} || "";
    }

    sub exist_global_config {
        return -f $global_config_path ? 1 : 0;
    }

    sub exist_project_config {
        my ($filepath) = @_;
        return -f get_config_path($filepath) ? 1 : 0;
    }

    sub create_global_config {
        return create_config($global_config_path, @gkeys);
    }

    sub create_project_config {
        my $rootdir = shift || "";
        if ( ! -d $rootdir ) {
            logger->error("Not exist directory : $rootdir");
            return;
        }
        return create_config($rootdir."/.plsense", @pkeys);
    }


    sub makeup_config {
        my $prootdir = dirname($pcnf->{confpath});
        my $perl = get_config("perl");
        my $perldoc = get_config("perldoc");
        # absolute lib-path
        my $libpath = get_config("lib-path", 1);
        if ( $libpath ) {
            $pcnf->{"lib-path"} = File::Spec->rel2abs($prootdir."/".$libpath);
        }
        # fix for Carton
        my $carton = get_config("carton", 1);
        if ( $carton ) {
            $pcnf->{local} = 1; # I'm not sure that Carton project is a local perl environment.
            if ( $perl eq get_default_config("perl") ) { $perl = "carton exec -- perl"; }
            if ( $perldoc eq get_default_config("perldoc") ) { $perldoc = "carton exec -- perldoc"; }
        }
        # Execute perl/perldoc after moving to the root of project
        $pcnf->{perl} = "cd '$prootdir' ; $perl";
        $pcnf->{perldoc} = "cd '$prootdir' ; $perldoc";
    }

    sub fix_env {
        if ( get_config("clean-env") ) {
            ENV:
            foreach my $envnm ( "PERL5LIB" ) {
                if ( ! exists $bkenv_of{$envnm} ) { $bkenv_of{$envnm} = $ENV{$envnm}; }
                $ENV{$envnm} = "";
            }
        }
        else {
            ENV:
            foreach my $envnm ( "PERL5LIB" ) {
                if ( exists $bkenv_of{$envnm} ) { $ENV{$envnm} = $bkenv_of{$envnm}; }
            }
        }
    }

    sub create_config {
        my ($confpath, @keys) = @_;
        my $old = -f $confpath ? load_config($confpath, @keys) : {};
        my $c = Config::Tiny->new;
        CONFIG:
        foreach my $confignm ( @keys ) {
            my $desc = $desc_of{$confignm};
            my $default = $default_of{$confignm};
            $c->{_}{$confignm} = $desc                    ? read_string("Input ${desc}: ($default) ") || $default
                               : exists $old->{$confignm} ? $old->{$confignm}
                               : defined $default         ? $default
                               :                            "";
        }
        my $fh;
        if ( ! open($fh, '>:utf8', $confpath) ) {
            logger->error("Failed open conffile[$confpath] : $!");
            return;
        }
        WRITE:
        for ( my $str = $c->write_string ) {
            print $fh $str or logger->error("Failed write [$str] to [$confpath] : $!");
        }
        if ( ! close $fh ) {
            logger->error("Failed close conffile[$confpath] : $!");
            return;
        }
        return 1;
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
            my $v = $c->{_}{$confignm};
            if ( ! defined $v || $v eq '' ) { next CONFIG; }
            $v =~ s{ ^ \s+ }{}xms;
            $v =~ s{ \s+ $ }{}xms;
            $cnf->{$confignm} = $v;
        }
        return $cnf;
    }

    sub get_config_path {
        my ($filepath) = @_;
        if ( ! -f $filepath ) { return; }
        my $dirpath = dirname(File::Spec->rel2abs($filepath));
        my $confpath;
        DIR:
        while ( -d $dirpath ) {
            my $curr = $dirpath."/.plsense";
            if ( -f $curr && $curr ne $global_config_path ) {
                $confpath = $curr;
                last DIR;
            }
            $dirpath =~ s{ / [^/]+ $ }{}xms or last DIR;
        }
        return $confpath;
    }

    sub read_string {
        my $prompt = shift || "";
        print $prompt;
        my $ret = <STDIN>;
        $ret =~ s{ ^\s+ }{}xms;
        $ret =~ s{ \s+$ }{}xms;
        return $ret;
    }
}

1;

__END__

