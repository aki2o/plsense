package PlSense::SubstituteBuilder;

use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Util;
use PlSense::AddressFinder;
{
    sub START {
        my ($class, $ident, $arg_ref) = @_;
        set_addrfinder( PlSense::AddressFinder->new({ with_build => 1, }) );
    }

    sub set_currentmodule {
        my ($self, $currentmodule) = @_;
        addrfinder->set_currentmodule($currentmodule);
    }
    sub set_currentmethod {
        my ($self, $currentmethod) = @_;
        addrfinder->set_currentmethod($currentmethod);
    }
    sub init_currentmethod {
        my ($self) = @_;
        addrfinder->init_currentmethod;
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

        my @addresses = addrfinder->find_addresses(@lefts);
        if ( $#addresses < 0 ) { return; }

        $self->build_substitute(\@addresses, @righttokens);
    }

    sub build_any_substitute_from_normal_statement {
        my ($self, @tokens) = @_;
        addrfinder->find_address_or_entity(@tokens);
    }

    sub build_substitute : PRIVATE {
        my ($self, $addresses, @tokens) = @_;

        my @values = addrfinder->find_addresses_or_entities(@tokens);
        if ( $#values < 0 ) { return; }

        my $mtd = addrfinder->get_currentmethod;
        my $argarraddr = $mtd ? '@'.$mtd->get_fullnm."::_" : "";
        if ( $argarraddr && ! eval { $values[0]->isa("PlSense::Entity") } && $values[0] eq $argarraddr ) {
            VAR:
            foreach my $addr ( @$addresses ) {
                addrfinder->forward_methodindex;
                substkeeper->add_substitute_to_argument($addr,
                                                        $mtd->get_fullnm,
                                                        addrfinder->get_methodindex,
                                                        1);
            }
            return;
        }

        substkeeper->add_substitutes($addresses, @values);
        return;
    }
}

1;

__END__
