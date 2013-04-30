use Test::More tests => 6;
use Test::Exception;
use Riak::Light;

dies_ok { Riak::Light->new } "should ask for port and host";
dies_ok { Riak::Light->new(host => '127.0.0.1') } "should ask for port";
dies_ok { Riak::Light->new(port => 8087) } "should ask for host";

subtest "new and default attrs values" => sub {
  my $client = new_ok('Riak::Light' => [ 
    host => '127.0.0.1', 
    port => 8087 
  ], "a new client");
  is($client->timeout, 0.5, "default timeout should be 0.5");
  ok(! $client->autodie, "default autodie shoudl be false");
};

subtest "new and other attrs values" => sub {
  my $client = new_ok('Riak::Light' => [ 
    host => '127.0.0.1', 
    port => 8087, 
    timeout => 0.2, 
    autodie => 1 
  ], "a new client");
  is($client->timeout, 0.2, "default timeout should be 0.2");
  ok($client->autodie, "autodie should be true");
};

SKIP: {
  skip("variable RIAK_PBC_HOST is not defined", 1) 
    unless $ENV{RIAK_PBC_HOST};
  
  my ($host, $port) = split ':', $ENV{RIAK_PBC_HOST};
  
  isa_ok(Riak::Light->new(host => $host, port => $port)->socket, 'IO::Socket');
};