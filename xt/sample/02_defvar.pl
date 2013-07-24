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


# hstart own scalar
#$scalar1
# hend ^ \$scalar1 \s is \s Variable \s of \s main\[ [^\n]+ \] \. $
# hend ^ Not \s documented\. $

# hstart own array 1
#@arr1
# hend ^ @arr1 \s is \s Variable \s of \s main\[ [^\n]+ \] \. $
# hend ^ Not \s documented\. $

# hstart own array 2
#$arr1
# hend ^ @arr1 \s is \s Variable \s of \s main\[ [^\n]+ \] \. $
# hend ^ Not \s documented\. $

# hstart own hash 1
#%hash2
# hend ^ %hash2 \s is \s Variable \s of \s main\[ [^\n]+ \] \. $
# hend ^ Not \s documented\. $

# hstart own hash 2
#$hash2
# hend ^ %hash2 \s is \s Variable \s of \s main\[ [^\n]+ \] \. $
# hend ^ Not \s documented\. $

