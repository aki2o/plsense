package PlSense::Entity::Hash;

use parent qw{ PlSense::Entity };
use strict;
use warnings;
use Class::Std::Storable;
use PlSense::Logger;
{
    my %membernm_of :ATTR( :default('') );
    sub set_membernm {
        my ($self, $membernm) = @_;
        $membernm = $self->resolve_membernm($membernm);
        $membernm_of{ident $self} = $membernm;
    }

    my %memberh_of :ATTR();
    sub set_member {
        my ($self, $member) = @_;
        if ( ! $member ) { return; }
        my $membernm = $membernm_of{ident $self};
        my $membertext = eval { $member->isa("PlSense::Entity") } ? $member->to_string : $member;
        logger->debug("Set hash member[".$membernm."] : ".$membertext);
        $memberh_of{ident $self}->{$membernm} = $member;
    }
    sub get_member {
        my ($self) = @_;
        return $memberh_of{ident $self}->{$membernm_of{ident $self}};
    }
    sub keys_member { my ($self) = @_; return keys %{$memberh_of{ident $self}}; }
    sub exist_member {
        my ($self, $membernm) = @_;
        $membernm = $self->resolve_membernm($membernm);
        return exists $memberh_of{ident $self}->{$membernm};
    }

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $class->set_type("hash");
        $memberh_of{$ident} = {};
    }

    sub resolve_membernm : PRIVATE {
        my $self = shift;
        my $membernm = shift || "";
        $membernm =~ s{ \A (\{|\[) \s* }{}xms;
        $membernm =~ s{ \s* (\}|\]) \z }{}xms;
        $membernm =~ s{ \A ("|') }{}xms;
        $membernm =~ s{ ("|') \z }{}xms;
        if ( $membernm !~ m{ \A [a-zA-Z0-9_\-]+ \z }xms ) { $membernm = '*'; }
        return $membernm;
    }

    sub to_string {
        my $self = shift;
        my $ret = "H<";
        MEMBER:
        foreach my $m ( $self->keys_member ) {
            $self->set_membernm($m);
            my $member = $self->get_member || "";
            my $membertext = eval { $member->isa("PlSense::Entity") } ? $member->to_string : $member;
            $ret .= "$m => $membertext, ";
        }
        $ret .= ">";
        return $ret;
    }

    sub clone {
        my $self = shift;
        my $ret = PlSense::Entity::Hash->new();
        MEMBER:
        foreach my $membernm ( keys %{$memberh_of{ident $self}} ) {
            $ret->set_membernm($membernm);
            my $member = $memberh_of{ident $self}->{$membernm};
            if ( eval { $member->isa("PlSense::Entity") } ) {
                $ret->set_member($member->clone);
            }
            elsif ( $member ) {
                $ret->set_member($member);
            }
        }
        return $ret;
    }
}

1;

__END__
