package PlSense::Plugin::CodeAssistant;

use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Util;
{
    my %input_of :ATTR( :default('') );
    sub set_input { my ($self, $input) = @_; $input_of{ident $self} = $input; }
    sub get_input : RESTRICTED { my ($self) = @_; return $input_of{ident $self}; }

    my %candidates_of :ATTR( :default(undef) );
    my %lasth_of :ATTR( :default(undef) );
    sub push_candidate : RESTRICTED {
        my ($self, $candidate, $instance) = @_;
        my $input = quotemeta($self->get_input);
        if ( $input ne "" && $candidate !~ m{ ^ $input }xms ) { return; }
        push @{$candidates_of{ident $self}}, $candidate;
        $lasth_of{ident $self}->{$candidate} = $instance;
        logger->info("Push candidate : $candidate");
    }
    sub count_candidate { my ($self) = @_; return $#{$candidates_of{ident $self}} + 1; }
    sub get_candidate {
        my ($self, $index) = @_;
        if ( ! $index || $index !~ m{ ^\d+$ }xms ) {
            logger->warn("Not Integer");
            return;
        }
        if ( $index < 1 || $index > $#{$candidates_of{ident $self}} + 1 ) {
            logger->warn("Out of Index");
            return;
        }
        return $candidates_of{ident $self}->[$index - 1];
    }
    sub init_candidate {
        my $self = shift;
        $candidates_of{ident $self} = [];
    }

    sub get_last_candidate_instance {
        my ($self, $candidate) = @_;
        if ( ! $candidate || ! exists $lasth_of{ident $self}->{$candidate} ) {
            return;
        }
        return $lasth_of{ident $self}->{$candidate};
    }
    sub init_last_candidate_instance {
        my $self = shift;
        $lasth_of{ident $self} = {};
    }

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $candidates_of{$ident} = [];
        $class->init_last_candidate_instance;
    }

    sub is_valid_context {
        my ($self, $code, $tok) = @_;
        return 0;
    }

    sub is_only_valid_context {
        my ($self, $code, $tok) = @_;
        return 0;
    }
}

1;

__END__
