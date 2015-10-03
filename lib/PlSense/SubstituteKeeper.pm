package PlSense::SubstituteKeeper;

use parent qw{ PlSense::Cacheable };
use strict;
use warnings;
use Class::Std;
use List::AllUtils qw{ any firstidx };
use Try::Tiny;
use PlSense::Logger;
use PlSense::Configure;
use PlSense::Util;
use PlSense::Entity::Scalar;
use PlSense::Entity::Array;
{
    my %cache_of :ATTR( :default(undef) );
    my %projcache_of :ATTR( :default(undef) );
    my %substh_of :ATTR();
    my %unknownargh_of :ATTR();
    my %max_entry_of :ATTR( :init_arg<max_entry> :default(50) );
    my %max_address_entry_of :ATTR( :init_arg<max_address_entry> :default(3) );
    my %current_local_is :ATTR();

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        $cache_of{$ident} = $class->new_cache('ISubst');
        $projcache_of{$ident} = $class->new_cache('Subst.'.$class->get_project());
        $substh_of{$ident} = {};
        $unknownargh_of{$ident} = {};
    }

    sub setup_without_reload {
        my $self = shift;
        $self->update_project();
        my $projnm = $self->get_project();
        my $local = get_config("local");
        $cache_of{ident $self}->set_namespace( $local ? "ISubst.$projnm" : "ISubst" );
        $projcache_of{ident $self}->set_namespace("Subst.$projnm");
        addrrouter->setup_without_reload();
        $current_local_is{ident $self} = $local;
    }

    sub setup {
        my $self = shift;
        my $force = shift || 0;

        my $projnm = get_config("name");
        if ( ! $force && $projnm eq $self->get_project() ) {
            logger->info("No need switch project data from [$projnm]");
            return;
        }

        logger->info("Switch project data to [$projnm]");
        my $local = get_config("local");
        $current_local_is{ident $self} || $local ? $self->reset
                                                 : $self->remove_project_all_sentinel(1);
        $self->setup_without_reload();
        if ( $local ) { $self->load_installed_all(1); }
        $self->load_project_all(1);
        return 1;
    }

    sub store {
        my $self = shift;
        my $mdlnm = shift || "";
        my $filepath = shift || "";
        my $projectnm = shift || "";
        addrrouter->store($mdlnm, $filepath, $projectnm);
        my $key = $self->get_cache_key($mdlnm, $filepath, $projectnm);
        if ( ! $projectnm ) {
            try   { $cache_of{ident $self}->set("[S]".$key, $substh_of{ident $self}); }
            catch { $cache_of{ident $self}->set("[S]".$key, $substh_of{ident $self}); };
            try   { $cache_of{ident $self}->set("[A]".$key, $unknownargh_of{ident $self}); }
            catch { $cache_of{ident $self}->set("[A]".$key, $unknownargh_of{ident $self}); };
        }
        elsif ( $projcache_of{ident $self} ) {
            try   { $projcache_of{ident $self}->set("[S]".$key, $substh_of{ident $self}); }
            catch { $projcache_of{ident $self}->set("[S]".$key, $substh_of{ident $self}); };
            try   { $projcache_of{ident $self}->set("[A]".$key, $unknownargh_of{ident $self}); }
            catch { $projcache_of{ident $self}->set("[A]".$key, $unknownargh_of{ident $self}); };
        }
        logger->info("Stored subst/arg info of $key");
    }

    sub load {
        my $self = shift;
        my $mdlnm = shift || "";
        my $filepath = shift || "";
        my $projectnm = shift || "";
        addrrouter->load($mdlnm, $filepath, $projectnm);
        my $key = $self->get_cache_key($mdlnm, $filepath, $projectnm);
        $self->load_by_substitute_key("[S]".$key, $projectnm);
        $self->load_by_unknown_argument_key("[A]".$key, $projectnm);
        logger->info("Loaded subst/arg info of $key");
    }

    sub load_all {
        my $self = shift;
        logger->info("Start Load all");
        $self->reset;
        $self->load_installed_all;
        $self->load_project_all;
        $self->resolve_unknown_argument;
    }

    sub remove {
        my $self = shift;
        my $mdlnm = shift || "";
        my $filepath = shift || "";
        my $projectnm = shift || "";
        addrrouter->remove($mdlnm, $filepath, $projectnm);
        my $key = $self->get_cache_key($mdlnm, $filepath, $projectnm);
        $self->remove_by_substitute_key("[S]".$key, $projectnm);
        $self->remove_by_unknown_argument_key("[A]".$key, $projectnm);
        logger->info("Removed subst/arg info of $key");
    }

    sub remove_project_all {
        my $self = shift;
        $self->remove_project_all_sentinel(0);
    }

    sub remove_all {
        my $self = shift;
        addrrouter->remove_all;
        $self->reset;
        try   { $cache_of{ident $self}->clear; }
        catch { $cache_of{ident $self}->clear; };
        if ( $projcache_of{ident $self} ) {
            try   { $projcache_of{ident $self}->clear; }
            catch { $projcache_of{ident $self}->clear; };
        }
        logger->info("Removed all subst/arg info");
    }

    sub reset {
        my $self = shift;
        addrrouter->reset;
        $substh_of{ident $self} = {};
        $unknownargh_of{ident $self} = {};
    }

    sub add_substitutes {
        my ($self, $lefts, @rights) = @_;
        SUBSTITUTE:
        for my $i ( 0..$#{$lefts} ) {

            if ( $#rights < 0 ) { last SUBSTITUTE; }
            my $addr = @{$lefts}[$i];
            my $type = substr($addr, 0, 1);

            if ( $i == $#{$lefts} && $#rights > 0 && ( $type eq '@' || $type eq '&' ) ) {

                # If the remained is multi-value to the last array address or the method return address,
                # Try merge the remained value.
                my $arr = PlSense::Entity::Array->new();
                my $element;
                my $scalar = "";
                VALUE:
                foreach my $value ( @rights ) {
                    if ( ! $value ) { next VALUE; }
                    my $etype = eval { $value->get_type } || "";
                    if ( $etype eq 'instance' ) {
                        $element = $value;
                        last VALUE;
                    }
                    elsif ( $etype eq 'scalar' ) {
                        if ( $scalar ne "" ) { $scalar .= " " }
                        $scalar .= $value->get_value;
                    }
                    elsif ( $etype eq 'array' ) {
                        ADDR:
                        for my $i ( 1..$value->count_address ) {
                            $arr->push_address( $value->get_address($i) );
                        }
                        my $e = $value->get_element or next VALUE;
                        if ( eval { $e->isa("PlSense::Entity::Instance") } ) {
                            $element = $e;
                            last VALUE;
                        }
                        elsif ( eval { $e->isa("PlSense::Entity::Scalar") } ) {
                            if ( $scalar ne "" ) { $scalar .= " " }
                            $scalar .= $e->get_value;
                        }
                    }
                    elsif ( $etype ne '' ) {
                        $element = $value;
                    }
                    else {
                        $arr->push_address($value);
                    }
                }
                if ( $element ) {
                    $arr->set_element($element);
                }
                elsif ( $scalar ne "" ) {
                    $arr->set_element( PlSense::Entity::Scalar->new({ value => $scalar }) );
                }
                $self->add_substitute($addr, $arr);
            }

            elsif ( $i == $#{$lefts} && $#rights > 0 && $type eq '%' ) {

                # If the remained is multi-value to the last hash address,
                # Try build hash value.
                my $hash = PlSense::Entity::Hash->new();
                my $onkey = 1;
                my $key = "";
                VALUE:
                foreach my $value ( @rights ) {
                    if ( $onkey && $value && eval { $value->isa("PlSense::Entity::Scalar") } ) {
                        $key = $value->get_value;
                    }
                    elsif ( ! $onkey && $key && $value ) {
                        $hash->set_membernm($key);
                        $hash->set_member($value);
                        $key = "";
                    }
                    $onkey = $onkey ? 0 : 1;
                }
                $self->add_substitute($addr, $hash);
            }

            else {

                my $right = shift @rights || "";
                if ( eval { $right->isa("PlSense::Entity") } ) {
                    $self->add_substitute($addr, $right);
                }
                elsif ( $right =~ s{ \[ ([0-9]+) \] \z }{}xms ) {
                    my $idx = $1;
                    $self->add_substitute_to_argument($addr, $right, $idx);
                }
                else {
                    $self->add_substitute($addr, $right);
                }

            }

        }
    }

    sub add_substitute {
        my ($self, $left, $right, $force) = @_;

        if ( $force ||
             eval { $right->isa("PlSense::Entity") } ||
             addrrouter->exist_route($right) ) {
            if ( ! addrrouter->add_route($left, $right) ) { return; }
            $self->move_to_route($left);
        }
        else {
            $self->add_substitute_sentinel($left, $right);
        }
    }

    sub add_unknown_argument {
        my ($self, $mtdaddr, $idx, $value) = @_;
        if ( ! $mtdaddr || ! $idx || ! $value ) { return; }

        my $idxh = $unknownargh_of{ident $self}->{$mtdaddr};
        if ( ! $idxh ) {
            $idxh = {};
            $unknownargh_of{ident $self}->{$mtdaddr} = $idxh;
        }

        my $values = $idxh->{$idx};
        if ( ! $values ) {
            $values = [];
            $idxh->{$idx} = $values;
        }

        my $vtype = eval { $value->get_type } || "";
        my $vtext = $vtype ? $value->to_string : $value;
        if ( ! $vtype ) {
            # If this value is address, check current values.
            my @addridxs;
            VALUE:
            for my $i ( 0..$#{$values} ) {
                my $currv = @{$values}[$i];
                if ( eval { $currv->isa("PlSense::Entity") } ) { next VALUE; }
                # If already exist this value, quit.
                if ( $currv eq $value ) { return; }
                push @addridxs, $i;
                # If count of address in values is max, remove first address.
                if ( $#addridxs + 1 >= $max_address_entry_of{ident $self} ) {
                    splice @{$values}, $addridxs[0], 1;
                    last VALUE;
                }
            }
        }

        # If count of values is max, remove first entity or first anything.
        if ( $#{$values} + 1 >= $max_entry_of{ident $self} ) {
            my $entityidx = firstidx { eval { $_->isa("PlSense::Entity") } } @{$values};
            if ( $entityidx >= 0 ) {
                splice @{$values}, $entityidx, 1;
            }
            else {
                shift @{$values};
            }
        }

        push @$values, $value;
        logger->debug("Add unknown argument of mtdaddr[$mtdaddr] idx[$idx] : $vtext");
    }

    sub add_substitute_to_argument {
        my ($self, $left, $right, $idx, $force) = @_;
        if ( ! $left || ! $right || ! $idx ) { return; }

        $self->add_substitute($left, $right."[".$idx."]", $force);

        if ( $right !~ m{ \A & (.+) :: ([^:]+) \z }xms ) { return; }
        my ($mdlkey, $mtdnm) = ($1, $2);
        my ($mdlnm, $filepath) = $mdlkey =~ m{ \A main \[ (.+) \] \z }xms ? ("main", $1)
                               :                                            ($mdlkey, "");
        my $mdl = mdlkeeper->get_module($mdlnm, $filepath) or return;
        if ( ! $mdl->exist_method($mtdnm) ) { return; }
        my $mtd = $mdl->get_method($mtdnm);

        my $mdlre = quotemeta($mdlkey);
        my $var;
        if ( $left =~ m{ \A ([\$@%]) & $mdlre :: $mtdnm :: ([^:]+) \z }xms ) {
            my $varnm = $1.$2;
            if ( ! $mtd->exist_variable($varnm) ) { return; }
            $var = $mtd->get_variable($varnm);
        }
        elsif ( $left =~ m{ \A ([\$@%]) $mdlre :: ([^:]+) \z }xms ) {
            my $varnm = $1.$2;
            if ( ! $mdl->exist_member($varnm) ) { return; }
            $var = $mdl->get_member($varnm);
        }
        if ( ! $var ) { return; }

        $mtd->set_argument($idx, $var);
    }

    sub remove_already_routing {
        my ($self) = @_;
        my @addrs = keys %{$substh_of{ident $self}};
        logger->info("Start remove already resolved substitute : count[".($#addrs + 1)."]");
        SUBST:
        foreach my $right ( @addrs ) {
            if ( ! addrrouter->exist_route($right) ) { next SUBST; }
            delete $substh_of{ident $self}->{$right};
        }
        @addrs = keys %{$unknownargh_of{ident $self}};
        my %resolved_of;
        logger->info("Start remove already resolved unknown argument : count[".($#addrs + 1)."]");
        ARG:
        foreach my $mtdaddr ( @addrs ) {
            if ( $mtdaddr !~ m{ ^(.+)\.W:([^.]+)$ }xms ) { next ARG; }
            my ($findaddr, $mtdnm) = ($1, $2);
            my $resolve = $resolved_of{$findaddr};
            if ( ! $resolve ) {
                $resolve = addrrouter->resolve_address($findaddr) or next ARG;
                $resolved_of{$findaddr} = $resolve;
            }
            if ( ! $resolve->isa("PlSense::Entity::Instance") ) { next ARG; }
            my $mdl = mdlkeeper->get_module( $resolve->get_modulenm ) or next ARG;
            my $mtd = $mdl->get_any_method($mtdnm) or next ARG;
            delete $unknownargh_of{ident $self}->{$mtdaddr};
        }
    }

    sub resolve_substitute {
        my ($self) = @_;
        my @addrs = keys %{$substh_of{ident $self}};
        logger->info("Start resolve substitute : count[".($#addrs + 1)."]");
        SUBST:
        foreach my $right ( @addrs ) {
            my $substs = $substh_of{ident $self}->{$right} or next SUBST;
            if ( ! addrrouter->exist_route($right) ) { next SUBST; }
            SUBST:
            foreach my $left ( @{$substs} ) {
                if ( ! addrrouter->add_route($left, $right) ) { next SUBST; }
                $self->move_to_route($left);
            }
            delete $substh_of{ident $self}->{$right};
        }
    }

    sub resolve_unknown_argument {
        my ($self) = @_;
        my @addrs = keys %{$unknownargh_of{ident $self}};
        my %resolved_of;
        logger->info("Start resolve unknown argument : count[".($#addrs + 1)."]");
        ARG:
        foreach my $mtdaddr ( @addrs ) {
            if ( $mtdaddr !~ m{ \A (.+)\.W:([^.]+?) \z }xms ) { next ARG; }
            my ($findaddr, $mtdnm) = ($1, $2);
            if ( ! exists $resolved_of{$findaddr} ) {
                $resolved_of{$findaddr} = undef;
                if ( addrrouter->exist_route($findaddr) ) {
                    $resolved_of{$findaddr} = addrrouter->resolve_address($findaddr);
                }
            }
            my $resolve = $resolved_of{$findaddr};
            if ( ! $resolve || ! $resolve->isa("PlSense::Entity::Instance") ) { next ARG; }
            my $mdl = mdlkeeper->get_module( $resolve->get_modulenm ) or next ARG;
            my $mtd = $mdl->get_any_method($mtdnm) or next ARG;
            logger->debug("Resolved unknown argument : $mtdaddr -> ".$mtd->get_fullnm);
            my $idxh = $unknownargh_of{ident $self}->{$mtdaddr};
            INDEX:
            foreach my $idx ( keys %$idxh ) {
                my $curraddr = $mtd->get_fullnm."[".$idx."]";
                VALUE:
                foreach my $value ( @{$idxh->{$idx}} ) {
                    $self->add_substitute($curraddr, $value);

                    # Add reverse route if value is a argument to super method
                    if ( eval { $value->isa("PlSense::Entity") } ) { next VALUE; }
                    if ( $mtdnm !~ m{ \A SUPER:: }xms ) { next VALUE; }
                    addrrouter->add_reverse_route($value, $curraddr);
                }
            }
            delete $unknownargh_of{ident $self}->{$mtdaddr};
        }
    }

    sub to_string_by_regexp {
        my ($self, $regexp) = @_;
        my $ret = "";
        SUBST:
        foreach my $right ( keys %{$substh_of{ident $self}} ) {
            if ( $right !~ m{ $regexp }xms ) { next SUBST; }
            my $substs = $substh_of{ident $self}->{$right} or next SUBST;
            SUBST:
            foreach my $left ( @{$substs} ) {
                $ret .= "$left -> $right\n";
            }
        }
        return $ret;
    }

    sub describe_keep_value {
        my ($self) = @_;
        my @substs = keys %{$substh_of{ident $self}};
        my $substkeys = 0;
        SUBST:
        foreach my $right ( @substs ) {
            my $substs = $substh_of{ident $self}->{$right} or next SUBST;
            $substkeys += $#{$substs} + 1;
        }
        my @unargs = keys %{$unknownargh_of{ident $self}};
        my $unargvalues = 0;
        ARG:
        foreach my $mtdaddr ( @unargs ) {
            my $idxh = $unknownargh_of{ident $self}->{$mtdaddr};
            INDEX:
            foreach my $idx ( keys %$idxh ) {
                my $values = $idxh->{$idx} or next INDEX;
                $unargvalues += $#{$values} + 1;
            }
        }

        my $ret = "Substitute ... Lefts:".$substkeys." Rights:".($#substs+1)."\n";
        $ret .= "Not Clear Argument ... Entrys:".($#unargs+1)." Values:".$unargvalues."\n";
        return $ret;
    }


    sub add_substitute_sentinel : PRIVATE {
        my ($self, $left, $right) = @_;
        if ( ! $left || ! $right ) { return; }

        my $substs = $substh_of{ident $self}->{$right};
        if ( ! $substs ) {
            $substs = [];
            $substh_of{ident $self}->{$right} = $substs;
        }
        if ( any { $_ eq $left } @{$substs} ) { return; }
        if ( $#{$substs} + 1 >= $max_entry_of{ident $self} ) { splice @{$substs}, $#{$substs} - 1, 1; }

        push @{$substs}, $left;
        logger->debug("Add substitute : $left -> $right");
    }

    sub move_to_route : PRIVATE {
        my ($self, $addr) = @_;

        logger->debug("Move to route : $addr");
        my %substs_of;
        ROUTABLE:
        foreach my $right ( grep { index($addr, $_) == 0 || index($_, $addr) == 0 } keys %{$substh_of{ident $self}} ) {
            $substs_of{$right} = $substh_of{ident $self}->{$right};
            delete $substh_of{ident $self}->{$right};
        }
        FOUND:
        foreach my $right ( keys %substs_of ) {
            my $substs = $substs_of{$right} or next FOUND;
            SUBST:
            foreach my $left ( @{$substs} ) {
                if ( ! addrrouter->add_route($left, $right) ) { next SUBST; }
                $self->move_to_route($left);
            }
        }
    }

    sub load_by_substitute_key : PRIVATE {
        my ($self, $key, $is_project) = @_;
        my $loadh;
        if ( ! $is_project ) {
            try   { $loadh = $cache_of{ident $self}->get($key); }
            catch { $loadh = $cache_of{ident $self}->get($key); };
        }
        elsif ( $projcache_of{ident $self} ) {
            try   { $loadh = $projcache_of{ident $self}->get($key); }
            catch { $loadh = $projcache_of{ident $self}->get($key); };
        }
        if ( ! $loadh ) { return; }
        RIGHTADDR:
        foreach my $rightaddr ( keys %$loadh ) {
            LEFTADDR:
            foreach my $leftaddr ( @{$loadh->{$rightaddr}} ) {
                $self->add_substitute_sentinel($leftaddr, $rightaddr);
            }
        }
    }

    sub load_by_unknown_argument_key : PRIVATE {
        my ($self, $key, $is_project) = @_;
        my $loadh;
        if ( ! $is_project ) {
            try   { $loadh = $cache_of{ident $self}->get($key); }
            catch { $loadh = $cache_of{ident $self}->get($key); };
        }
        elsif ( $projcache_of{ident $self} ) {
            try   { $loadh = $projcache_of{ident $self}->get($key); }
            catch { $loadh = $projcache_of{ident $self}->get($key); };
        }
        if ( ! $loadh ) { return; }
        MTDADDR:
        foreach my $mtdaddr ( keys %$loadh ) {
            IDX:
            foreach my $idx ( keys %{$loadh->{$mtdaddr}} ) {
                VALUE:
                foreach my $value ( @{$loadh->{$mtdaddr}->{$idx}} ) {
                    $self->add_unknown_argument($mtdaddr, $idx, $value);
                }
            }
        }
    }

    sub remove_by_substitute_key : PRIVATE {
        my ($self, $key, $is_project, $memoryonly) = @_;
        my $loadh;
        if ( ! $is_project ) {
            try   { $loadh = $cache_of{ident $self}->get($key); }
            catch { $loadh = $cache_of{ident $self}->get($key); };
        }
        elsif ( $projcache_of{ident $self} ) {
            try   { $loadh = $projcache_of{ident $self}->get($key); }
            catch { $loadh = $projcache_of{ident $self}->get($key); };
        }
        if ( ! $loadh ) { return; }
        RIGHTADDR:
        foreach my $rightaddr ( keys %$loadh ) {
            my $substs = $substh_of{ident $self}->{$rightaddr};
            if ( ! $substs ) { next RIGHTADDR; }
            LEFTADDR:
            foreach my $leftaddr ( @{$loadh->{$rightaddr}} ) {
                my $idx = firstidx { $_ eq $leftaddr } @{$substs};
                if ( $idx < 0 ) {
                    addrrouter->remove_route($leftaddr, $rightaddr);
                }
                else {
                    splice @{$substs}, $idx, 1;
                }
            }
            if ( $#{$substs} < 0 ) { delete $substh_of{ident $self}->{$rightaddr}; }
        }
        if ( $memoryonly ) { return; }
        if ( ! $is_project ) {
            try   { $cache_of{ident $self}->remove($key); }
            catch { $cache_of{ident $self}->remove($key); };
        }
        elsif ( $projcache_of{ident $self} ) {
            try   { $projcache_of{ident $self}->remove($key); }
            catch { $projcache_of{ident $self}->remove($key); };
        }
    }

    sub remove_by_unknown_argument_key : PRIVATE {
        my ($self, $key, $is_project, $memoryonly) = @_;
        my $loadh;
        if ( ! $is_project ) {
            try   { $loadh = $cache_of{ident $self}->get($key); }
            catch { $loadh = $cache_of{ident $self}->get($key); };
        }
        elsif ( $projcache_of{ident $self} ) {
            try   { $loadh = $projcache_of{ident $self}->get($key); }
            catch { $loadh = $projcache_of{ident $self}->get($key); };
        }
        if ( ! $loadh ) { return; }
        MTDADDR:
        foreach my $mtdaddr ( keys %$loadh ) {
            my $lidxh = $loadh->{$mtdaddr};
            my $idxh = $unknownargh_of{ident $self}->{$mtdaddr};
            if ( ! $idxh ) { next MTDADDR; }
            IDX:
            foreach my $idx ( keys %$lidxh ) {
                my $values = $idxh->{$idx} or next IDX;
                VALUE:
                foreach my $v ( @{$lidxh->{$idx}} ) {
                    my $fidx = eval { $v->get_type } ? firstidx { eval { $_->to_string eq $v->to_string } } @{$values}
                             :                         firstidx { ! eval { $_->get_type } && $_ eq $v } @{$values};
                    if ( $fidx < 0 ) { next VALUE; }
                    splice @{$values}, $fidx, 1;
                }
                if ( $#{$values} < 0 ) { delete $idxh->{$idx}; }
            }
            my @idxs = keys %$idxh;
            if ( $#idxs < 0 ) { delete $unknownargh_of{ident $self}->{$mtdaddr}; }
        }
        if ( $memoryonly ) { return; }
        if ( ! $is_project ) {
            try   { $cache_of{ident $self}->remove($key); }
            catch { $cache_of{ident $self}->remove($key); };
        }
        elsif ( $projcache_of{ident $self} ) {
            try   { $projcache_of{ident $self}->remove($key); }
            catch { $projcache_of{ident $self}->remove($key); };
        }
    }

    sub load_installed_all : PRIVATE {
        my $self = shift;
        my $not_resolve_subst = shift || 0;
        my @keys;
        try   { @keys = $cache_of{ident $self}->get_keys; }
        catch { @keys = $cache_of{ident $self}->get_keys; };
        KEY:
        foreach my $key ( @keys ) {
            my $ch = substr($key, 1, 1);
            if ( $ch eq 'S' ) {
                addrrouter->load_by_cache_key(substr($key, 3));
                $self->load_by_substitute_key($key, 0);
            }
            elsif ( $ch eq 'A' ) {
                $self->load_by_unknown_argument_key($key, 0);
            }
        }
        logger->info("Loaded subst/arg info of installed module all");
        if ( ! $not_resolve_subst ) { $self->resolve_substitute; }
    }

    sub load_project_all : PRIVATE {
        my $self = shift;
        my $not_resolve_subst = shift || 0;
        if ( $self->get_project eq get_default_config("name") ) { return; }
        my @keys;
        try   { @keys = $projcache_of{ident $self}->get_keys; }
        catch { @keys = $projcache_of{ident $self}->get_keys; };
        KEY:
        foreach my $key ( @keys ) {
            my $ch = substr($key, 1, 1);
            if ( $ch eq 'S' ) {
                addrrouter->load_by_cache_key(substr($key, 3));
                $self->load_by_substitute_key($key, 1);
            }
            elsif ( $ch eq 'A' ) {
                $self->load_by_unknown_argument_key($key, 1);
            }
        }
        logger->info("Loaded subst/arg info of project module all");
        if ( ! $not_resolve_subst ) { $self->resolve_substitute; }
    }

    sub remove_project_all_sentinel : PRIVATE {
        my $self = shift;
        my $memoryonly = shift || 0;
        my @keys;
        try   { @keys = $projcache_of{ident $self}->get_keys; }
        catch { @keys = $projcache_of{ident $self}->get_keys; };
        KEY:
        foreach my $key ( @keys ) {
            my $ch = substr($key, 1, 1);
            if ( $ch eq 'S' ) {
                $memoryonly ? addrrouter->remove_by_cache_key_on_memory(substr($key, 3))
                            : addrrouter->remove_by_cache_key(substr($key, 3));
                $self->remove_by_substitute_key($key, 1, $memoryonly);
            }
            elsif ( $ch eq 'A' ) {
                $self->remove_by_unknown_argument_key($key, 1, $memoryonly);
            }
        }
        logger->info("Removed subst/arg info of project module all : memoryonly[$memoryonly]");
    }

}

1;

__END__
