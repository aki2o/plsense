package PlSense::SubstituteBuilder;

use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::SubstituteValueFinder;
{
    my %builtin_of :ATTR( :init_arg<builtin> );
    sub get_builtin : PRIVATE { my ($self) = @_; return $builtin_of{ident $self}; }

    my %mdlkeeper_of :ATTR( :init_arg<mdlkeeper> );
    sub get_mdlkeeper : PRIVATE { my ($self) = @_; return $mdlkeeper_of{ident $self}; }

    my %substkeeper_of :ATTR( :init_arg<substkeeper> );
    sub get_substkeeper : PRIVATE { my ($self) = @_; return $substkeeper_of{ident $self}; }

    my %finder_of :ATTR();
    sub get_finder : PRIVATE { my ($self) = @_; return $finder_of{ident $self}; }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        $finder_of{$ident} = PlSense::SubstituteValueFinder->new({ builtin => $class->get_builtin,
                                                                   mdlkeeper => $class->get_mdlkeeper,
                                                                   substkeeper => $class->get_substkeeper,
                                                                   with_build => 1, });
    }

    sub set_currentmodule {
        my ($self, $currentmodule) = @_;
        $finder_of{ident $self}->set_currentmodule($currentmodule);
    }
    sub set_currentmethod {
        my ($self, $currentmethod) = @_;
        $finder_of{ident $self}->set_currentmethod($currentmethod);
    }
    sub init_currentmethod {
        my ($self) = @_;
        $finder_of{ident $self}->init_currentmethod;
    }

    sub build_method_return {
        my ($self, $mtd, @tokens) = @_;

        if ( ! $mtd || ! $mtd->isa("PlSense::Symbol::Method") ) {
            logger->error("Not PlSense::Symbol::Method");
            return;
        }
        if ( $mtd->get_name eq "new" ) {
            logger->debug("Quit build method return because method name is new.");
            return;
        }

        my @addresses;
        push @addresses, $mtd->get_fullnm;
        $self->build_substitute(\@addresses, @tokens);
    }

    sub build_variable_substitute {
        my ($self, $vars, @tokens) = @_;

        my @addresses;
        VAR:
        foreach my $var ( @$vars ) {
            if ( ! $var || ! $var->isa("PlSense::Symbol::Variable") ) {
                logger->error("Not PlSense::Symbol::Variable");
                return;
            }
            push @addresses, $var->get_fullnm;
        }
        if ( $#addresses < 0 ) { return; }

        $self->build_substitute(\@addresses, @tokens);
    }

    sub build_substitute_with_find_variable {
        my ($self, $lefttokens, @righttokens) = @_;

        my @lefts = @{$lefttokens};
        if ( $#lefts < 0 ) { return; }

        my @addresses = $finder_of{ident $self}->find_addresses(@lefts);
        if ( $#addresses < 0 ) { return; }

        $self->build_substitute(\@addresses, @righttokens);
    }

    sub build_any_substitute_from_normal_statement {
        my ($self, @tokens) = @_;
        $finder_of{ident $self}->find_address_or_entity(@tokens);
    }

    sub build_substitute : PRIVATE {
        my ($self, $addresses, @tokens) = @_;

        my @values = $finder_of{ident $self}->find_addresses_or_entities(@tokens);
        if ( $#values < 0 ) { return; }

        my $mtd = $finder_of{ident $self}->get_currentmethod;
        my $argarraddr = $mtd ? '@'.$mtd->get_fullnm."::_" : "";
        if ( $argarraddr && ! eval { $values[0]->isa("PlSense::Entity") } && $values[0] eq $argarraddr ) {
            VAR:
            foreach my $addr ( @$addresses ) {
                $finder_of{ident $self}->forward_methodindex;
                $substkeeper_of{ident $self}->add_substitute_to_argument($addr,
                                                                         $mtd->get_fullnm,
                                                                         $finder_of{ident $self}->get_methodindex,
                                                                         1);
            }
            return;
        }

        $substkeeper_of{ident $self}->add_substitutes($addresses, @values);
        return;
    }
}

1;

__END__
