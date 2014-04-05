package PlSense::AddressRouter;

use parent qw{ PlSense::Cacheable };
use strict;
use warnings;
use Class::Std;
use List::AllUtils qw{ firstidx lastidx };
use Try::Tiny;
use PlSense::Logger;
use PlSense::Configure;
use PlSense::Util;
{
    my %cache_of :ATTR( :default(undef) );
    my %routeh_of :ATTR();
    my %rrouteh_of :ATTR();
    my %max_resolve_entry_of :ATTR( :init_arg<max_resolve_entry> :default(5) );
    my %max_address_entry_of :ATTR( :init_arg<max_address_entry> :default(2) );
    my %max_reverse_address_entry_of :ATTR( :init_arg<max_reverse_address_entry> :default(10) );
    my %max_try_routing_of :ATTR( :init_arg<max_try_routing> :default(50) );
    my %commonkeyh_of :ATTR();

    my %with_build_is :ATTR( :init_arg<with_build> );
    sub with_build { my ($self) = @_; return $with_build_is{ident $self} ? 1 : 0; }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        $cache_of{$ident} = $class->new_cache('Resolve');
        $class->reset;
    }

    sub setup_without_reload {
        my $self = shift;
        $self->update_project();
        my $projnm = $self->get_project();
        $cache_of{ident $self}->set_namespace( get_config("local") ? "Resolve.$projnm" : "Resolve" );
    }

    sub setup {
        my $self = shift;
        my $force = shift || 0;

        my $projnm = get_config("name");
        if ( ! $force && $projnm eq $self->get_project() ) {
            logger->info("No need switch project data from [$projnm]");
            return;
        }

        $self->setup_without_reload();
        $self->load_current_project();
        logger->info("Switched project routing to $projnm");
        return 1;
    }

    sub store_current_project {
        my $self = shift;
        my $key = "perl.".$self->get_project;
        try   { $cache_of{ident $self}->set($key, { route => $routeh_of{ident $self}, rroute => $rrouteh_of{ident $self} }); }
        catch { $cache_of{ident $self}->set($key, { route => $routeh_of{ident $self}, rroute => $rrouteh_of{ident $self} }); };
        logger->info("Stored project routing of $key");
    }

    sub load_current_project {
        my $self = shift;
        my $key = "perl.".$self->get_project();
        my $cacheh;
        try   { $cacheh = $cache_of{ident $self}->get($key); }
        catch { $cacheh = $cache_of{ident $self}->get($key); };
        $routeh_of{ident $self} = $cacheh && $cacheh->{"route"} ? $cacheh->{"route"} : {};
        $rrouteh_of{ident $self} = $cacheh && $cacheh->{"rroute"} ? $cacheh->{"rroute"} : {};
        $self->init_common_key_hash;
        logger->info("Loaded project routing of $key");
    }

    sub store {
        my $self = shift;
        my $mdlnm = shift || "";
        my $filepath = shift || "";
        my $projectnm = shift || "";
        my $key = $self->get_cache_key($mdlnm, $filepath, $projectnm);
        try   { $cache_of{ident $self}->set($key, $routeh_of{ident $self}); }
        catch { $cache_of{ident $self}->set($key, $routeh_of{ident $self}); };
        logger->info("Stored routing of $key");
    }

    sub load {
        my $self = shift;
        my $mdlnm = shift || "";
        my $filepath = shift || "";
        my $projectnm = shift || "";
        $self->load_by_cache_key( $self->get_cache_key($mdlnm, $filepath, $projectnm) );
    }

    sub load_by_cache_key {
        my $self = shift;
        my $key = shift || "";
        my $loadh;
        try   { $loadh = $cache_of{ident $self}->get($key); }
        catch { $loadh = $cache_of{ident $self}->get($key); };
        if ( ! $loadh ) { return; }
        ADDR:
        foreach my $addr ( keys %$loadh ) {
            my $resolves = $loadh->{$addr} or next ADDR;
            RESOLVE:
            foreach my $resolve ( @$resolves ) {
                $self->add_route($addr, $resolve);
            }
        }
        logger->info("Loaded routing of $key");
    }

    sub remove {
        my $self = shift;
        my $mdlnm = shift || "";
        my $filepath = shift || "";
        my $projectnm = shift || "";
        $self->remove_by_cache_key( $self->get_cache_key($mdlnm, $filepath, $projectnm) );
    }

    sub remove_by_cache_key {
        my $self = shift;
        my $key = shift || "";
        $self->remove_by_cache_key_on_memory($key);
        try   { $cache_of{ident $self}->remove($key); }
        catch { $cache_of{ident $self}->remove($key); };
        logger->info("Removed routing of $key");
    }

    sub remove_by_cache_key_on_memory {
        my $self = shift;
        my $key = shift || "";
        my $loadh;
        try   { $loadh = $cache_of{ident $self}->get($key); }
        catch { $loadh = $cache_of{ident $self}->get($key); };
        if ( ! $loadh ) { return; }
        ADDR:
        foreach my $addr ( keys %$loadh ) {
            my $resolves = $loadh->{$addr} or next ADDR;
            RESOLVE:
            foreach my $resolve ( @$resolves ) {
                $self->remove_route($addr, $resolve);
            }
        }
        logger->info("Removed routing on memory of $key");
    }

    sub remove_all {
        my $self = shift;
        $self->reset;
        try   { $cache_of{ident $self}->clear; }
        catch { $cache_of{ident $self}->clear; };
        logger->info("Removed all routing");
    }

    sub reset {
        my $self = shift;
        $routeh_of{ident $self} = {};
        $rrouteh_of{ident $self} = {};
        $self->init_common_key_hash;
    }

    sub add_route {
        my ($self, $addr, $value) = @_;
        if ( ! $addr || ! $value ) { return; }

        my $ret;
        my $resolves = $routeh_of{ident $self}->{$addr};
        if ( ! $resolves ) {
            $resolves = [];
            $routeh_of{ident $self}->{$addr} = $resolves;
            $ret = 1;
        }

        my $vtype = eval { $value->get_type } || "";
        my $vtext = $vtype ? $value->to_string : $value;
        if ( ! $vtype ) {
            # If this value is address, check current resolves.
            my @addridxs;
            RESOLVE:
            for my $i ( 0..$#{$resolves} ) {
                my $resolve = @{$resolves}[$i];
                if ( eval { $resolve->isa("PlSense::Entity") } ) { next RESOLVE; }
                # If already exist this value, remove it for moving to last.
                if ( $resolve eq $value ) {
                    splice @{$resolves}, $i, 1;
                    last RESOLVE;
                }
                push @addridxs, $i;
                # If count of address in resolves is max, remove a before last address.
                if ( $#addridxs + 1 >= $max_address_entry_of{ident $self} ) {
                    my $ridx = $#addridxs > 1 ? $#addridxs - 1 : 0;
                    splice @{$resolves}, $addridxs[$ridx], 1;
                    last RESOLVE;
                }
            }
        }

        # If count of resolves is max, remove last entity or last anything.
        if ( $#{$resolves} + 1 >= $max_resolve_entry_of{ident $self} ) {
            my $entityidx = lastidx { eval { $_->isa("PlSense::Entity") } } @{$resolves};
            if ( $entityidx >= 0 ) {
                splice @{$resolves}, $entityidx, 1;
            }
            else {
                pop @{$resolves};
            }
        }

        push @{$resolves}, $value;
        logger->debug("Add routing : $addr -> $vtext");
        if ( ! $vtype ) { $self->add_reverse_route($value, $addr); }
        my $commonkey = $self->get_address_common_part($addr);
        if ( $commonkey ) { $commonkeyh_of{ident $self}->{$commonkey} = 1; }
        return $ret;
    }

    sub remove_route {
        my ($self, $addr, $value) = @_;
        if ( ! $addr ) { return; }
        if ( ! $value ) {
            # delete $routeh_of{ident $self}->{$addr};
            # my $commonkey = $self->get_address_common_part($addr);
            # if ( $commonkey ) { delete $commonkeyh_of{ident $self}->{$commonkey}; }
            return;
        }
        my $resolves = $routeh_of{ident $self}->{$addr} or return;
        my $vtype = eval { $value->get_type } || "";
        my $vstr = $vtype ? $value->to_string : "";
        my $idx = $vtype ? firstidx { eval { $_->to_string eq $vstr } } @{$resolves}
                :          firstidx { ! eval { $_->get_type } && $_ eq $value } @{$resolves};
        if ( $idx < 0 ) { return; }
        splice @{$resolves}, $idx, 1;
        if ( $#{$resolves} < 0 ) { delete $routeh_of{ident $self}->{$addr}; }
        if ( ! $vtype ) { $self->remove_reverse_route($value, $addr); }
        my $vtext = $vtype ? $value->to_string : $value;
        logger->debug("Removed routing : $addr -> $vtext");
    }

    sub exist_route {
        my ($self, $addr) = @_;
        if ( ! $addr ) { return; }
        return exists $routeh_of{ident $self}->{$addr} ||
               exists $commonkeyh_of{ident $self}->{ $self->get_address_common_part($addr) };
    }

    sub get_route {
        my ($self, $addr) = @_;
        if ( ! $addr ) { return (); }
        my $ret = $routeh_of{ident $self}->{$addr} || [];
        return @{$ret};
    }

    sub resolve_address {
        my ($self, $addr) = @_;
        logger->debug("Start resolve address : $addr");
        my @resolves = $self->resolve_address_1($addr, 0);
        if ( $#resolves < 0 ) { return; }
        @resolves = map { eval { $_->clone } } @resolves;
        my $ret;
        MERGE:
        foreach my $value ( @resolves ) {
            $ret = $self->update_value($ret, $value);
        }
        my $rettext = $ret ? $ret->to_string : "";
        logger->debug("Resolved address : $rettext");
        return $ret;
    }

    sub resolve_anything {
        my ($self, $addr) = @_;
        logger->debug("Start resolve anything : $addr");
        my (@ret, %found_is);
        RESOLVED:
        foreach my $resolve ( $self->resolve_address_1($addr, 1) ) {
            if ( eval { $resolve->isa("PlSense::Entity") } ) {
                push @ret, $resolve;
            }
            elsif ( $resolve && ! $found_is{$resolve} ) {
                $found_is{$resolve} = 1;
                push @ret, $resolve;
            }
        }
        return @ret;
    }

    sub get_route_list {
        my ($self) = @_;
        return keys %{$routeh_of{ident $self}};
    }

    sub get_matched_route_list {
        my ($self, $regexp) = @_;
        return grep { $_ =~ m{ $regexp }xms } keys %{$routeh_of{ident $self}};
    }

    sub to_string_by_regexp {
        my ($self, $regexp) = @_;
        my $ret = "";
        MATCH:
        foreach my $addr ( $self->get_matched_route_list($regexp) ) {
            my $values = $routeh_of{ident $self}->{$addr};
            VALUE:
            foreach my $value ( @{$values} ) {
                my $valuetext = eval { $value->isa("PlSense::Entity") } ? $value->to_string : $value;
                $ret .= "$addr -> $valuetext\n";
            }
        }
        return $ret;
    }

    sub describe_keep_value {
        my ($self) = @_;
        my @routes = $self->get_route_list;
        my $valuecount = 0;
        ROUTE:
        foreach my $addr ( @routes ) {
            my $values = $routeh_of{ident $self}->{$addr} or next ROUTE;
            $valuecount += $#{$values} + 1;
        }
        return "Route ... Entrys:".($#routes+1)." Resolves:".$valuecount."\n";
    }


    sub get_address_common_part : PRIVATE {
        my ($self, $addr) = @_;
        if ( $addr =~ m{ \A [\$@%]? &? main\[ .+? \] :: [^.]+ }xms  ) { return $&; }
        elsif ( $addr =~ m{ \A ([^.]+) }xms  ) { return $&; }
        logger->warn("Failed get address common part from $addr");
        return "";
    }

    sub init_common_key_hash : PRIVATE {
        my ($self) = @_;
        $commonkeyh_of{ident $self} = {};
        if ( ! $self->with_build ) { return; }
        ADDR:
        foreach my $addr ( keys %{$routeh_of{ident $self}} ) {
            my $commonkey = $self->get_address_common_part($addr) or next ADDR;
            $commonkeyh_of{ident $self}->{$commonkey} = 1;
        }
    }

    my %chkaddress_is :ATTR();
    my %trycount_of :ATTR();
    sub resolve_address_1 : PRIVATE {
        my ($self, $addr, $allow_addr) = @_;
        my (@ret, @othermdls, $followaddr);
        my $trycount = 0;
        my $curraddr = $addr;
        ADDR:
        while ( $curraddr && $trycount < 3 ) {

            logger->debug("Start try resolve by $curraddr");
            $trycount_of{ident $self} = 0;
            $chkaddress_is{ident $self} = {};
            @ret = $self->resolve_address_sentinel($curraddr, $allow_addr, 1);
            if ( $#ret >= 0 ) { last ADDR; }

            if ( ! defined $followaddr ) {
                logger->debug("Start try get other address from [$addr]");
                my $mtdaddr = $addr =~ s{ \A & ( main \[ .+? \] :: [^.]+ ) }{}xms ? $1
                            : $addr =~ s{ \A & ( [a-zA-Z0-9_:]+ ) }{}xms          ? $1
                            :                                                       "" or last ADDR;
                $followaddr = $addr || "";
                if ( $mtdaddr !~ s{ :: ([^:]+) \z }{}xms ) { last ADDR; }
                my $mtdnm = $1;
                $followaddr = $mtdnm.$followaddr;
                my ($mdlnm, $filepath) = $mtdaddr =~ m{ \A main \[ (.+) \] \z }xms ? ("main", $1)
                                       :                                             ($mtdaddr, "");
                my $mdl = mdlkeeper->get_module($mdlnm, $filepath) or last ADDR;
                my $mtd = $mdl->get_any_method($mtdnm) or last ADDR;
                if ( $mtd->is_importive ) {
                    logger->debug("Try get original method of [$mtdnm] in [".$mdl->get_name."]");
                    USINGMDL:
                    for my $i ( 1..$mdl->count_usingmdl ) {
                        my $extmdl = $mdl->get_usingmdl($i);
                        if ( ! $extmdl->exist_method($mtdnm) ) { next USINGMDL; }
                        my $extmtd = $extmdl->get_method($mtdnm);
                        if ( $extmtd->is_importive ) { next USINGMDL; }
                        push @othermdls, $extmdl->get_name;
                        last USINGMDL;
                    }
                }
                else {
                    logger->debug("Try get all parents of [".$mdl->get_name."]");
                    @othermdls = $mdl->get_all_parents(1);
                }
            }
            if ( $#othermdls < 0 ) { last ADDR; }

            my $nextmdlnm = shift @othermdls;
            $curraddr = "&".$nextmdlnm."::".$followaddr;
            $trycount++;

        }
        return @ret;
    }

    sub is_valid_address_to_resolve : PRIVATE {
        my ($self, $addr) = @_;
        # Allow try to resolve some time for the case that call same method having different follow address.
        # For example, method for clone.
        my $trycount = $chkaddress_is{ident $self}->{$addr} || 0;
        if ( $trycount >= 3 ) { return 0; }
        $chkaddress_is{ident $self}->{$addr} = $trycount + 1;
        return 1;
    }

    sub is_found_address_while_resolve : PRIVATE {
        my ($self, $addr) = @_;
        if ( $chkaddress_is{ident $self}->{$addr} ) { return 1; }
        $chkaddress_is{ident $self}->{$addr} = 1;
        return 0;
    }

    sub resolve_address_sentinel : PRIVATE {
        my ($self, $addr, $allow_addr, $not_resolve_reverse) = @_;

        if ( ! $self->is_valid_address_to_resolve($addr) ) { return (); }
        if ( $trycount_of{ident $self} >= $max_try_routing_of{ident $self} ) {
            logger->debug("Exceed max try routing for resolve address");
            return ();
        }
        $trycount_of{ident $self}++;

        my (@ret, @follows);
        my $curraddr = $addr;

        if ( ! $not_resolve_reverse ) {
            push @ret, $self->resolve_reverse_address($addr, $allow_addr);
        }

        FIND:
        while ( $curraddr && ! exists $routeh_of{ident $self}->{$curraddr} ) {
            if ( $curraddr !~ s{ \. ([^.]+) \z }{}xms ) { last FIND; }
            unshift @follows, $1;
        }
        my $resolves = $curraddr ? $routeh_of{ident $self}->{$curraddr} : [];
        if ( ! $resolves ) { $resolves = []; }

        my $fstr = join(".", @follows);
        PUSH_RESOLVED:
        foreach my $value ( @{$resolves} ) {
            if ( eval { $value->isa("PlSense::Entity") } ) {
                logger->debug("Resolved $curraddr -> ".$value->to_string." / $fstr");
                push @ret, $self->resolve_entity($allow_addr, $value, @follows);
            }
            elsif ( $self->is_valid_address_to_resolve($value) ) {
                my $naddr = $fstr ? $value.".".$fstr : $value;
                logger->debug("Resolved $curraddr -> $value / $fstr");
                if ( $allow_addr ) { push @ret, $naddr; }
                push @ret, $self->resolve_address_sentinel($naddr, $allow_addr);
            }
        }
        return @ret;
    }

    sub resolve_reverse_address : PRIVATE {
        my ($self, $addr, $allow_addr) = @_;

        my (@ret, @follows);
        if ( $addr !~ s{ \. ( R \.? .*? ) \z }{}xms ) { return @ret; }

        # If exist reference in address, try resolve by reverse routing.
        @follows = split m{ \. }xms, $1;
        my $curraddr = $addr;
        FIND:
        while ( $curraddr && ! exists $rrouteh_of{ident $self}->{$curraddr} ) {
            if ( $curraddr !~ s{ \. ([^.]+) \z }{}xms ) { last FIND; }
            unshift @follows, $1;
        }
        my $raddrs = $curraddr ? $rrouteh_of{ident $self}->{$curraddr} : [] or return @ret;

        my $fstr = join(".", @follows);
        PUSH_RESOLVED:
        foreach my $raddr ( @{$raddrs} ) {
            if ( $self->is_found_address_while_resolve($raddr) ) { next PUSH_RESOLVED; }
            my $naddr = $raddr.".".$fstr;
            logger->debug("Resolved $curraddr -> $raddr / $fstr");
            if ( $allow_addr ) { push @ret, $naddr; }
            push @ret, $self->resolve_address_sentinel($naddr, $allow_addr);
        }
        return @ret;
    }

    sub resolve_entity : PRIVATE {
        my ($self, $allow_addr, $entity, @follows) = @_;

        if ( ! $entity ) { return (); }
        my $etype = $entity->get_type;
        if ( $etype eq 'null' ) { return (); }
        my $follow = shift @follows or return ( $self->get_correct_entity($entity) );

        my @ret;
        my $ch = substr($follow, 0, 1);
        my $fstr = join(".", @follows);
        if ( $ch eq "A" ) {
            if ( $etype ne 'array' ) { return (); }
            my $el = $entity->get_element;
            if ( eval { $el->isa("PlSense::Entity") } ) {
                logger->debug("Resolved ".$entity->to_string.$follow." -> ".$el->to_string." / $fstr");
                return $self->resolve_entity($allow_addr, $el, @follows);
            }
            elsif ( $self->is_valid_address_to_resolve($el) ) {
                my $naddr = $el && $fstr ? $el.".".$fstr : $el;
                logger->debug("Resolved ".$entity->to_string.$follow." -> $el / $fstr");
                if ( $allow_addr ) { push @ret, $naddr; }
                push @ret, $self->resolve_address_sentinel($naddr, $allow_addr);
            }
        }
        elsif ( $ch eq "H" ) {
            if ( $etype ne 'hash' ) { return (); }
            $entity->set_membernm(substr($follow, 2));
            my $member = $entity->get_member || return ();
            if ( eval { $member->isa("PlSense::Entity") } ) {
                logger->debug("Resolved ".$entity->to_string.$follow." -> ".$member->to_string." / $fstr");
                return $self->resolve_entity($allow_addr, $member, @follows);
            }
            elsif ( $self->is_valid_address_to_resolve($member) ) {
                my $naddr = $member && $fstr ? $member.".".$fstr : $member;
                logger->debug("Resolved ".$entity->to_string.$follow." -> $member / $fstr");
                if ( $allow_addr ) { push @ret, $naddr; }
                push @ret, $self->resolve_address_sentinel($naddr, $allow_addr);
            }
        }
        elsif ( $ch eq "R" ) {
            if ( $etype eq 'reference' ) {
                my $e = $entity->get_entity || return ();
                if ( eval { $e->isa("PlSense::Entity") } ) {
                    logger->debug("Resolved ".$entity->to_string.$follow." -> ".$e->to_string." / $fstr");
                    return $self->resolve_entity($allow_addr, $e, @follows);
                }
                elsif ( $self->is_valid_address_to_resolve($e) ) {
                    my $naddr = $e && $fstr ? $e.".".$fstr : $e;
                    logger->debug("Resolved ".$entity->to_string.$follow." -> $e / $fstr");
                    if ( $allow_addr ) { push @ret, $naddr; }
                    push @ret, $self->resolve_address_sentinel($naddr, $allow_addr);
                }
            }
            elsif ( $etype eq 'instance' ) {
                my $mdlnm = $entity->get_modulenm or return ();
                my $baddr = '&'.$mdlnm.'::BLESS.R';
                if ( ! $self->is_valid_address_to_resolve($baddr) ) { return (); }
                my $naddr = $fstr ? $baddr.".".$fstr : $baddr;
                logger->debug("Resolved ".$entity->to_string.$follow." -> $baddr / $fstr");
                if ( $allow_addr ) { push @ret, $naddr; }
                push @ret, $self->resolve_address_sentinel($naddr, $allow_addr);
            }
        }
        elsif ( $ch eq "W" ) {
            if ( $etype ne 'instance' ) { return (); }
            my $mdl = mdlkeeper->get_module( $entity->get_modulenm ) or return ();
            my $mtdnm = substr($follow, 2);
            my $mtd = $mdl->get_any_method($mtdnm) or return ();
            my $mtdfullnm = $mtd->get_fullnm;
            if ( ! $self->is_valid_address_to_resolve($mtdfullnm) ) { return (); }
            my $naddr = $fstr ? $mtdfullnm.".".$fstr : $mtdfullnm;
            logger->debug("Resolved ".$entity->to_string.$follow." -> ".$mtdfullnm." / ".$fstr);
            if ( $allow_addr ) { push @ret, $naddr; }
            push @ret, $self->resolve_address_sentinel($naddr, $allow_addr);
        }
        return @ret;
    }

    sub get_correct_entity : PRIVATE {
        my ($self, $entity) = @_;
        if ( ! $entity ) { return; }

        if ( $entity->isa("PlSense::Entity::Array") ) {
            my $e = $entity->get_element;
            my $etype = eval { $e->get_type } || '';
            if ( $etype eq 'instance' ) { return $entity; }
            my $value = "";
            ADDR:
            for my $i ( 1..$entity->count_address ) {
                my $resolve;
                my @resolves = $self->resolve_address_sentinel($entity->get_address($i), 0);
                if ( $#resolves >= 0 ) {
                    @resolves = map { eval { $_->clone } } @resolves;
                    MERGE:
                    foreach my $value ( @resolves ) {
                        $resolve = $self->update_value($resolve, $value);
                    }
                }
                if ( ! $resolve ) { next ADDR; }
                if ( $resolve->isa("PlSense::Entity::Instance") ) {
                    $entity->set_element($resolve);
                    return $entity;
                }
                elsif ( $resolve->isa("PlSense::Entity::Array") ) {
                    my $curre = $resolve->get_element or next ADDR;
                    if ( ! eval { $curre->isa("PlSense::Entity::Scalar") } ) { next ADDR; }
                    my $currvalue = $curre->get_value || "";
                    $value .= $value ne "" && $currvalue ne "" ? " ".$currvalue : $currvalue;
                }
            }
            if ( $value eq "" ) { return $entity; }
            if ( $etype ne 'scalar' ) {
                $entity->set_element( PlSense::Entity::Scalar->new({ value => $value }) );
            }
            else {
                $e->set_value( $e->get_value ? $e->get_value." ".$value : $value );
            }
            return $entity;
        }

        return $entity;
    }


    sub update_value : PRIVATE {
        my ($self, $old, $new) = @_;

        # The value priority is Entity > Address > Null > Nothing
        if ( ! $new ) { return $old; }
        if ( ! $old ) { return $new; }
        my $oldtype = eval { $old->get_type } || '';
        my $newtype = eval { $new->get_type } || '';
        if ( ! $oldtype || $oldtype eq 'null' ) { return $new; }
        if ( ! $newtype || $newtype eq 'null' ) { return $old; }

        # If both is Entity, try to merge
        return $self->merge_entity($old, $new, $oldtype, $newtype);
    }

    sub merge_entity : PRIVATE {
        my ($self, $old, $new, $oldtype, $newtype) = @_;

        if ( $oldtype eq 'instance' ) {
            if ( $newtype ne 'instance' ) { return $new; }
            my $oldmdlnm = $old->get_modulenm || "";
            my $newmdlnm = $new->get_modulenm || "";
            if ( ! $oldmdlnm ) { return $new; }
            elsif ( $newmdlnm && $oldmdlnm ne $newmdlnm ) { return $new; }
            # my $oldmdl = mdlkeeper->get_module($old->get_modulenm);
            # my $newmdl = mdlkeeper->get_module($new->get_modulenm);
            # if ( ! $oldmdl ) {
            #     $old->set_modulenm($new->get_modulenm);
            # }
            # elsif ( $newmdl && $old->get_modulenm ne $new->get_modulenm ) {
            #     # looking for common parent of old and new.
            #     OLDPARENT:
            #     for my $i ( 0..$oldmdl->count_parent ) {
            #         my $currmdl = $i == 0 ? $oldmdl : $oldmdl->get_parent($i);
            #         NEWPARENT:
            #         for my $k ( 0..$newmdl->count_parent ) {
            #             my $chkmdl = $k == 0 ? $newmdl : $newmdl->get_parent($k);
            #             if ( $currmdl->get_name eq $chkmdl->get_name ) {
            #                 $old->set_modulenm($currmdl->get_name);
            #                 return;
            #             }
            #         }
            #     }
            # }
        }

        elsif ( $oldtype eq 'reference' ) {
            if ( $newtype ne 'reference' ) { return $new; }
            my $oldrefs = $old->get_entity;
            my $newrefs = $new->get_entity;
            $old->set_entity( $self->update_value($oldrefs, $newrefs) );
        }

        elsif ( $oldtype eq 'hash' ) {
            if ( $newtype ne 'hash' ) { return $new; }
            KEY:
            foreach my $key ( $old->keys_member ) {
                if ( ! $new->exist_member($key) ) { next KEY; }
                $old->set_membernm($key);
                $new->set_membernm($key);
                my $oldval = $old->get_member;
                my $newval = $new->get_member;
                $old->set_member( $self->update_value($oldval, $newval) );
            }
            KEY:
            foreach my $key ( $new->keys_member ) {
                if ( $old->exist_member($key) ) { next KEY; }
                $old->set_membernm($key);
                $new->set_membernm($key);
                $old->set_member($new->get_member);
            }
        }

        elsif ( $oldtype eq 'array' ) {
            if ( $newtype ne 'array' ) { return $new; }
            my $olde = $old->get_element;
            my $newe = $new->get_element;
            $old->set_element( $self->update_value($olde, $newe) );
        }

        elsif ( $oldtype eq 'scalar' ) {
            if ( $newtype ne 'scalar' ) { return $new; }
            $old->set_value($old->get_value ? $old->get_value." ".$new->get_value : $new->get_value);
        }

        return $old;
    }

    sub add_reverse_route : PRIVATE {
        my ($self, $addr, $raddr) = @_;
        if ( ! $addr || ! $raddr ) { return; }

        my $raddrs = $rrouteh_of{ident $self}->{$addr};
        if ( ! $raddrs ) {
            $raddrs = [];
            $rrouteh_of{ident $self}->{$addr} = $raddrs;
        }

        if ( $#{$raddrs} >= $max_reverse_address_entry_of{ident $self} ) { return; }

        my $idx = firstidx { $_ eq $raddr } @{$raddrs};
        if ( $idx >= 0 ) { return; }

        push @{$raddrs}, $raddr;
    }

    sub remove_reverse_route : PRIVATE {
        my ($self, $addr, $raddr) = @_;
        if ( ! $addr || ! $raddr ) { return; }
        my $raddrs = $rrouteh_of{ident $self}->{$addr} or return;
        my $idx = firstidx { $_ eq $raddr } @{$raddrs};
        if ( $idx < 0 ) { return; }
        splice @{$raddrs}, $idx, 1;
        if ( $#{$raddrs} < 0 ) { delete $rrouteh_of{ident $self}->{$addr}; }
    }

}

1;

__END__
