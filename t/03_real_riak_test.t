use Test::More tests => 3;
use Test::Exception;
use Riak::Light;

SKIP: {
  skip("variable RIAK_PBC_HOST is not defined", 3) 
    unless $ENV{RIAK_PBC_HOST};
    
  my ($host, $port) = split ':', $ENV{RIAK_PBC_HOST};
  
  my $client = Riak::Light->new(host => $host, port => $port);
  
  my $hash = { baz => 1024 };
  
  ok($client->put(foo => "bar", $hash)       , "should store the hashref in Riak");
  is_deeply($client->get(foo => 'bar'), $hash, "should fetch the stored hashref from Riak");
  ok($client->del(foo => 'bar')              , "should delete the hashref");
}