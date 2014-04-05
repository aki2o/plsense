package PlSense::CodeAssist;

use strict;
use warnings;
use List::AllUtils qw{ uniq };
use Class::Std;
use PPI::Lexer;
use Module::Pluggable instantiate => 'new', search_path => 'PlSense::Plugin::CodeAssistant';
use PlSense::Logger;
use PlSense::Util;
use PlSense::Helper;
{
    my %lexer_of :ATTR();
    my %assistants_of :ATTR();

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $assistants_of{$ident} = [];
        $lexer_of{$ident} = PPI::Lexer->new();
    }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        my @assistants = $class->plugins();
        ASSISTANT:
        foreach my $assist ( @assistants ) { push @{$assistants_of{$ident}}, $assist; }
    }

    sub get_assist {
        my ($self, $code) = @_;
        my @ret;

        my $currmdl = addrfinder->get_currentmodule;
        if ( ! $currmdl || ! $currmdl->isa("PlSense::Symbol::Module") ) {
            logger->warn("Not yet set current module");
            return @ret;
        }

        $code =~ s{ \n\z }{}xms;
        if ( ! $code ) { return @ret; }

        my $doc = $lexer_of{ident $self}->lex_source($code);
        $doc->prune("PPI::Token::Comment");
        $doc->prune("PPI::Token::Pod");
        my $tok = eval { $doc->last_token } or return @ret;

        ASSISTANT:
        foreach my $assist ( @{$assistants_of{ident $self}} ) {
            $assist->set_input("");
            $assist->init_last_candidate_instance;
            $assist->init_candidate;
        }

        logger->info("Start check only valid context");
        ASSISTANT:
        foreach my $assist ( @{$assistants_of{ident $self}} ) {
            if ( ! $assist->is_only_valid_context($code, $tok) ) { next ASSISTANT; }
            CANDIDATE:
            for my $i ( 1..$assist->count_candidate ) {
                push @ret, $assist->get_candidate($i);
            }
            return uniq(sort @ret);
        }

        logger->info("Start check valid context");
        ASSISTANT:
        foreach my $assist ( @{$assistants_of{ident $self}} ) {
            if ( ! $assist->is_valid_context($code, $tok) ) { next ASSISTANT; }
            CANDIDATE:
            for my $i ( 1..$assist->count_candidate ) {
                push @ret, $assist->get_candidate($i);
            }
        }
        return uniq(sort @ret);
    }

    sub get_last_candidate_instance {
        my ($self, $candidate) = @_;
        if ( ! $candidate ) { return; }
        ASSISTANT:
        foreach my $assist ( @{$assistants_of{ident $self}} ) {
            my $instance = $assist->get_last_candidate_instance($candidate);
            if ( ! $instance ) { next ASSISTANT; }
            return $instance;
        }
    }
}

1;

__END__
