package PlSense::SocketClient;

use strict;
use warnings;
use Class::Std;
use IO::Socket;
use PlSense::Logger;
use PlSense::Configure;
{
    my %retryinterval_of :ATTR( :init_arg<retryinterval> :default(1) );
    my %maxretry_of :ATTR( :init_arg<maxretry> :default(10) );

    sub get_main_server_response {
        my ($self, $sendtext, $opt_ref) = @_;
        my $sock = $self->connect_main_server($opt_ref);
        return $self->get_server_response($sock, $sendtext);
    }

    sub get_work_server_response {
        my ($self, $sendtext, $opt_ref) = @_;
        my $sock = $self->connect_work_server($opt_ref);
        return $self->get_server_response($sock, $sendtext);
    }

    sub get_resolve_server_response {
        my ($self, $sendtext, $opt_ref) = @_;
        my $sock = $self->connect_resolve_server($opt_ref);
        return $self->get_server_response($sock, $sendtext);
    }

    sub request_main_server {
        my ($self, $sendtext, $opt_ref) = @_;
        my $sock = $self->connect_main_server($opt_ref);
        return $self->request_server($sock, $sendtext);
    }

    sub request_work_server {
        my ($self, $sendtext, $opt_ref) = @_;
        my $sock = $self->connect_work_server($opt_ref);
        return $self->request_server($sock, $sendtext);
    }

    sub request_resolve_server {
        my ($self, $sendtext, $opt_ref) = @_;
        my $sock = $self->connect_resolve_server($opt_ref);
        return $self->request_server($sock, $sendtext);
    }

    sub connect_main_server {
        my ($self, $opt_ref) = @_;
        return $self->connect_server("main", get_config("port1"), $opt_ref);
    }

    sub connect_work_server {
        my ($self, $opt_ref) = @_;
        return $self->connect_server("work", get_config("port2"), $opt_ref);
    }

    sub connect_resolve_server {
        my ($self, $opt_ref) = @_;
        return $self->connect_server("resolve", get_config("port3"), $opt_ref);
    }

    sub connect_server : PRIVATE {
        my ($self, $svtype, $port, $opt_ref) = @_;
        my $s;
        my $wait = 0;
        my $maxwait = $opt_ref->{maxretry} || $maxretry_of{ident $self};
        my $interval = $opt_ref->{retryinterval} || $retryinterval_of{ident $self};
        OPEN_SOCKET:
        while ( ! $s && $wait < $maxwait ) {
            $s = IO::Socket::INET->new(PeerAddr => "localhost",
                                       PeerPort => $port,
                                       Proto => "tcp",
                                       );
            $self->sleep_for($interval);
            $wait++;
        }
        if ( ! $s && ! $opt_ref->{ignore_error} ) {
            logger->error("Can't connect $svtype server : $!");
            return;
        }
        return $s;
    }

    sub request_server : PRIVATE {
        my ($self, $sock, $sendtext) = @_;
        $sendtext =~ s{ \n$ }{}xms;
        if ( ! $sock ) { return; }
        $sock->print("$sendtext\n");
        $sock->close;
        return 1;
    }

    sub get_server_response : PRIVATE {
        my ($self, $sock, $sendtext) = @_;
        $sendtext =~ s{ \n$ }{}xms;
        if ( ! $sock ) { return ""; }
        $sock->print("$sendtext\n");
        my $ret = "";
        LINE:
        while ( my $line = $sock->getline ) {
            $ret .= $line;
        }
        $sock->close;
        return $ret;
    }

    sub sleep_for : PRIVATE {
        my ($self, $duration) = @_;
        select undef, undef, undef, $duration;
        return;
    }
}

1;

__END__
