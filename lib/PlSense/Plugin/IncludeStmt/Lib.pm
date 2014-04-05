package PlSense::Plugin::IncludeStmt::Lib;

use parent qw{ PlSense::Plugin::IncludeStmt };
use strict;
use warnings;
use Class::Std;
use File::Basename;
use PlSense::Util;
{
    sub include_statement {
        my ($self, $mdl, $includenm, $stmt) = @_;
        # if ( $includenm ne "lib" ) { return; }

        # my @tokens = $stmt->children;
        # my $e = shift @tokens or return;
        # if ( ! $e->isa("PPI::Token::Word") ) { return; }
        # $e = shift @tokens or return;
        # if ( $e->isa("PPI::Token::Whitespace") ) { $e = shift @tokens or return; }
        # if ( ! $e->isa("PPI::Token::Word") ) { return; }
        # $e = shift @tokens or return;
        # if ( $e->isa("PPI::Token::Whitespace") ) { $e = shift @tokens or return; }

        # my @libpathes;
        # if ( $e->isa("PPI::Token::QuoteLike::Words") ) {
        #     LIBPATH:
        #     foreach my $libpath ( $e->literal ) {
        #         push @libpathes, $libpath;
        #     }
        # }
        # elsif ( $e->isa("PPI::Structure::List") ) {
        #     @tokens = $e->children;
        #     $e = shift @tokens or return;
        #     if ( ! $e->isa("PPI::Statement::Expression") ) { return; }
        #     TOKEN:
        #     foreach my $tok ( $e->children ) {
        #         if ( ! $tok->isa("PPI::Token::Quote") ) { next TOKEN; }
        #         if ( $tok->isa("PPI::Token::Quote::Single") ) {
        #             push @libpathes, "".$tok->literal."";
        #         }
        #         else {
        #             my $value = "".$e->content."";
        #             $value =~ s{ ^ ("|') }{}xms;
        #             $value =~ s{ ("|') $ }{}xms;
        #             push @libpathes, $value;
        #         }
        #     }
        # }
        # elsif ( $e->isa("PPI::Token::Quote::Single") ) {
        #     push @libpathes, "".$e->literal."";
        # }
        # elsif ( $e->isa("PPI::Token::Quote") ) {
        #     my $value = "".$e->content."";
        #     $value =~ s{ ^ ("|') }{}xms;
        #     $value =~ s{ ("|') $ }{}xms;
        #     push @libpathes, $value;
        # }

        # my $currpath = dirname($mdl->get_filepath);
        # LIBPATH:
        # foreach my $libpath ( @libpathes ) {
        #     mdlkeeper->find_module($currpath."/".$libpath);
        # }
    }
}

1;

__END__
