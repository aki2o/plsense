#!/usr/bin/perl

use IO::File;

my $io = IO::File->new();

my @arrio;
push @arrio, $io;

my $sio = shift @arrio;
# astart shift
#$sio->
# aend include: ioctl seek fcntl

my $pio = pop @arrio;
# astart pop
#$pio->
# aend include: ioctl seek fcntl

my @greped = grep { $_ && $_->isa("IO::File") } @arrio;
# astart grep
#$greped[0]->
# aend include: ioctl seek fcntl

my @sorted = sort @arrio;
# astart sort
#$sorted[0]->
# aend include: ioctl seek fcntl

my @arrio2;
unshift @arrio2, $io;

my $sio2 = shift @arrio2;
# astart unshift
#$sio2->
# aend include: ioctl seek fcntl

my @revs = reverse @arrio;
# astart reverse
#$revs[0]->
# aend include: ioctl seek fcntl

my (%hashio, $keynm);
$hashio{$keynm} = $io;
foreach my $hashv ( values %hashio ) {
    # astart values
    #$hashv->
    # aend include: ioctl seek fcntl
}

my $evalio = eval { print ""; $io; };
# astart eval
#$evalio->
# aend include: ioctl seek fcntl


my @arrio3;
push(@arrio3, $io);

my $sio3 = shift(@arrio3);
# astart shift with brace
#$sio3->
# aend include: ioctl seek fcntl

my @greped2 = grep( { $_ && $_->isa("IO::File") } @arrio );
# astart grep with brace
#$greped2[0]->
# aend include: ioctl seek fcntl

