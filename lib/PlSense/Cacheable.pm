package PlSense::Cacheable;

use strict;
use warnings;
use Class::Std;
use Cache::FileCache;
use PlSense::Logger;
{
    my %cachedir_of :ATTR( :init_arg<cachedir> );
    sub get_cachedir : RESTRICTED { my ($self) = @_; return $cachedir_of{ident $self}; }

    my %projectnm_of :ATTR();
    sub set_project {
        my ($self, $projectnm) = @_;
        if ( ! $projectnm ) { return; }
        $projectnm_of{ident $self} = $projectnm;
        return 1;
    }
    sub get_project { my $self = shift; return $projectnm_of{ident $self}; }

    sub get_default_project_name {
        my $self = shift;
        return "default";
    }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        $projectnm_of{$ident} = $class->get_default_project_name;
    }

    sub new_cache : RESTRICTED {
        my ($self, $namespace) = @_;
        if ( ! -d $cachedir_of{ident $self} ) {
            logger->error("Not exist directory[".$cachedir_of{ident $self}."]");
            return;
        }
        my $ret = Cache::FileCache->new({ cache_root => $cachedir_of{ident $self},
                                          namespace => $namespace });
        if ( ! $ret ) {
            logger->error("Can't available cache directory[".$cachedir_of{ident $self}."]");
        }
        return $ret;
    }

    sub get_cache_key : RESTRICTED {
        my $self = shift;
        my $mdlnm_or_key = shift || "";
        my $filepath = shift || "";
        my $projectnm = shift || "";
        my $ret = $projectnm ? $projectnm."." : "";
        $ret .= $mdlnm_or_key eq "main" ? $mdlnm_or_key."|".$filepath : $mdlnm_or_key;
        return $ret;
    }
}

1;

__END__
