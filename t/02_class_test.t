use Test::More tests => 7;
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
  is($client->r,  2, "default r  should be 2");
  is($client->w,  2, "default w  should be 2");  
  is($client->rw, 2, "default rw should be 2");
  ok(! $client->last_error, "default last_error should be undef");    
  ok(! $client->autodie, "default autodie shoudl be false");
};

subtest "new and other attrs values" => sub {
  my $client = new_ok('Riak::Light' => [ 
    host => '127.0.0.1', 
    port => 8087, 
    timeout => 0.2, 
    autodie => 1,
    r => 1, w => 1, rw => 1
  ], "a new client");
  is($client->timeout, 0.2, "timeout should be 0.2");
  is($client->r,  1, "r  should be 1");
  is($client->w,  1, "w  should be 1");  
  is($client->rw, 1, "rw should be 1");  
  ok($client->autodie, "autodie should be true");
};

SKIP: {
  skip("variable RIAK_PBC_HOST is not defined", 1) 
    unless $ENV{RIAK_PBC_HOST};
  
  my ($host, $port) = split ':', $ENV{RIAK_PBC_HOST};
  
  isa_ok(Riak::Light->new(host => $host, port => $port)->driver, 'Riak::Light::Driver');
};

ok(! Riak::Light->new(host => 'not.exist', port => 9999)->driver->socket, 'should return undef');