#!/usr/bin/perl

# astart scalar
#$
# aend include: _ / , ARGV ENV
# ahelp ENV : ^ %ENV \s is \s Builtin \s Variable\. $
# ahelp ENV : ^ ===== \s Part \s of \s PerlDoc \s ===== \n .

# astart array
#@
# aend include: ARGV
# ahelp ARGV : ^ @ARGV \s is \s Builtin \s Variable\. $
# ahelp ARGV : ^ ===== \s Part \s of \s PerlDoc \s ===== \n .

# astart hash
#%
# aend include: ENV

# astart array index
#$#
# aend include: ARGV

# astart scalar in str
#print "$
# aend include: _ / , ARGV ENV

# astart my
#my $
# aend equal:

# astart our
#our @
# aend equal:


# hstart builtin variable
#@ARGV
# hend ^ @ARGV \s is \s Builtin \s Variable\. $
# hend ^ ===== \s Part \s of \s PerlDoc \s ===== \n .

