#!/usr/bin/perl

my %hash1;
$hash1{key1} = "";
$hash1{key2} = undef;
my $scalar1 = \%hash1;


# astart hash key
#$hash1{
# aend equal: key1 key2

# astart hash key has word
#$hash1{k
# aend equal: key1 key2

# astart hash key of reference
#$scalar1->{
# aend equal: key1 key2

# astart hash key of reference has word
#$scalar1->{k
# aend equal: key1 key2

