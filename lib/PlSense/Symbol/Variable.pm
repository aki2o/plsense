package PlSense::Symbol::Variable;

use parent qw{ PlSense::Symbol };
use strict;
use warnings;
use Class::Std::Storable;
use Scalar::Util qw{ weaken };
use PlSense::Logger;
{
    my %lexical_is :ATTR( :init_arg<lexical> :default(1) );
    sub set_lexical { my ($self, $lexical) = @_; $lexical_is{ident $self} = $lexical; }
    sub is_lexical { my ($self) = @_; return $lexical_is{ident $self}; }

    my %importive_is :ATTR( :init_arg<importive> :default(0) );
    sub set_importive { my ($self, $importive) = @_; $importive_is{ident $self} = $importive; }
    sub is_importive { my ($self) = @_; return $importive_is{ident $self}; }

    my %belong_of :ATTR( :init_arg<belong> :default('') );
    sub set_belong {
        my ($self, $belong) = @_;
        $belong_of{ident $self} = $belong;
        weaken $belong_of{ident $self};
        if ( $belong->isa("PlSense::Symbol::Module") ) {
            $belong->set_member($self->get_name(), $self);
        }
        elsif ( $belong->isa("PlSense::Symbol::Method") ) {
            $belong->set_variable($self->get_name(), $self);
        }
        else {
            logger->error("Invalid value [$belong]");
        }
    }
    sub get_belong { my ($self) = @_; return $belong_of{ident $self}; }

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        my $ch = substr($class->get_name(), 0, 1) || "";
        $class->set_type( $ch eq '$' ? "scalar"
                        : $ch eq '@' ? "array"
                        : $ch eq '%' ? "hash"
                        :              "variable");
    }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        if ( exists $arg_ref->{belong} ) {
            $class->set_belong($arg_ref->{belong});
            logger->debug("New variable : name[".$class->get_name."] belong[".$class->get_belong->get_name."]");
        }
        else {
            logger->debug("New variable : name[".$class->get_name."]");
        }
    }

    sub get_id {
        my $self = shift;
        return substr $self->get_name(), 1;
    }

    sub get_fullnm {
        my $self = shift;
        my $belong = $self->get_belong();
        return $belong ? substr($self->get_name(), 0, 1).$belong->get_fullnm()."::".$self->get_id()
                       : $self->get_name();
    }
}

1;

__END__
