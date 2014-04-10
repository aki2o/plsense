#!/usr/bin/perl

=head1 NAME

defsub.pl - Check about defined sub.

=cut


# Inner package
package DefSub;

=head1 NAME

DefSub - This is a inner package.

=cut

# Start inner package

# Inner method
sub barar {
    my $barvar = shift;
    return "";
}

1;


package main;

=head1 DESCRIPTION

The following sub is defined.

- hogege
- fugaga

=cut

# Start main package

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
# ahelp hogege : ^ RETURN: \s Literal \s As \s SCALAR $

# astart own method word 2
#f
# aend include: fugaga
# ahelp fugaga : ^ fugaga \s is \s Method \s of \s main\[ [^\n]+ \]\. $
# ahelp fugaga : ^ ARG1: \s \$fugavar1 \s As \s Unknown $
# ahelp fugaga : ^ ARG2: \s @fugavar2 \s As \s Unknown $
# ahelp fugaga : ^ RETURN: \s @fugavar2 \s As \s Unknown $


# hstart own method
#hogege
# hend ^ hogege \s is \s Method \s of \s main\[ [^\n]+ \]\. $
# hend ^ ARG1: \s \$hogevar \s As \s Unknown $
# hend ^ RETURN: \s Literal \s As \s SCALAR $

# hstart explicit own method
#&hogege
# hend ^ hogege \s is \s Method \s of \s main\[ [^\n]+ \]\. $
# hend ^ ARG1: \s \$hogevar \s As \s Unknown $
# hend ^ RETURN: \s Literal \s As \s SCALAR $


# mstart own main method
#hogege
# mend ^ NAME: \s hogege $
# mend ^ ARG1: \s \$hogevar \s As \s Unknown $
# mend ^ RETURN: \s Literal \s As \s SCALAR $
# mend ^ FILE: \s .+ /02_defsub.pl $
# mend ^ LINE: \s 45 $
# mend ^ COL: \s 1 $

# mstart own main method 2
#fugaga
# mend ^ NAME: \s fugaga $
# mend ^ ARG1: \s \$fugavar1 \s As \s Unknown $
# mend ^ ARG2: \s \@fugavar2 \s As \s Unknown $
# mend ^ RETURN: \s \@fugavar2 \s As \s Unknown $
# mend ^ FILE: \s .+ /02_defsub.pl $
# mend ^ LINE: \s 56 $
# mend ^ COL: \s 1 $

# mstart explicit own main method
#&hogege
# mend ^ NAME: \s hogege $
# mend ^ ARG1: \s \$hogevar \s As \s Unknown $
# mend ^ RETURN: \s Literal \s As \s SCALAR $
# mend ^ FILE: \s .+ /02_defsub.pl $
# mend ^ LINE: \s 45 $
# mend ^ COL: \s 1 $

# mstart explicit own main method reference
#\&hogege
# mend ^ NAME: \s hogege $
# mend ^ ARG1: \s \$hogevar \s As \s Unknown $
# mend ^ RETURN: \s Literal \s As \s SCALAR $
# mend ^ FILE: \s .+ /02_defsub.pl $
# mend ^ LINE: \s 45 $
# mend ^ COL: \s 1 $

