package PlSense::Plugin::IncludeStmt::Vars;

use parent qw{ PlSense::Plugin::IncludeStmt };
use strict;
use warnings;
use Class::Std;
{
    sub include_statement {
        my ($self, $mdl, $includenm, $stmt) = @_;
        if ( $includenm ne "vars" ) { return; }

        my @tokens = $stmt->children;
        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Word") ) { return; }
        $e = shift @tokens or return;
        if ( $e->isa("PPI::Token::Whitespace") ) { $e = shift @tokens or return; }
        if ( ! $e->isa("PPI::Token::Word") ) { return; }
        $e = shift @tokens or return;
        if ( $e->isa("PPI::Token::Whitespace") ) { $e = shift @tokens or return; }

        if ( $e->isa("PPI::Token::QuoteLike::Words") ) {
            VAR:
            foreach my $varnm ( $e->literal ) {
                PlSense::Symbol::Variable->new({ name => "$varnm", lexical => 0, belong => $mdl, });
            }
        }
        elsif ( $e->isa("PPI::Structure::List") ) {
            @tokens = $e->children;
            $e = shift @tokens or return;
            if ( ! $e->isa("PPI::Statement::Expression") ) { return; }
            VAR:
            foreach my $tok ( $e->children ) {
                if ( ! $tok->isa("PPI::Token::Quote") ) { next VAR; }
                my $varnm;
                if ( $tok->isa("PPI::Token::Quote::Single") ) {
                    $varnm = "".$tok->literal."";
                }
                else {
                    $varnm = "".$tok->content."";
                    $varnm =~ s{ \A ("|') }{}xms;
                    $varnm =~ s{ ("|') \z }{}xms;
                }
                PlSense::Symbol::Variable->new({ name => $varnm, lexical => 0, belong => $mdl, });
            }
        }
    }
}

1;

__END__
