#!/usr/bin/perl

use IO::File;
use lib "lib";
use MtdExport qw{ immtd };

my $scalar1 = IO::File->new();
# astart scalar instance
#$scalar1->
# aend include: ioctl seek fcntl
# ahelp ioctl : ^ ioctl \s is \s Method \s of \s IO::

my @arr1;
$arr1[0] = IO::File->new();
# astart array instance
#$arr1[0]->
# aend include: ioctl seek fcntl

my %hash1;
$hash1{key1} = IO::File->new();
# astart hash scalar instance
#$hash1{key1}->
# aend include: ioctl seek fcntl

$hash1{key2} = \@arr1;
# astart hash array instance
#$hash1{key2}->[0]->
# aend include: ioctl seek fcntl

my $scalar2 = \%hash1;
# astart reference instance
#$scalar2->{key1}->
# aend include: ioctl seek fcntl


# astart import instance
#immtd->
# aend include: accept listen


foreach my $io ( @arr1 ) {
    # astart loop var instance
    #$io->
    # aend include: ioctl seek fcntl
}


# hstart instance method
#$scalar2->{key1}->ioctl
# hend ^ ioctl \s is \s Method \s of \s IO::


# mstart instance method
#$scalar2->{key1}->ioctl
# mend ^ NAME: \s ioctl $
# mend ^ FILE: \s .+ /IO/ .+ $
# mend ^ LINE: \s \d+ $
# mend ^ COL: \s \d+ $


