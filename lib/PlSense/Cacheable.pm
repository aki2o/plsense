package PlSense::Cacheable;

use strict;
use warnings;
use Class::Std;
use Cache::FileCache;
use PlSense::Logger;
use PlSense::Configure;
{
    my %projectnm_of :ATTR();
    sub get_project : RESTRICTED { my $self = shift; return $projectnm_of{ident $self}; }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        $projectnm_of{$ident} = get_default_config("name");
    }

    sub update_project {
        my $self = shift;
        $projectnm_of{ident $self} = get_config("name");
    }

    sub setup_without_reload {
        my $self = shift;
    }

    sub setup {
        my $self = shift;
        my $force = shift || 0;
    }

    sub new_cache : RESTRICTED {
        my ($self, $namespace) = @_;
        my $cachedir = get_config("cachedir");
        if ( ! -d $cachedir ) {
            logger->error("Not exist directory[".$cachedir."]");
            return;
        }
        my $ret = Cache::FileCache->new({ cache_root => $cachedir,
                                          namespace => $namespace });
        if ( ! $ret ) {
            logger->error("Can't available cache directory[".$cachedir."]");
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
