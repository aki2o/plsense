#!/usr/bin/perl

for my $idx ( 0..10 ) {
    # astart for var 1
    #$
    # aend include: idx
}

for ( my $count = 0; $count <= 10; $count++ ) {
    # astart for var 2
    #$
    # aend include: count
}

foreach my $currword ( "hoge", "fuga" ) {
    # astart foreach var
    #$
    # aend include: currword
}

while ( my $line = <> ) {
    # astart while var
    #$
    # aend include: line
}

INDEX:
for my $lidx ( 0..10 ) {
    # astart label for var 1
    #$
    # aend include: lidx
}

ELEMENT:
for ( my $lcount = 0; $lcount <= 10; $lcount++ ) {
    # astart label for var 2
    #$
    # aend include: lcount
}

WORD:
foreach my $lcurrword ( "hoge", "fuga" ) {
    # astart label foreach var
    #$
    # aend include: lcurrword
}

LINE:
while ( my $lline = <> ) {
    # astart label while var
    #$
    # aend include: lline
}

