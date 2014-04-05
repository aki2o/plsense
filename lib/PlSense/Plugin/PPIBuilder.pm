package PlSense::Plugin::PPIBuilder;

use strict;
use warnings;
use Class::Std;
{
    sub begin {
        my ($self, $mdl, $ppi) = @_;
    }

    sub start {
        my ($self, $mdl, $ppi) = @_;
    }

    sub end {
        my ($self, $mdl, $ppi) = @_;
    }

    sub scheduled_statement {
        my ($self, $mdl, $scheduled_type, $stmt) = @_;
    }

    sub sub_statement {
        my ($self, $mtd, $stmt) = @_;
    }

    sub variable_statement {
        my ($self, $vars, $stmt) = @_;
    }

    sub other_statement {
        my ($self, $mdl, $mtd, $stmt) = @_;
    }
}

1;

__END__

