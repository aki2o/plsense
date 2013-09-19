package PlSense::ModuleBuilder::DocBuilder;

use parent qw{ PlSense::ModuleBuilder };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
{
    sub build {
        my ($self, $mdl) = @_;
        my $mdlnm = $mdl->get_name();
        if ( $mdlnm eq "main" ) { return; }

        my $filepath = $mdl->get_filepath;
        my $mdlhelptext = qx{ perldoc -t $mdlnm 2>/dev/null } || qx{ perldoc -t '$filepath' 2>/dev/null };
        if ( $mdlhelptext ne '' ) {
            $mdl->set_helptext($mdlhelptext);
        }
        else {
            logger->info("Can't get document of [$mdlnm] in [$filepath]");
            return;
        }

        my @cands = ($mdl->keys_member, $mdl->keys_method);
        my @indents = (4, 2, 0);
        my $remained = 1;
        BUILD:
        while ( $remained ) {
            $remained = 0;
            my $indent = pop @indents;
            if ( ! defined $indent ) { last BUILD; }
            $self->build_from_indent_matched($mdl, $mdlhelptext, $indent);
            CAND:
            foreach my $cand ( @cands ) {
                my $c = $mdl->exist_member($cand) ? $mdl->get_member($cand) : $mdl->get_method($cand);
                if ( $c->get_helptext() eq "" ) {
                    $remained = 1;
                    last CAND;
                }
            }
        }
    }

    sub build_from_indent_matched : PRIVATE {
        my ($self, $mdl, $text, $indent) = @_;
        my @cands = ($mdl->keys_member(), $mdl->keys_method());
        my ($helptext, $lasttitle);
        my @curre;
        TITLE:
        while ( $text =~ m{ ^ \s{$indent} ([^\s] [^\n]+) $ }xms ) {
            ($text, $helptext) = ($', $`);
            my $title = $1;

            if ( $self->update_helptext($lasttitle, $helptext, $indent, @curre) ) {
                @curre = ();
                $lasttitle = "";
            }

            my $c;
            CAND:
            foreach my $cand ( @cands ) {
                my $regexp = quotemeta($cand);
                if ( $title =~ m{ \A $regexp (\s|$) }xms ||
                     $title =~ m{ \A " $regexp " (\s|$) }xms ||
                     $title =~ m{ \A ' $regexp ' (\s|$) }xms ) {
                    $c = $mdl->exist_member($cand) ? $mdl->get_member($cand) : $mdl->get_method($cand) and last CAND;
                }
            }
            if ( $c ) {
                push @curre, $c;
                $lasttitle .= $title."\n";
            }
            else {
                @curre = ();
                $lasttitle = "";
            }
        }
        $self->update_helptext($lasttitle, $helptext, $indent, @curre);
    }

    sub update_helptext : PRIVATE {
        my ($self, $title, $text, $indent, @idents) = @_;
        if ( $#idents < 0 || ! $title || ! $text || $text !~ m{ [^\s] }xms ) { return; }

        my $validhelp;
        my $helptext = $title;
        LINE:
        foreach my $line ( split m{ \n }xms, $text ) {
            if ( $line =~ m{ [^\s] }xms && $line !~ s{ \A \s{$indent} }{}xms ) { last LINE; }
            $helptext .= $line."\n";
            $validhelp = 1;
        }
        if ( ! $validhelp ) { return; }

        ADD_HELPTEXT:
        foreach my $e ( @idents ) {
            if ( ! $e || ! $e->isa("PlSense::Symbol") ) { next ADD_HELPTEXT; }
            $e->set_helptext($e->get_helptext."\n===== Part of PerlDoc =====\n".$helptext);
            logger->info("Updated help of [".$e->get_fullnm."]");
        }
        return 1;
    }
}

1;

__END__

