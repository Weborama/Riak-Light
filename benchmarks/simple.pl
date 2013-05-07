use strict;
use warnings;
use Benchmark::Forking qw(timethis timethese cmpthese);

use Net::Riak;
use Riak::Light;

die "please set the RIAK_PBC_HOST variable" unless $ENV{RIAK_PBC_HOST};

my $hash = { baz => 1024, boom => [1,2,3,4,5,1000] };

my ($host, $port) = split ':', $ENV{RIAK_PBC_HOST};

my $riak_light_client = Riak::Light->new(host => $host, port => $port);

$riak_light_client->put(foo_riak_light => key => $hash);

my $net_riak_client = Net::Riak->new(
    transport => 'PBC',
    host => $host,
    port => $port
);
my $net_riak_bucket = $net_riak_client->bucket('foo_net_riak');

$net_riak_client->bucket('foo_net_riak')->new_object(key => $hash)->store;

cmpthese(3_000, {
  "Riak::Light only get" => sub  {
    $riak_light_client->get(foo_riak_light => 'key'),
  },
  "Net::Riak only get" => sub  {
    $net_riak_bucket->get('key')->data;
  },
});