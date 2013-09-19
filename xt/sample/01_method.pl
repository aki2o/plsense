#!/usr/bin/perl

use File::Spec;


# astart explicit call
#&s
# aend include: shift sort splice

# astart method word
#m
# aend include: map
# aend exclude: min max
# ahelp map : ^ map \s is \s Builtin \s Method\. $
# ahelp map : ^ RETURN: \s
# ahelp map : ^ map \s+ BLOCK \s+ LIST \s
# ahelp map : ^ map \s+ EXPR,LIST \s

# astart static call
#File::Spec->
# aend include: rel2abs abs2rel
# aend exclude: grep
# ahelp abs2rel : ^ abs2rel \s is \s Method \s of \s File::Spec
# ahelp abs2rel : ^ ===== \s Part \s of \s PerlDoc \s ===== \s+ abs2rel \s


# hstart builtin method
#map
# hend ^ map \s is \s Builtin \s Method\. $
# hend ^ RETURN: \s
# hend ^ map \s+ BLOCK \s+ LIST \s
# hend ^ map \s+ EXPR,LIST \s

# hstart static method
#File::Spec->abs2rel
# hend ^ abs2rel \s is \s Method \s of \s File::Spec
# hend ^ ===== \s Part \s of \s PerlDoc \s ===== \s+ abs2rel \s


# mstart static method
#File::Spec->abs2rel
# mend ^ NAME: \s abs2rel $
# mend ^ FILE: \s [^\s]+
# mend ^ LINE: \s \d+ $
# mend ^ COL: \s \d+ $

