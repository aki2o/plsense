package PlSense::Plugin::IncludeStmt;

use strict;
use warnings;
use Class::Std;
{
    my %mdlkeeper_of :ATTR( :init_arg<mdlkeeper> );
    sub get_mdlkeeper : RESTRICTED { my ($self) = @_; return $mdlkeeper_of{ident $self}; }

    sub include_statement {
        my ($self, $mdl, $stmt) = @_;
    }
}

1;

__END__
