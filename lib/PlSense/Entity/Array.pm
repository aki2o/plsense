package PlSense::Entity::Array;

use parent qw{ PlSense::Entity };
use strict;
use warnings;
use Class::Std::Fast::Storable;
use PlSense::Logger;
use PlSense::Entity::Null;
{
    my %element_of :ATTR( :init_arg<element> :default('') );
    sub set_element {
        my ($self, $element) = @_;
        my $eltext = eval { $element->isa("PlSense::Entity") } ? $element->to_string : $element;
        logger->debug("Set array element : ".$eltext);
        $element_of{ident $self} = $element;
    }
    sub get_element { my ($self) = @_; return $element_of{ident $self}; }

    my %addresses_of :ATTR();
    sub push_address {
        my ($self, $address) = @_;
        if ( ! $address ) { return; }
        push @{$addresses_of{ident $self}}, $address;
    }
    sub count_address { my ($self) = @_; return $#{$addresses_of{ident $self}} + 1; }
    sub get_address {
        my ($self, $index) = @_;
        if ( $index !~ m{ ^\d+$ }xms ) {
            logger->warn("Not Integer");
            return;
        }
        if ( $index < 1 || $index > $#{$addresses_of{ident $self}} + 1 ) {
            logger->warn("Out of Index");
            return;
        }
        return @{$addresses_of{ident $self}}[$index - 1];
    }

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $class->set_type("array");
    }

    sub to_string {
        my $self = shift;
        my $ret = "A<";
        my $e = $self->get_element || "";
        $ret .= eval { $e->isa("PlSense::Entity") } ? $e->to_string : $e;
        KEY:
        for my $i ( 1..$self->count_address ) {
            $ret .= $i == 1 ? " | ".$self->get_address($i) : ", ".$self->get_address($i);
        }
        $ret .= ">";
        return $ret;
    }

    sub clone {
        my $self = shift;
        my $ret = PlSense::Entity::Array->new();
        ADDR:
        foreach my $addr ( @{$addresses_of{ident $self}} ) {
            $ret->push_address($addr);
        }
        if ( eval { $element_of{ident $self}->isa("PlSense::Entity") } ) {
            $ret->set_element( $element_of{ident $self}->clone );
        }
        elsif ( $element_of{ident $self} ) {
            $ret->set_element( $element_of{ident $self} );
        }
        return $ret;
    }
}

1;

__END__
