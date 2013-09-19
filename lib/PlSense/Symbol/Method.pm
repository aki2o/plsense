package PlSense::Symbol::Method;

use parent qw{ PlSense::Symbol };
use strict;
use warnings;
use Class::Std::Storable;
use PlSense::Logger;
{
    my %publicly_is :ATTR( :init_arg<publicly> :default(0) );
    sub set_publicly { my ($self, $publicly) = @_; $publicly_is{ident $self} = $publicly; }
    sub is_publicly { my ($self) = @_; return $publicly_is{ident $self}; }

    my %privately_is :ATTR( :init_arg<privately> :default(0) );
    sub set_privately { my ($self, $privately) = @_; $privately_is{ident $self} = $privately; }
    sub is_privately { my ($self) = @_; return $privately_is{ident $self}; }

    my %importive_is :ATTR( :init_arg<importive> :default(0) );
    sub set_importive { my ($self, $importive) = @_; $importive_is{ident $self} = $importive; }
    sub is_importive { my ($self) = @_; return $importive_is{ident $self}; }

    my %reserved_is :ATTR( :init_arg<reserved> :default(0) );
    sub set_reserved { my ($self, $reserved) = @_; $reserved_is{ident $self} = $reserved; }
    sub is_reserved { my ($self) = @_; return $reserved_is{ident $self}; }

    my %linenumber_of :ATTR( :init_arg<linenumber> :default(0) );
    sub set_linenumber {
        my ($self, $linenumber) = @_;
        if ( $linenumber !~ m{ ^\d+$ }xms ) {
            logger->warn("Not Integer");
            return;
        }
        $linenumber_of{ident $self} = $linenumber;
    }
    sub get_linenumber { my ($self) = @_; return $linenumber_of{ident $self}; }

    my %colnumber_of :ATTR( :init_arg<colnumber> :default(0) );
    sub set_colnumber {
        my ($self, $colnumber) = @_;
        if ( $colnumber !~ m{ ^\d+$ }xms ) {
            logger->warn("Not Integer");
            return;
        }
        $colnumber_of{ident $self} = $colnumber;
    }
    sub get_colnumber { my ($self) = @_; return $colnumber_of{ident $self}; }

    my %attribute_of :ATTR( :default(undef) );
    sub set_attribute { my ($self, $attribute) = @_; $attribute_of{ident $self} = $attribute; }
    sub get_attribute { my ($self) = @_; return $attribute_of{ident $self}; }

    my %module_of :ATTR( :init_arg<module> :default('') );
    sub set_module {
        my ($self, $module) = @_;
        if ( ! $module || ! $module->isa("PlSense::Symbol::Module") ) {
            logger->error("Not PlSense::Symbol::Module");
            return;
        }
        $module_of{ident $self} = $module;
        $module->set_method($self->get_name, $self);
    }
    sub get_module { my ($self) = @_; return $module_of{ident $self}; }

    my %variableh_of :ATTR();
    sub set_variable {
        my ($self, $variablenm, $variable) = @_;
        if ( ! $variable || ! $variable->isa("PlSense::Symbol::Variable") ) {
            logger->error("Not PlSense::Symbol::Variable");
            return;
        }
        if ( $variablenm ne $variable->get_name() ) {
            logger->warn("Not equal key[$variablenm] and variable's name[".$variable->get_name()."]");
            return;
        }
        $variableh_of{ident $self}->{$variablenm} = $variable;
        logger->debug("Set variable of [".$self->get_fullnm()."] : $variablenm");
    }
    sub exist_variable {
        my ($self, $variablenm) = @_;
        return $variablenm && exists $variableh_of{ident $self}->{$variablenm};
    }
    sub get_variable {
        my ($self, $variablenm) = @_;
        if ( ! exists $variableh_of{ident $self}->{$variablenm} ) {
            logger->warn("Not exist variable[$variablenm] in ".$self->get_fullnm);
            return;
        }
        return $variableh_of{ident $self}->{$variablenm};
    }
    sub keys_variable {
        my ($self) = @_;
        return keys %{$variableh_of{ident $self}};
    }

    my %argumenth_of :ATTR();
    sub set_argument {
        my ($self, $idx, $variable) = @_;
        if ( ! $variable || ! $variable->isa("PlSense::Symbol::Variable") ) {
            logger->error("Not PlSense::Symbol::Variable");
            return;
        }
        $argumenth_of{ident $self}->{$idx} = $variable;
        logger->debug("Set [$idx] argument of [".$self->get_fullnm."] : ".$variable->get_fullnm);
    }
    sub get_argument {
        my ($self, $idx) = @_;
        if ( ! exists $argumenth_of{ident $self}->{$idx} ) {
            return;
        }
        return $argumenth_of{ident $self}->{$idx};
    }
    sub get_arguments {
        my ($self) = @_;
        my @ret;
        my $idx = 1;
        ARG:
        while ( exists $argumenth_of{ident $self}->{$idx} ) {
            push @ret, $argumenth_of{ident $self}->{$idx};
            $idx++;
        }
        return @ret;
    }

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $class->set_type("method");
        $variableh_of{$ident} = {};
        $argumenth_of{$ident} = {};
    }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        if ( exists $arg_ref->{module} ) {
            $class->set_module($arg_ref->{module});
            logger->debug("New method : name[".$class->get_name."] module[".$class->get_module->get_name."]");
        }
        else {
            logger->debug("New method : name[".$class->get_name."]");
        }
    }

    sub get_fullnm {
        my $self = shift;
        my $module = $module_of{ident $self};
        return $module ? "&".$module->get_fullnm."::".$self->get_name
             :           "&".$self->get_name;
    }
}

1;

__END__
