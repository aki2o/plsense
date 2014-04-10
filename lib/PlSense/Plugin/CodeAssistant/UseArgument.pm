package PlSense::Plugin::CodeAssistant::UseArgument;

use parent qw{ PlSense::Plugin::CodeAssistant };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Util;
{
    sub is_only_valid_context {
        my ($self, $code, $tok) = @_;

        if ( ! $tok ) { return; }
        if ( ! $tok->isa("PPI::Token::QuoteLike::Words") && $tok->isa("PPI::Token::Quote") ) { return; }
        my $stmt = $tok->statement or return;
        if ( ! $stmt->isa("PPI::Statement::Include") ) { return; }
        my $mdlnm = $stmt->module or return;

        if ( $tok->content !~ m{ qw[^\s] \s* ([^;]*) \z  }xms &&
             $tok->content !~ m{ ["'] \s* ([^"']*) \z  }xms ) {
            return;
        }
        my $argtext = $1 || "";
        my @inputed = split m{ \s+ }xms, $argtext;
        my $input = $argtext eq "" || $argtext =~ m{ \s \z }xms ? "" : pop @inputed;

        logger->info("Match context : input[$input]");
        $self->set_input($input);

        my %inputed_is;
        INPUTED:
        foreach my $inputed ( @inputed ) {
            $inputed_is{$inputed} = 1;
        }

        logger->notice("Found use argument of $mdlnm");
        if ( $mdlnm eq "base" || $mdlnm eq "parent" ) {

            MODULE:
            foreach my $mdl ( mdlkeeper->get_packages ) {
                if ( $inputed_is{$mdl->get_name} ) { next MODULE; }
                $self->push_candidate($mdl->get_name, $mdl);
            }

        }
        else {

            my $mdl = mdlkeeper->get_module($mdlnm) or return;
            if ( ! $mdl->is_exportable ) { return; }

            my @exportvars;
            if ( $mdl->exist_member('@EXPORT') ) { push @exportvars, $mdl->get_member('@EXPORT'); }
            if ( $mdl->exist_member('@EXPORT_OK') ) { push @exportvars, $mdl->get_member('@EXPORT_OK'); }
            EXPORTVAR:
            foreach my $var ( @exportvars ) {
                if ( ! $var ) { next EXPORTVAR; }
                my $resolve = addrrouter->resolve_address($var->get_fullnm) or next EXPORTVAR;
                if ( ! $resolve->isa("PlSense::Entity::Array") ) { next EXPORTVAR; }
                my $scalar = $resolve->get_element or next EXPORTVAR;
                if ( ! eval { $scalar->isa("PlSense::Entity::Scalar") } ) { next EXPORTVAR; }
                EXPORTABLE:
                foreach my $somenm ( split m{ \s+ }xms, $scalar->get_value ) {
                    $somenm =~ s{ \A & }{}xms;
                    my $some = $mdl->get_method($somenm) || $mdl->get_member($somenm) or next EXPORTABLE;
                    if ( $some->isa("PlSense::Symbol::Variable") && $some->is_lexical ) { next EXPORTABLE; }
                    if ( $inputed_is{$some->get_name} ) { next EXPORTABLE; }
                    $self->push_candidate($some->get_name, $some);
                }
            }

            if ( $mdl->exist_member('%EXPORT_TAGS') ) {
                my $var = $mdl->get_member('%EXPORT_TAGS');
                my $resolve = addrrouter->resolve_address($var->get_fullnm) or return;
                if ( ! $resolve->isa("PlSense::Entity::Hash") ) { return; }
                KEY:
                foreach my $key ( $resolve->keys_member ) {
                    if ( $key eq '*' ) { next KEY; }
                    $resolve->set_membernm($key);
                    my $value = $resolve->get_member;
                    if ( eval { $value->isa("PlSense::Entity") } ) {
                        $self->push_candidate(":".$key, $value);
                    }
                    else {
                        $self->push_candidate(":".$key, addrrouter->resolve_address($value));
                    }
                }
            }

        }
        return 1;
    }
}

1;

__END__
