package PlSense::Entity::Reference;

use parent qw{ PlSense::Entity };
use strict;
use warnings;
use Class::Std::Storable;
use PlSense::Logger;
use PlSense::Entity::Null;
{
    my %entity_of :ATTR( :init_arg<entity> :default('') );
    sub set_entity {
        my ($self, $entity) = @_;
        my $etext = eval { $entity->isa("PlSense::Entity") } ? $entity->to_string : $entity;
        logger->debug("Set reference referenced : ".$etext);
        $entity_of{ident $self} = $entity;
    }
    sub get_entity { my ($self) = @_; return $entity_of{ident $self}; }

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $class->set_type("reference");
    }

    sub to_string {
        my $self = shift;
        my $ret = "R<";
        my $e = $self->get_entity;
        $ret .= eval { $e->isa("PlSense::Entity") } ? $e->to_string : $e;
        $ret .= ">";
        return $ret;
    }

    sub clone {
        my $self = shift;
        my $ret = PlSense::Entity::Reference->new();
        if ( eval { $entity_of{ident $self}->isa("PlSense::Entity") } ) {
            $ret->set_entity( $entity_of{ident $self}->clone );
        }
        else {
            $ret->set_entity( $entity_of{ident $self} );
        }
        return $ret;
    }
}

1;

__END__
