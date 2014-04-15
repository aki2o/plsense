package PlSense::Builtin;

use parent qw{ PlSense::Cacheable };
use strict;
use warnings;
use Class::Std;
use Try::Tiny;
use PlSense::Logger;
use PlSense::Configure;
use PlSense::Symbol::Method;
use PlSense::Symbol::Variable;
{
    my %cache_of :ATTR( :default(undef) );
    my %current_local_is :ATTR();

    my %variableh_of :ATTR( :default(undef) );
    sub set_variable : PRIVATE {
        my ($self, $variablenm, $variable) = @_;
        $variableh_of{ident $self}->{$variablenm} = $variable;
    }
    sub exist_variable {
        my $self = shift;
        my $variablenm = shift || "";
        return exists $variableh_of{ident $self}->{$variablenm};
    }
    sub get_variable {
        my $self = shift;
        my $variablenm = shift || "";
        if ( ! exists $variableh_of{ident $self}->{$variablenm} ) {
            logger->warn("Not exist builtin variable : $variablenm");
            return;
        }
        return $variableh_of{ident $self}->{$variablenm};
    }
    sub keys_variable {
        my ($self) = @_;
        return keys %{$variableh_of{ident $self}};
    }
    sub get_variables {
        my ($self) = @_;
        return values %{$variableh_of{ident $self}};
    }

    my %methodh_of :ATTR( :default(undef) );
    sub set_method : PRIVATE {
        my ($self, $methodnm, $method) = @_;
        my $methodh = $methodh_of{ident $self};
        $methodh->{$methodnm} = $method;
    }
    sub exist_method {
        my ($self, $methodnm) = @_;
        my $methodh = $methodh_of{ident $self};
        return exists $methodh->{$methodnm};
    }
    sub get_method {
        my ($self, $methodnm) = @_;
        my $methodh = $methodh_of{ident $self};
        if ( ! exists $methodh->{$methodnm} ) {
            logger->warn("Not exist builtin method : $methodnm");
            return;
        }
        return $methodh->{$methodnm};
    }
    sub keys_method {
        my ($self) = @_;
        return keys %{$methodh_of{ident $self}};
    }
    sub get_methods {
        my ($self) = @_;
        return values %{$methodh_of{ident $self}};
    }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        $cache_of{$ident} = $class->new_cache('Builtin');
        $class->reset;
    }

    sub setup_without_reload {
        my $self = shift;
        $self->update_project();
        my $projnm = $self->get_project();
        my $local = get_config("local");
        $cache_of{ident $self}->set_namespace( $local ? "Builtin.$projnm" : "Builtin" );
        $current_local_is{ident $self} = $local;
    }

    sub setup {
        my $self = shift;
        my $force = shift || 0;

        my $projnm = get_config("name");
        my $local = get_config("local");
        if ( ( ! $force && $projnm eq $self->get_project() ) ||
             ( ! $current_local_is{ident $self} && ! $local ) ) {
            logger->info("No need switch project data from [$projnm]");
            return;
        }

        logger->info("Switch project data to [$projnm]");
        $self->reset;
        $self->setup_without_reload();
        # Loading is entrusted to server process
        return 1;
    }

    sub build {
        my ($self, $force) = @_;
        if ( ! $force && $self->load ) { return; }
        $self->build_builtin_variables();
        $self->build_builtin_functions();
        my $c = { variable => $variableh_of{ident $self},
                  method   => $methodh_of{ident $self}, };
        try   { $cache_of{ident $self}->set("perl", $c); }
        catch { $cache_of{ident $self}->set("perl", $c); };
    }

    sub load {
        my ($self) = @_;
        logger->debug("Start load");
        my $c = {};
        try   { $c = $cache_of{ident $self}->get("perl"); }
        catch { $c = $cache_of{ident $self}->get("perl"); };
        if ( ! exists $c->{variable} || ! exists $c->{method} ) { return; }
        $variableh_of{ident $self} = $c->{variable};
        $methodh_of{ident $self} = $c->{method};
        return 1;
    }

    sub is_loaded {
        my ($self) = @_;
        my @vars = keys %{$variableh_of{ident $self}};
        my @mtds = keys %{$methodh_of{ident $self}};
        return $#vars > 0 && $#mtds > 0;
    }

    sub reset {
        my ($self) = @_;
        $variableh_of{ident $self} = {};
        $methodh_of{ident $self} = {};
    }

    sub remove {
        my ($self) = @_;
        $self->reset;
        try   { $cache_of{ident $self}->clear; }
        catch { $cache_of{ident $self}->clear; };
        logger->info("Removed all builtin info");
    }

    sub build_builtin_variables : PRIVATE {
        my $self = shift;
        logger->debug("Start build builtin variables");
        $variableh_of{ident $self} = {};
        my $perldoc = get_config("perldoc");
        my @perldocret = qx{ $perldoc -t perlvar };
        my $validline = 0;
        my $helptext = "";
        my $foundvar = 1;
        my $indentlvl = 0;
        my @foundvars = ();
        LINE:
        foreach my $line ( @perldocret ) {
            chomp $line;

            # Start region of builtin variables
            if ( $line =~ m{ ^ (\s+) \$ARG $ }xms ) {
                $validline = 1;
                $indentlvl = length $1;
                logger->debug("Found region start of build builtin variables");
            }
            # End region of builtin variables
            elsif ( $validline && $line =~ m{ ^ \s+ Error \s Indicators $ }xms ) {
                $validline = 0;
                logger->debug("Found region end of build builtin variables");
                if ( $#foundvars >= 0 ) {
                    $self->set_variable_helptext($helptext, @foundvars);
                    @foundvars = ();
                    $helptext = "";
                }
            }
            if ( ! $validline ) { next LINE; }

            # Defined variable
            if ( $line =~ m{ ^ \s{$indentlvl} ([\$@%][^\s]+) ( $ | \s{2,} ) }xms ) {
                my $varnm = $1;
                if ( ! $foundvar ) {
                    $self->set_variable_helptext($helptext, @foundvars);
                    @foundvars = ();
                    $helptext = "";
                }
                $foundvar = 1;
                push @foundvars, $varnm;
                $helptext .= substr($line, $indentlvl)."\n";
            }
            # Got help
            else {
                $helptext .= length($line) > $indentlvl ? substr($line, $indentlvl)."\n" : $line."\n";
                $foundvar = 0;
            }

        }
    }

    sub set_variable_helptext : PRIVATE {
        my ($self, $helptext, @targetvars) = @_;
        SET_HELPTEXT:
        foreach my $varnm ( @targetvars ) {
            if ( $self->exist_variable($varnm) ) { next SET_HELPTEXT; }
            my $var = PlSense::Symbol::Variable->new({ name => $varnm });
            $var->set_helptext("\n===== Part of PerlDoc =====\n".$helptext);
            $self->set_variable($varnm, $var);
            logger->debug("Got builtin variable : $varnm");
        }
    }

    sub build_builtin_functions : PRIVATE {
        my $self = shift;
        logger->debug("Start build builtin functions");
        $methodh_of{ident $self} = {};
        my $perldoc = get_config("perldoc");
        my @perldocret = qx{ $perldoc -t perlfunc };
        my $validline = 0;
        my $helptext = "";
        my $foundfunc = 1;
        my @foundfuncs = ();
        LINE:
        foreach my $line ( @perldocret ) {
            chomp $line;

            # Start region of builtin functions
            if ( $line =~ m{ ^ \s+ Alphabetical \s Listing \s of \s Perl \s Functions $ }xms ) {
                $validline = 1;
                logger->debug("Found region start of build builtin functions");
            }
            # End region of builtin functions
            elsif ( $validline && $line =~ m{ ^ \s+ Non-function \s Keywords \s by \s Cross-reference $ }xms ) {
                $validline = 0;
                logger->debug("Found region end of build builtin functions");
                if ( $#foundfuncs >= 0 ) {
                    $self->set_function_helptext($helptext, @foundfuncs);
                    @foundfuncs = ();
                    $helptext = "";
                }
            }
            if ( ! $validline ) { next LINE; }

            # Defined function
            if ( $line =~ m{ ^ \s{4} ([a-zA-Z0-9_\-]+) }xms ) {
                my $funcnm = $1;
                if ( ! $foundfunc ) {
                    $self->set_function_helptext($helptext, @foundfuncs);
                    @foundfuncs = ();
                    $helptext = "";
                }
                $foundfunc = 1;
                push @foundfuncs, $funcnm;
                $helptext .= substr($line, 4)."\n";
            }
            # Got help
            else {
                $helptext .= length($line) > 4 ? substr($line, 4)."\n" : $line."\n";
                $foundfunc = 0;
            }

        }
    }

    sub set_function_helptext : PRIVATE {
        my ($self, $helptext, @targetfuncs) = @_;
        SET_HELPTEXT:
        foreach my $funcnm ( @targetfuncs ) {
            if ( $self->exist_method($funcnm) ) { next SET_HELPTEXT; }
            my $func = PlSense::Symbol::Method->new({ name => $funcnm });
            $func->set_helptext("\n===== Part of PerlDoc =====\n".$helptext);
            $self->set_method($funcnm, $func);
            logger->debug("Got builtin function : $funcnm");
        }
    }
}

1;

__END__
