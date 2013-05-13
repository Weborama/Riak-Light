## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout;
## use critic

use Moo::Role;

# ABSTRACT: socket interface to add timeout in in/out operations

requires 'sysread';
requires 'syswrite';

1;

__END__

=head1 NAME

  Riak::Light::Timeout - Moo::Role to support IO Timeout for Riak::Light

=head1 VERSION

  version 0.001

=head1 DESCRIPTION
  
  Internal class
