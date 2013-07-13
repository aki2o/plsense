#!/usr/bin/perl

# tstart on use
#use 
# tend include: Exporter File::Spec Getopt::Long strict warnings
# tend exclude: grep map shift $_ @ARGV %ENV

# tstart on require
#require 
# tend include: Exporter File::Spec Getopt::Long strict warnings
# tend exclude: grep map shift $_ @ARGV %ENV

# tstart on use has word
#use Fi
# tend include: File::Spec File::Basename FindBin
# tend exclude: Exporter Getopt::Long strict warnings

# tstart on scalar
#$
# tend include: _ / , ARGV ENV

# tstart on array
#@
# tend include: ARGV

# tstart on hash
#%
# tend include: ENV

# tstart on funcall
#&
# tend include: grep map shift

# tstart on my
#my $
# tend equal:

# tstart on our
#our @
# tend equal:

# tstart on maybe function word
#m
# tend include: map
# tend exclude: min max

# tstart on maybe package word not included
#Fi
# tend include: File::Spec File::Basename FindBin
# tend exclude: Exporter Getopt::Long strict warnings

# tstart not included module literal method
#File::Spec->
# tend include: rel2abs abs2rel
# tend exclude: grep

