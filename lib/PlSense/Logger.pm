package PlSense::Logger;

use strict;
use warnings;
use Log::Handler;
use Exporter 'import';
our @EXPORT = qw( logger setup_logger update_logger_level );
{
    my $logger;
    my $logger_alias = "logger";

    sub logger {
        if ( ! $logger ) {
            setup_logger($ENV{PLSENSE_LOG_LEVEL});
        }
        return $logger;
    }

    sub setup_logger {
        my ($level, $filepath) = @_;
        if ( $filepath ) {
            $logger = Log::Handler->new(
                file => { filename => $filepath,
                          utf8 => 1,
                          maxlevel => $level ? $level : "err",
                          timeformat => '%H:%M:%S',
                          message_layout => '%m',
                          message_pattern => [ qw/%T %L %p %l %m/ ],
                          prepare_message => sub {
                              my $m = shift;
                              my $pkgnm = $m->{package};
                              $pkgnm =~ s{ ^PlSense:: }{}xms;
                              $m->{message} = sprintf("%s %-8s %-4s %-45s %s",
                                                      $m->{time}, $m->{level}.":", $$, $pkgnm."(".$m->{line}.")", $m->{message});
                          },
                          alias => $logger_alias,
                      },
                screen => { log_to => "STDERR",
                            maxlevel => "err",
                            message_layout => '%L: %m',
                        },
                );
        }
        else {
            $logger = Log::Handler->new(
                screen => { log_to => "STDERR",
                            maxlevel => $level ? $level : "err",
                            message_layout => '%L: %m',
                        },
                );
        }
    }

    sub update_logger_level {
        my ($level) = @_;
        if ( ! $level ) { return; }
        if ( ! $logger ) { return; }
        $logger->debug("Update log level : $level");
        $logger->set_level( $logger_alias => { maxlevel => $level } );
        return;
    }
}

1;

__END__

