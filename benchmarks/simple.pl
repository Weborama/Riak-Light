use strict;
use warnings;
use Benchmark::Forking qw(timethis timethese cmpthese);

use Net::Riak;
use Riak::Light;

=head1 BENCHMARK

# using a local riak

$ perl -I ./lib benchmarks/simple.pl

                       Rate Net::Riak get/set Net::Riak only get Riak::Light get/set Riak::Light only get
Net::Riak get/set     486/s                --               -53%                -79%                 -89%
Net::Riak only get   1045/s              115%                 --                -54%                 -76%
Riak::Light get/set  2262/s              365%               117%                  --                 -49%
Riak::Light only get 4401/s              805%               321%                 95%                   --

=cut

die "please set the RIAK_PBC_HOST variable" unless $ENV{RIAK_PBC_HOST};

my $hash = { baz => 1024, boom => [1,2,3,4,5,1000] };

my ($host, $port) = split ':', $ENV{RIAK_PBC_HOST};

my $riak_light_client = Riak::Light->new(host => $host, port => $port);

sub test_riak_light_getset {
  my $key = "key" . int(rand(1024));
  $riak_light_client->put(foo_riak_light => $key, $hash);
  $riak_light_client->get(foo_riak_light => $key),
}

$riak_light_client->put(foo_riak_light => key => $hash);

sub test_riak_light_get {
  $riak_light_client->get(foo_riak_light => 'key'),
}

my $net_riak_client = Net::Riak->new(
    transport => 'PBC',
    host => $host,
    port => $port
);
my $net_riak_bucket = $net_riak_client->bucket('foo_net_riak');

sub test_net_riak_getset {
  my $key = "key" . int(rand(1024));
  $net_riak_bucket->new_object($key, $hash)->store;
  $net_riak_bucket->get($key)->data;
}

$net_riak_client->bucket('foo_net_riak')->new_object(key => $hash)->store;

sub test_net_riak_get {
  $net_riak_bucket->get('key')->data;
}

cmpthese(25_000, {
  "Riak::Light only get" => \&test_riak_light_get,
  "Net::Riak only get" => \&test_net_riak_get,
  "Riak::Light get/set" => \&test_riak_light_getset,
  "Net::Riak get/set" => \&test_net_riak_getset
});