## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Util;
## use critic
use Config;
use Exporter 'import';

#ABSTRACT: util class, provides is_windows, is_solaris, etc

@EXPORT_OK = qw(is_windows is_netbsd_6_32bits is_solaris);

sub is_windows {
    $Config{osname} eq 'MSWin32';
}

sub is_netbsd_6_32bits {
    _is_netbsd();
}

sub _is_netbsd {
    $Config{osname} eq 'netbsd';
}

sub is_solaris {
    $Config{osname} eq 'solaris';
}

1;

=head1 DESCRIPTION
  
  Internal class
