#!/usr/bin/perl

my $scalar1;
my @arr1;
my %hash1;
our ($scalar2, @arr2, %hash2);


# astart own scalar
#$
# aend include: scalar1 arr1 hash1 scalar2 arr2 hash2

# astart own array
#@
# aend include: arr1 arr2

# astart own hash
#%
# aend include: hash1 hash2
# ahelp hash1 : ^ %hash1 \s is \s Variable \s of \s main\[ [^\n]+ \] \. $
# ahelp hash1 : ^ Not \s documented\. $


# hstart own variable
#$hash1{hoge}
# hend ^ %hash1 \s is \s Variable \s of \s main\[ [^\n]+ \] \. $
# hend ^ Not \s documented\. $

