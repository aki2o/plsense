package MtdExport;

use strict;
use warnings;
use Exporter 'import';
use IO::Socket;
our @EXPORT = qw{ immtd };
{
    sub immtd {
        return IO::Socket::INET->new();
    }
}

1;

__END__
