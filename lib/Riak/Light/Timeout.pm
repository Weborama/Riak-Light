## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout;
## use critic

use Moo::Role;

requires 'perform_sysread';
requires 'perform_syswrite';

1;