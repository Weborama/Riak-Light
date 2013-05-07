use Test::More tests => 10;

BEGIN {
  use_ok('Riak::Light');  
  use_ok('Riak::Light::PBC');
  use_ok('Riak::Light::Socket');
  use_ok('Riak::Light::Connector');
  use_ok('Riak::Light::Driver');
}

require_ok('Riak::Light');
require_ok('Riak::Light::PBC');
require_ok('Riak::Light::Socket');
require_ok('Riak::Light::Connector');
require_ok('Riak::Light::Driver');
