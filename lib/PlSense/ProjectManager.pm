package PlSense::ProjectManager;

use strict;
use warnings;
use Class::Std;
use Config::Tiny;
use List::AllUtils qw{ first };
use File::Basename;
use PlSense::Logger;
use PlSense::Project;
{
    my %projects_of :ATTR();
    my %currentproject_of :ATTR();

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        $projects_of{$ident} = [];
    }

    sub open_project {
        my ($self, $confpath) = @_;

        my $fh;
        if ( ! open $fh, '<:utf8', $confpath ) {
            logger->error("Failed open conffile[$confpath] : $!");
            return;
        }
        my $c = Config::Tiny->read_string( do { local $/; <$fh> } );
        if ( ! close $fh ) {
            logger->error("Failed close conffile[$confpath] : $!");
            return;
        }

        my $projnm = $c->{_}{name};
        my $libpath = $c->{_}{"lib-path"} || "";
        if ( ! $projnm ) {
            logger->error("Not defined name section in [$confpath]");
            return;
        }

        my $p = first { $_->get_name eq $projnm } @{$projects_of{ident $self}};
        if ( ! $p ) {
            $p = PlSense::Project->new({ name => $projnm, confpath => $confpath });
            push @{$projects_of{ident $self}}, $p;
        }
        else {
            $p->set_confpath($confpath);
        }
        $p->set_libpath(dirname($confpath)."/".$libpath);
        $currentproject_of{ident $self} = $p;
        return $p;
    }

    sub get_current_project {
        my ($self) = @_;
        return $currentproject_of{ident $self};
    }

    sub clear_current_project {
        my ($self) = @_;
        $currentproject_of{ident $self} = undef;
    }
}

1;

__END__
