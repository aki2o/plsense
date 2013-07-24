#!/usr/bin/perl

my $glovalvar;

sub hogege {
    my $hogevar = shift;

    # astart variable in method 1
    #$
    # aend include: glovalvar hogevar
    # aend exclude: fugavar1

    return "";
}

sub fugaga {
    my ($fugavar1, @fugavar2) = @_;

    # astart variable in method 2
    #$
    # aend include: glovalvar fugavar1
    # aend exclude: hogevar

    return @fugavar2;
}


# astart explicit call own method 1
#&h
# aend include: hogege

# astart explicit call own method 2
#&f
# aend include: fugaga

# astart own method word 1
#h
# aend include: hogege
# ahelp hogege : ^ hogege \s is \s Method \s of \s main\[ [^\n]+ \]\. $
# ahelp hogege : ^ ARG1: \s \$hogevar \s As \s Unknown $
# ahelp hogege : ^ Return: \s Literal \s As \s SCALAR $

# astart own method word 2
#f
# aend include: fugaga
# ahelp fugaga : ^ fugaga \s is \s Method \s of \s main\[ [^\n]+ \]\. $
# ahelp fugaga : ^ ARG1: \s \$fugavar1 \s As \s Unknown $
# ahelp fugaga : ^ ARG2: \s @fugavar2 \s As \s Unknown $
# ahelp fugaga : ^ Return: \s @fugavar2 \s As \s Unknown $


# hstart own method
#hogege
# hend ^ hogege \s is \s Method \s of \s main\[ [^\n]+ \]\. $
# hend ^ ARG1: \s \$hogevar \s As \s Unknown $
# hend ^ Return: \s Literal \s As \s SCALAR $

