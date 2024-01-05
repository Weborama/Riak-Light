## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Util;
## use critic
use strict;
use warnings;
use Config;
use Exporter 'import';

our @EXPORT_OK = qw(is_windows is_netbsd is_solaris);

#ABSTRACT: util class, provides is_windows, is_solaris, etc

sub is_windows {
    $Config{osname} eq 'MSWin32';
}

sub is_netbsd {
    $Config{osname} eq 'netbsd';
}

sub is_solaris {
    $Config{osname} eq 'solaris';
}

1;
__END__
=head1 DESCRIPTION
  
  Internal class
