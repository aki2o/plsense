package BlessParent;

use strict;
use warnings;

sub new {
    my ($class, $arg_ref) = @_;
    my $self = {};

    $self->{hoge} = $arg_ref->{hoge} || undef;
    $self->{fuga} = $arg_ref->{fuga} || undef;

    bless $self, $class;
    return $self;
}

sub set_hoge {
    my ($self, $hoge) = @_;
    $self->{hoge} = $hoge;

    # astart blessed hash member
    #$self->{
    # aend equal: fuga hoge
}

sub get_hoge {
    my $self = shift;
    return $self->{hoge};

    # astart own method of blessed class by shift
    #$self->
    # aend equal: can get_fuga get_hoge isa new set_fuga set_hoge
}

sub set_fuga {
    my ($self, $fuga) = @_;
    $self->{fuga} = $fuga;
}

sub get_fuga {
    my ($self) = @_;
    return $self->{fuga};

    # astart own method of blessed class by @_
    #$self->
    # aend equal: can get_fuga get_hoge isa new set_fuga set_hoge
}

1;

__END__
