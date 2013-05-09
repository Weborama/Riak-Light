## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout;
## use critic

use Moo::Role;

# ABSTRACT: socket interface to add timeout in in/out operations

requires 'sysread';
requires 'syswrite';

1;
