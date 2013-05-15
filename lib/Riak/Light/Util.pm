## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Util;
## use critic
use Config;
use Exporter 'import';

@EXPORT_OK = qw(is_windows is_netbsd_6_32bits);

sub is_windows {
    $Config{osname} eq 'MSWin32';
}

sub is_netbsd_6_32bits {
    _is_netbsd();
}

sub _is_netbsd {
    $Config{osname} eq 'netbsd';
}

1;

=head1 DESCRIPTION
  
  Internal class
