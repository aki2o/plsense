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
        my $mdlhelptext = qx{ perldoc $mdlnm 2>/dev/null } || qx{ perldoc '$filepath' 2>/dev/null };
        if ( $mdlhelptext =~ m{ [^\s]+ }xms ) {
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
        my ($currc, $helptext, $lasttitle);
        TITLE:
        while ( $text =~ m{ ^ \s{$indent} ([^\s] [^\n]+) $ }xms ) {
            ($text, $helptext) = ($', $`);
            my $title = $1;
            $self->update_helptext($currc, $lasttitle, $helptext, $indent);
            undef $currc;
            $helptext = "";
            $lasttitle = $title;
            CAND:
            foreach my $cand ( @cands ) {
                my $c = $mdl->exist_member($cand) ? $mdl->get_member($cand) : $mdl->get_method($cand);
                my $regexp = quotemeta($cand);
                if ( $title =~ m{ \b $regexp \b }xms ) {
                    $currc = $c;
                    last CAND;
                }
            }
        }
        $self->update_helptext($currc, $lasttitle, $helptext, $indent);
    }

    sub update_helptext : PRIVATE {
        my ($self, $ident, $title, $text, $indent) = @_;
        my $helptext = "";
        if ( ! $ident || ! $title || ! $text || $text !~ m{ [^\s]+ }xms ) { return; }
        if ( $ident->get_helptext() ne "" ) {
            $helptext .= $ident->get_helptext()."\n\n=====\n\n";
        }
        $helptext .= $title;
        LINE:
        foreach my $line ( split m{ \n }xms, $text ) {
            $helptext .= length($line) < $indent ? $line."\n" : substr($line, $indent)."\n";
        }
        $ident->set_helptext($helptext);
        logger->debug("Updated help of [".$ident->get_fullnm."]");
    }
}

1;

__END__

