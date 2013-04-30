use strict;
use warnings;
use Benchmark::Forking qw(timethis timethese cmpthese);

use Net::Riak;
use Riak::Light;

die "please set the RIAK_PBC_HOST variable" unless $ENV{RIAK_PBC_HOST}; 

my ($host, $port) = split ':', $ENV{RIAK_PBC_HOST};

my $riak_light_client = Riak::Light->new(host => $host, port => $port);

my $net_riak_client = Net::Riak->new(
    transport => 'PBC',
    host => $host,
    port => $port
);
my $net_riak_bucket = $net_riak_client->bucket('foo_net_riak');

my $hash = { baz => 1024, boom => [1,2,3,4,5,1000] };

sub test_riak_light {
  my $key = "key" . int(rand(1024));
  $riak_light_client->put(foo_riak_light => $key, $hash);
  $riak_light_client->get(foo_riak_light => $key),
}

sub test_net_riak {
  my $key = "key" . int(rand(1024));
  $net_riak_bucket->new_object($key, $hash)->store;
  $net_riak_bucket->get($key)->data;
}

cmpthese(5_000, {
  "Riak::Light" => \&test_riak_light,
  "Net::Riak" => \&test_net_riak
});

__END__

using a local riak

$ perl -I ./lib benchmarks/simple.pl 
              Rate   Net::Riak Riak::Light
Net::Riak    479/s          --        -78%
Riak::Light 2165/s        352%          --
