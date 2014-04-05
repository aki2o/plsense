package PlSense::Plugin::AddressFinder::Ext;

use parent qw{ PlSense::Plugin::AddressFinder };
use strict;
use warnings;
use Class::Std;
{
    sub get_method_name {
        my ($self) = @_;
        return "";
    }

    sub find_address {
        my ($self, @tokens) = @_;
        return;
    }

    sub find_address_or_entity {
        my ($self, @tokens) = @_;
        return;
    }

    sub get_argument_tokens {
        my ($self, @tokens) = @_;
        my $tok = shift @tokens or return ();
        if ( ! $tok->isa("PPI::Structure::List") ) { return ($tok, @tokens); }
        my @children = $tok->children;
        $tok = shift @children or return ();
        if ( ! $tok->isa("PPI::Statement") ) { return (); }
        return $tok->children;
    }
}

1;

__END__
