package PlSense::Symbol::Module;

use parent qw{ PlSense::Symbol };
use strict;
use warnings;
use Class::Std::Storable;
use List::AllUtils qw{ first uniq firstidx };
use Scalar::Util qw{ weaken };
use PlSense::Logger;
{
    my %filepath_of :ATTR( :init_arg<filepath> );
    sub get_filepath { my ($self) = @_; return $filepath_of{ident $self}; }

    my %projectnm_of :ATTR( :init_arg<projectnm> :default('') );
    sub get_projectnm { my ($self) = @_; return $projectnm_of{ident $self}; }

    my %lastmodified_of :ATTR( :init_arg<lastmodified> );
    sub get_lastmodified { my ($self) = @_; return $lastmodified_of{ident $self}; }

    my %initialized_is :ATTR( :default(0) );
    sub initialized { my ($self) = @_; $initialized_is{ident $self} = 1; }
    sub uninitialized { my ($self) = @_; $initialized_is{ident $self} = 0; }
    sub is_initialized { my ($self) = @_; return $initialized_is{ident $self}; }

    my %parents_of :ATTR();
    sub update_parent {
        my ($self) = @_;
        DELETE_INVALID:
        while ( ( my $idx = firstidx { ! $_ } @{$parents_of{ident $self}} ) >= 0 ) {
            splice @{$parents_of{ident $self}}, $idx, 1;
        }
    }
    sub push_parent {
        my ($self, $parent, $not_weaken) = @_;
        if ( ! $parent || ! $parent->isa("PlSense::Symbol::Module") ) {
            logger->error("Not PlSense::Symbol::Module");
            return;
        }
        if ( $self->exist_parent($parent->get_name) ) {
            logger->warn("Already exist [".$parent->get_name()."]");
            return;
        }
        push @{$parents_of{ident $self}}, $parent;
        if ( ! $not_weaken ) { weaken @{$parents_of{ident $self}}[-1]; }
    }
    sub count_parent {
        my ($self) = @_;
        $self->update_parent;
        return $#{$parents_of{ident $self}} + 1;
    }
    sub get_parent {
        my ($self, $index) = @_;
        if ( $index !~ m{ ^\d+$ }xms ) {
            logger->warn("Not Integer");
            return;
        }
        if ( $index < 1 || $index > $#{$parents_of{ident $self}} + 1 ) {
            logger->warn("Out of Index");
            return;
        }
        return @{$parents_of{ident $self}}[$index - 1];
    }
    sub exist_parent {
        my ($self, $mdlnm) = @_;
        my @ret = grep { $_ && $_->get_name eq $mdlnm } @{$parents_of{ident $self}};
        return $#ret >= 0 ? 1 : 0;
    }
    sub reset_parent { my ($self) = @_; $parents_of{ident $self} = []; }

    my %usingmdls_of :ATTR();
    sub update_usingmdl {
        my ($self) = @_;
        DELETE_INVALID:
        while ( ( my $idx = firstidx { ! $_ } @{$usingmdls_of{ident $self}} ) >= 0 ) {
            splice @{$usingmdls_of{ident $self}}, $idx, 1;
        }
    }
    sub push_usingmdl {
        my ($self, $usingmdl, $not_weaken) = @_;
        if ( ! $usingmdl || ! $usingmdl->isa("PlSense::Symbol::Module") ) {
            logger->error("Not PlSense::Symbol::Module");
            return;
        }
        if ( $self->exist_usingmdl($usingmdl->get_name()) ) {
            logger->warn("Already exist : ".$usingmdl->get_name());
            return;
        }
        push @{$usingmdls_of{ident $self}}, $usingmdl;
        if ( ! $not_weaken ) { weaken @{$usingmdls_of{ident $self}}[-1]; }
    }
    sub count_usingmdl {
        my ($self) = @_;
        $self->update_usingmdl;
        return $#{$usingmdls_of{ident $self}} + 1;
    }
    sub get_usingmdl {
        my ($self, $index) = @_;
        if ( $index !~ m{ ^\d+$ }xms ) {
            logger->warn("Not Integer");
            return;
        }
        if ( $index < 1 || $index > $#{$usingmdls_of{ident $self}} + 1 ) {
            logger->warn("Out of Index");
            return;
        }
        return @{$usingmdls_of{ident $self}}[$index - 1];
    }
    sub exist_usingmdl {
        my ($self, $mdlnm) = @_;
        my @ret = grep { $_ && $_->get_name eq $mdlnm } @{$usingmdls_of{ident $self}};
        return $#ret >= 0 ? 1 : 0;
    }
    sub reset_usingmdl { my ($self) = @_; $usingmdls_of{ident $self} = []; }

    my %bundlemdls_of :ATTR( :default(undef) );
    sub update_bundlemdl {
        my ($self) = @_;
        DELETE_INVALID:
        while ( ( my $idx = firstidx { ! $_ } @{$bundlemdls_of{ident $self}} ) >= 0 ) {
            splice @{$bundlemdls_of{ident $self}}, $idx, 1;
        }
    }
    sub push_bundlemdl {
        my ($self, $bundlemdl, $not_weaken) = @_;
        if ( ! $bundlemdl || ! $bundlemdl->isa("PlSense::Symbol::Module") ) {
            logger->error("Not PlSense::Symbol::Module");
            return;
        }
        if ( $self->exist_bundlemdl($bundlemdl->get_name()) ) {
            logger->warn("Already exist : ".$bundlemdl->get_name());
            return;
        }
        push @{$bundlemdls_of{ident $self}}, $bundlemdl;
        if ( ! $not_weaken ) { weaken @{$bundlemdls_of{ident $self}}[-1]; }
    }
    sub count_bundlemdl {
        my ($self) = @_;
        $self->update_bundlemdl;
        return $#{$bundlemdls_of{ident $self}} + 1;
    }
    sub get_bundlemdl {
        my ($self, $index) = @_;
        if ( ! $index || $index !~ m{ ^\d+$ }xms ) {
            logger->warn("Not Integer");
            return;
        }
        if ( $index < 1 || $index > $#{$bundlemdls_of{ident $self}} + 1 ) {
            logger->warn("Out of Index");
            return;
        }
        return @{$bundlemdls_of{ident $self}}[$index - 1];
    }
    sub exist_bundlemdl {
        my ($self, $mdlnm) = @_;
        my @ret = grep { $_ && $_->get_name eq $mdlnm } @{$bundlemdls_of{ident $self}};
        return $#ret >= 0 ? 1 : 0;
    }
    sub reset_bundlemdl { my ($self) = @_; $bundlemdls_of{ident $self} = []; }

    my %memberh_of :ATTR();
    sub set_member {
        my ($self, $membernm, $member) = @_;
        if ( ! $member || ! $member->isa("PlSense::Symbol::Variable") ) {
            logger->error("Not PlSense::Symbol::Variable");
            return;
        }
        if ( $membernm ne $member->get_name() ) {
            logger->warn("Not equal key[$membernm] and member's name[".$member->get_name()."]");
            return;
        }
        $memberh_of{ident $self}->{$membernm} = $member;
    }
    sub exist_member {
        my ($self, $membernm) = @_;
        return $membernm && exists $memberh_of{ident $self}->{$membernm};
    }
    sub get_member {
        my ($self, $membernm) = @_;
        if ( ! exists $memberh_of{ident $self}->{$membernm} ) {
            logger->warn("Not exist member[$membernm] in ".$self->get_fullnm);
            return;
        }
        return $memberh_of{ident $self}->{$membernm};
    }
    sub keys_member {
        my ($self) = @_;
        return keys %{$memberh_of{ident $self}};
    }

    my %methodh_of :ATTR();
    sub set_method {
        my ($self, $methodnm, $method) = @_;
        if ( ! $method || ! $method->isa("PlSense::Symbol::Method") ) {
            logger->error("Not PlSense::Symbol::Method");
            return;
        }
        if ( $methodnm ne $method->get_name() ) {
            logger->warn("Not equal key[$methodnm] and method's name[".$method->get_name()."]");
            return;
        }
        $methodh_of{ident $self}->{$methodnm} = $method;
    }
    sub exist_method {
        my ($self, $methodnm) = @_;
        return $methodnm && exists $methodh_of{ident $self}->{$methodnm};
    }
    sub get_method {
        my ($self, $methodnm) = @_;
        if ( ! exists $methodh_of{ident $self}->{$methodnm} ) {
            logger->warn("Not exist method[$methodnm] in ".$self->get_fullnm);
            return;
        }
        return $methodh_of{ident $self}->{$methodnm};
    }
    sub keys_method {
        my ($self) = @_;
        return keys %{$methodh_of{ident $self}};
    }

    my %source_of :ATTR();
    sub set_source {
        my ($self, $source) = @_;
        $source_of{ident $self} = $source;
    }
    sub get_source { my ($self) = @_; return $source_of{ident $self}; }

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $class->set_type("module");
        $class->reset_all;

        my $name = $arg_ref->{name} || "";
        if ( ! $name || $name !~ m{ ^ [a-zA-Z_][a-zA-Z0-9_:]* $ }xms ) {
            logger->error("Name is invalid value : [$name]");
        }

        my $filepath = $arg_ref->{filepath} || "";
        if ( ! -f $filepath ) {
            logger->error("Not exist file[$filepath]");
        }
    }

    sub reset_all {
        my ($self, $lastmodified) = @_;
        $parents_of{ident $self} = [];
        $usingmdls_of{ident $self} = [];
        $bundlemdls_of{ident $self} = [];
        $memberh_of{ident $self} = {};
        $methodh_of{ident $self} = {};
        $source_of{ident $self} = undef;
        $initialized_is{ident $self} = 0;
        if ( $lastmodified ) { $lastmodified_of{ident $self} = $lastmodified; }
    }

    sub renew {
        my ($self) = @_;
        return PlSense::Symbol::Module->new({ name => $self->get_name,
                                              filepath => $self->get_filepath,
                                              projectnm => $self->get_projectnm,
                                              lastmodified => $self->get_lastmodified,
                                              linenumber => $self->get_linenumber,
                                              colnumber => $self->get_colnumber, });
    }

    sub interchange_to {
        my ($self, $mdl) = @_;
        if ( ! $mdl || ! $mdl->isa("PlSense::Symbol::Module") ) { return; }

        $self->reset_all($mdl->get_lastmodified);
        MEMBER:
        foreach my $membernm ( $mdl->keys_member ) {
            my $member = $mdl->get_member($membernm);
            $member->set_belong($self);
        }
        METHOD:
        foreach my $methodnm ( $mdl->keys_method ) {
            my $method = $mdl->get_method($methodnm);
            $method->set_module($self);
        }
        PARENT:
        for my $i ( 1..$mdl->count_parent ) { $self->push_parent( $mdl->get_parent($i) ); }
        USINGMDL:
        for my $i ( 1..$mdl->count_usingmdl ) { $self->push_usingmdl( $mdl->get_usingmdl($i) ); }
        BUNDLEMDL:
        for my $i ( 1..$mdl->count_bundlemdl ) { $self->push_bundlemdl( $mdl->get_bundlemdl($i) ); }
        $self->set_helptext($mdl->get_helptext);
        $self->set_source($mdl->get_source);
        $mdl->is_initialized ? $self->initialized : $self->uninitialized;
    }

    sub get_fullnm {
        my $self = shift;
        return $self->get_name eq "main" ? "main[".$self->get_filepath."]" : $self->get_name;
    }

    sub to_detail_string {
        my $self = shift;
        my $ret = "";
        my $first;
        my $addr = sprintf("%s", $self);
        $addr =~ s{ ^ PlSense::Symbol::Module=SCALAR\((.+)\) $ }{$1}xms;
        $ret .= "MYSELF: ".$self->get_name."($addr)\n";
        $ret .= "PARENT: ";
        $first = 1;
        PARENT:
        for ( my $i = 1; $i <= $self->count_parent; $i++ ) {
            my $mdl = $self->get_parent($i);
            if ( ! $first ) { $ret .= ", "; }
            $first = 0;
            $ret .= $mdl->get_name;
            my $addr = sprintf("%s", $mdl);
            $addr =~ s{ ^ PlSense::Symbol::Module=SCALAR\((.+)\) $ }{$1}xms;
            $ret .= "($addr)";
        }
        $ret .= "\n";
        $ret .= "INCLUDE: ";
        $first = 1;
        USINGMDL:
        for ( my $i = 1; $i <= $self->count_usingmdl; $i++ ) {
            my $mdl = $self->get_usingmdl($i);
            if ( ! $first ) { $ret .= ", "; }
            $first = 0;
            $ret .= $mdl->get_name;
            my $addr = sprintf("%s", $mdl);
            $addr =~ s{ ^ PlSense::Symbol::Module=SCALAR\((.+)\) $ }{$1}xms;
            $ret .= "($addr)";
        }
        $ret .= "\n";
        MEMBER:
        foreach my $var ( values %{$memberh_of{ident $self}} ) {
            $ret .= $var->get_name." LEXICAL[".$var->is_lexical."] IMPORTIVE[".$var->is_importive."]\n";
        }
        METHOD:
        foreach my $mtd ( values %{$methodh_of{ident $self}} ) {
            my $attr = $mtd->get_attribute;
            my $attrtext = $attr ? $attr->{content} : "";
            $ret .= "&".$mtd->get_name." ATTR[".$attrtext."] PUBLIC[".$mtd->is_publicly."] PRIVATE[".$mtd->is_privately."] IMPORTIVE[".$mtd->is_importive."] RESERVED[".$mtd->is_reserved."]\n";
            VAR:
            foreach my $varnm ( $mtd->keys_variable ) {
                my $var = $mtd->get_variable($varnm);
                $ret .= "  ".$var->get_name." LEXICAL[".$var->is_lexical."] IMPORTIVE[".$var->is_importive."]\n";
            }
        }
        return $ret;
    }

    sub is_objective {
        my $self = shift;
        return $self->exist_method("new");
    }

    sub is_exportable {
        my $self = shift;
        return $self->exist_parent("Exporter") || $self->exist_usingmdl("Exporter");
    }

    sub is_ancestor_of {
        my ($self, $mdl) = @_;
        if ( ! $mdl || ! $mdl->isa("PlSense::Symbol::Module") ) { return; }
        PARENT:
        for my $i ( 1..$mdl->count_parent ) {
            my $parent = $mdl->get_parent($i);
            if ( $parent->get_name eq $self->get_name ) { return 1; }
            $self->is_ancestor_of($parent) && return 1;
        }
        return;
    }

    sub get_own_methods {
        my ($self, $only_name) = @_;
        my %mtd_of;
        METHOD:
        foreach my $mtd ( values %{$methodh_of{ident $self}} ) {
            my $mtdnm = $mtd->get_name;
            if ( $mtd->is_importive ) { next METHOD; }
            $mtd_of{$mtdnm} = $mtd;
        }
        my @ret;
        PUSH:
        foreach my $mtdnm ( sort keys %mtd_of ) {
            push @ret, $only_name ? $mtdnm : $mtd_of{$mtdnm};
        }
        return @ret;
    }

    sub get_inherit_methods {
        my ($self, $only_name) = @_;
        my %mtd_of;
        PARENT:
        for ( my $i = 1; $i <= $self->count_parent; $i++ ) {
            my $parent = $self->get_parent($i);
            PARENTMTD:
            foreach my $mtd ( $parent->get_not_private_methods ) {
                if ( exists $mtd_of{$mtd->get_name} ) { next PARENTMTD; }
                $mtd_of{$mtd->get_name} = $mtd;
            }
        }
        my @ret;
        PUSH:
        foreach my $mtdnm ( sort keys %mtd_of ) {
            push @ret, $only_name ? $mtdnm : $mtd_of{$mtdnm};
        }
        return @ret;
    }

    sub get_public_methods {
        my ($self, $only_name) = @_;
        my %mtd_of;
        METHOD:
        foreach my $mtd ( values %{$methodh_of{ident $self}} ) {
            my $mtdnm = $mtd->get_name;
            if ( $mtd->is_importive ) { next METHOD; }
            if ( $mtd->is_reserved ) { next METHOD; }
            if ( ! $mtd->is_publicly ) { next METHOD; }
            $mtd_of{$mtdnm} = $mtd;
        }
        PARENT:
        for ( my $i = 1; $i <= $self->count_parent; $i++ ) {
            my $parent = $self->get_parent($i);
            PARENTMTD:
            foreach my $mtd ( $parent->get_public_methods ) {
                if ( exists $mtd_of{$mtd->get_name} ) { next PARENTMTD; }
                $mtd_of{$mtd->get_name} = $mtd;
            }
        }
        my @ret;
        PUSH:
        foreach my $mtdnm ( sort keys %mtd_of ) {
            push @ret, $only_name ? $mtdnm : $mtd_of{$mtdnm};
        }
        return @ret;
    }

    sub get_not_private_methods {
        my ($self, $only_name) = @_;
        my %mtd_of;
        METHOD:
        foreach my $mtd ( values %{$methodh_of{ident $self}} ) {
            my $mtdnm = $mtd->get_name;
            if ( $mtd->is_importive ) { next METHOD; }
            if ( $mtd->is_reserved ) { next METHOD; }
            if ( $mtd->is_privately ) { next METHOD; }
            $mtd_of{$mtdnm} = $mtd;
        }
        INHERITMTD:
        foreach my $mtd ( $self->get_inherit_methods ) {
            if ( exists $mtd_of{$mtd->get_name} ) { next INHERITMTD; }
            $mtd_of{$mtd->get_name} = $mtd;
        }
        my @ret;
        PUSH:
        foreach my $mtdnm ( sort keys %mtd_of ) {
            push @ret, $only_name ? $mtdnm : $mtd_of{$mtdnm};
        }
        return @ret;
    }

    sub get_all_objective_methods {
        my ($self, $only_name) = @_;
        my %mtd_of;
        METHOD:
        foreach my $mtd ( values %{$methodh_of{ident $self}} ) {
            my $mtdnm = $mtd->get_name;
            if ( $mtd->is_importive ) { next METHOD; }
            if ( $mtd->is_reserved ) { next METHOD; }
            $mtd_of{$mtdnm} = $mtd;
        }
        INHERITMTD:
        foreach my $mtd ( $self->get_inherit_methods ) {
            if ( exists $mtd_of{$mtd->get_name} ) { next INHERITMTD; }
            $mtd_of{$mtd->get_name} = $mtd;
        }
        my @ret;
        PUSH:
        foreach my $mtdnm ( sort keys %mtd_of ) {
            push @ret, $only_name ? $mtdnm : $mtd_of{$mtdnm};
        }
        return @ret;
    }

    sub get_instance_methods {
        my ($self, $mdl, $only_name) = @_;
        $only_name = $only_name ? 1 : 0;
        my $is_me = $mdl && $mdl->isa("PlSense::Symbol::Module") && $self->get_name eq $mdl->get_name ? 1 : 0;
        my $is_ancestor = $self->is_ancestor_of($mdl) ? 1 : 0;
        my $mdltext = $mdl && $mdl->isa("PlSense::Symbol::Module") ? $mdl->get_name : "";
        logger->debug("Get instance methods of [".$self->get_name."] in [$mdltext]. is_me[$is_me] is_ancestor[$is_ancestor] only_name[$only_name]");
        return $is_me       ? $self->get_all_objective_methods($only_name)
             : $is_ancestor ? $self->get_not_private_methods($only_name)
             :                $self->get_public_methods($only_name);
    }

    sub get_static_methods {
        my ($self, $mdl, $only_name) = @_;
        my %mtd_of;
        INSTANCEMTD:
        foreach my $mtd ( $self->get_instance_methods($mdl) ) {
            $mtd_of{$mtd->get_name} = $mtd;
        }
        IMPORTMTD:
        foreach my $mtd ( values %{$methodh_of{ident $self}} ) {
            my $mtdnm = $mtd->get_name;
            if ( ! $mtd->is_importive ) { next IMPORTMTD; }
            if ( $mtd->is_reserved ) { next IMPORTMTD; }
            if ( exists $mtd_of{$mtdnm} ) { next IMPORTMTD; }
            USINGMDL:
            for ( my $i = 1; $i <= $self->count_usingmdl; $i++ ) {
                my $m = $self->get_usingmdl($i);
                if ( ! $m->exist_method($mtdnm) ) { next USINGMDL; }
                my $extmtd = $m->get_method($mtdnm);
                if ( $extmtd->is_importive ) { next USINGMDL; }
                $mtd_of{$mtdnm} = $extmtd;
                last USINGMDL;
            }
            if ( ! exists $mtd_of{$mtdnm} ) { $mtd_of{$mtdnm} = $mtd; }
        }
        my @ret;
        PUSH:
        foreach my $mtdnm ( sort keys %mtd_of ) {
            push @ret, $only_name ? $mtdnm : $mtd_of{$mtdnm};
        }
        return @ret;
    }

    sub get_any_methods {
        my ($self, $only_name) = @_;
        my %mtd_of;
        METHOD:
        foreach my $mtd ( values %{$methodh_of{ident $self}} ) {
            my $mtdnm = $mtd->get_name;
            $mtd_of{$mtdnm} = $mtd;
        }
        INHERITMTD:
        foreach my $mtd ( $self->get_inherit_methods ) {
            if ( exists $mtd_of{$mtd->get_name} ) { next INHERITMTD; }
            $mtd_of{$mtd->get_name} = $mtd;
        }
        my @ret;
        PUSH:
        foreach my $mtdnm ( sort keys %mtd_of ) {
            push @ret, $only_name ? $mtdnm : $mtd_of{$mtdnm};
        }
        return @ret;
    }

    sub get_any_original_methods {
        my ($self, $only_name) = @_;
        my %mtd_of;
        METHOD:
        foreach my $mtd ( values %{$methodh_of{ident $self}} ) {
            my $mtdnm = $mtd->get_name;
            if ( $mtd->is_importive ) {
                USINGMDL:
                for ( my $i = 1; $i <= $self->count_usingmdl; $i++ ) {
                    my $m = $self->get_usingmdl($i);
                    if ( ! $m->exist_method($mtdnm) ) { next USINGMDL; }
                    my $extmtd = $m->get_method($mtdnm);
                    # if ( $extmtd->is_importive ) { next USINGMDL; }
                    $mtd_of{$mtdnm} = $extmtd;
                    last USINGMDL;
                }
                if ( ! exists $mtd_of{$mtdnm} ) { $mtd_of{$mtdnm} = $mtd; }
            }
            else {
                $mtd_of{$mtdnm} = $mtd;
            }
        }
        INHERITMTD:
        foreach my $mtd ( $self->get_inherit_methods ) {
            if ( exists $mtd_of{$mtd->get_name} ) { next INHERITMTD; }
            $mtd_of{$mtd->get_name} = $mtd;
        }
        my @ret;
        PUSH:
        foreach my $mtdnm ( sort keys %mtd_of ) {
            push @ret, $only_name ? $mtdnm : $mtd_of{$mtdnm};
        }
        return @ret;
    }

    sub get_external_methods {
        my ($self, $only_name) = @_;
        my %mtd_of;
        USINGMDL:
        for ( my $i = 1; $i <= $self->count_usingmdl; $i++ ) {
            my $m = $self->get_usingmdl($i);
            MTD:
            foreach my $mtd ( $m->get_public_methods ) {
                if ( exists $mtd_of{$mtd->get_fullnm} ) { next MTD; }
                $mtd_of{$mtd->get_fullnm} = $mtd;
            }
        }
        my @ret;
        PUSH:
        foreach my $mtdnm ( sort keys %mtd_of ) {
            push @ret, $only_name ? $mtdnm : $mtd_of{$mtdnm};
        }
        return @ret;
    }

    sub get_instance_method {
        my ($self, $mdl, $mtdnm) = @_;
        return first { $mtdnm && $_->get_name eq $mtdnm } $self->get_instance_methods($mdl);
    }

    sub get_any_method {
        my ($self, $mtdnm) = @_;
        if ( ! $mtdnm ) { return; }
        if ( $mtdnm =~ s{ \A SUPER:: }{}xms ) {
            PARENT:
            for my $i ( 1..$self->count_parent ) {
                my $parent = $self->get_parent($i);
                # I'm not sure which method is right, get_any_method, get_instance_method.
                my $mtd = $parent->get_any_method($mtdnm) or next PARENT;
                return $mtd;
            }
        }
        else {
            return first { $_->get_name eq $mtdnm } $self->get_any_methods;
        }
    }

    sub get_any_original_method {
        my ($self, $mtdnm) = @_;
        my $mtd = $self->get_any_method($mtdnm) or return;
        if ( ! $mtd->is_importive ) { return $mtd; }
        USINGMDL:
        for ( my $i = 1; $i <= $self->count_usingmdl; $i++ ) {
            my $m = $self->get_usingmdl($i);
            if ( ! $m->exist_method($mtdnm) ) { next USINGMDL; }
            my $extmtd = $m->get_method($mtdnm);
            # if ( $extmtd->is_importive ) { next USINGMDL; }
            return $extmtd;
        }
        return $mtd;
    }

    sub exist_instance_method {
        my ($self, $mdl, $mtdnm) = @_;
        return $self->get_instance_method($mdl, $mtdnm) ? 1 : 0;
    }

    sub exist_any_method {
        my ($self, $mtdnm) = @_;
        return $self->get_any_method($mtdnm) ? 1 : 0;
    }

    sub get_public_scalars {
        my ($self, $only_name) = @_;
        return $self->get_public_variables("scalar", $only_name);
    }

    sub get_public_arrays {
        my ($self, $only_name) = @_;
        return $self->get_public_variables("array", $only_name);
    }

    sub get_public_hashes {
        my ($self, $only_name) = @_;
        return $self->get_public_variables("hash", $only_name);
    }

    sub get_public_any_variables {
        my ($self, $only_name) = @_;
        return $self->get_public_variables("", $only_name);
    }

    sub get_public_variables : PRIVATE {
        my ($self, $type, $only_name) = @_;
        my %var_of;
        MEMBER:
        foreach my $var ( values %{$memberh_of{ident $self}} ) {
            if ( $var->is_lexical ) { next MEMBER; }
            # This comment out is wrong. but effort for bad module that not use 'my' and 'our' at definition
            # if ( $var->is_importive ) { next MEMBER; }
            if ( $type && $var->get_type ne $type ) { next MEMBER; }
            $var_of{$var->get_fullnm} = $var;
        }
        my @ret;
        PUSH:
        foreach my $varnm ( sort keys %var_of ) {
            push @ret, $only_name ? $varnm : $var_of{$varnm};
        }
        return @ret;
    }

    sub get_current_scalars {
        my ($self, $methodnm, $only_name) = @_;
        return $self->get_current_variables("scalar", $methodnm, $only_name);
    }

    sub get_current_arrays {
        my ($self, $methodnm, $only_name) = @_;
        return $self->get_current_variables("array", $methodnm, $only_name);
    }

    sub get_current_hashes {
        my ($self, $methodnm, $only_name) = @_;
        return $self->get_current_variables("hash", $methodnm, $only_name);
    }

    sub get_current_any_variables {
        my ($self, $methodnm, $only_name) = @_;
        return $self->get_current_variables("", $methodnm, $only_name);
    }

    sub get_current_variables : PRIVATE {
        my ($self, $type, $mtdnm, $only_name) = @_;
        my %var_of;
        if ( $self->exist_method($mtdnm) ) {
            my $mtd = $self->get_method($mtdnm);
            VARIABLE:
            foreach my $varnm ( $mtd->keys_variable ) {
                my $var = $mtd->get_variable($varnm);
                if ( $type && $var->get_type ne $type ) { next VARIABLE; }
                if ( exists $var_of{$varnm} ) { next VARIABLE; }
                $var_of{$varnm} = $var;
            }
        }
        MEMBER:
        foreach my $var ( values %{$memberh_of{ident $self}} ) {
            my $varnm = $var->get_name;
            if ( $type && $var->get_type ne $type ) { next MEMBER; }
            if ( exists $var_of{$varnm} ) { next MEMBER; }
            $var_of{$varnm} = $var;
        }
        my @ret;
        PUSH:
        foreach my $varnm ( sort keys %var_of ) {
            push @ret, $only_name ? $varnm : $var_of{$varnm};
        }
        return @ret;
    }

    sub get_external_scalars {
        my ($self, $only_name) = @_;
        return $self->get_external_variables("scalar", $only_name);
    }

    sub get_external_arrays {
        my ($self, $only_name) = @_;
        return $self->get_external_variables("array", $only_name);
    }

    sub get_external_hashes {
        my ($self, $only_name) = @_;
        return $self->get_external_variables("hash", $only_name);
    }

    sub get_external_any_variables {
        my ($self, $only_name) = @_;
        return $self->get_external_variables("", $only_name);
    }

    sub get_external_variables : PRIVATE {
        my ($self, $type, $only_name) = @_;
        my %var_of;
        USINGMDL:
        for ( my $i = 1; $i <= $self->count_usingmdl; $i++ ) {
            my $m = $self->get_usingmdl($i);
            VAR:
            foreach my $var ( $m->get_public_variables($type, 0) ) {
                if ( $type && $var->get_type ne $type ) { next VAR; }
                if ( exists $var_of{$var->get_fullnm} ) { next VAR; }
                $var_of{$var->get_fullnm} = $var;
            }
        }
        my @ret;
        PUSH:
        foreach my $varnm ( sort keys %var_of ) {
            push @ret, $only_name ? $varnm : $var_of{$varnm};
        }
        return @ret;
    }

    sub get_all_parents {
        my ($self, $only_name) = @_;
        my @ret;
        PARENT:
        for ( my $i = 1; $i <= $self->count_parent; $i++ ) {
            my $parent = $self->get_parent($i);
            push @ret, $parent;
            push @ret, $parent->get_all_parents;
        }
        return ! $only_name ? @ret : map { $_->get_name } @ret;
    }
}

1;

__END__
