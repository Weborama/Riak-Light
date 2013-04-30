use Test::More tests => 8;
use Riak::Light;

SKIP: {
  skip("variable RIAK_PBC_HOST is not defined", 5) 
    unless $ENV{RIAK_PBC_HOST};
    
  my ($host, $port) = split ':', $ENV{RIAK_PBC_HOST};
  
  my $client = Riak::Light->new(host => $host, port => $port);
  
  my $hash = { baz => 1024 };
  
  ok( $client->put(foo => "bar", $hash)      , "should store the hashref in Riak");
  is_deeply($client->get(foo => 'bar'), $hash, "should fetch the stored hashref from Riak");
  ok( $client->del(foo => 'bar')             , "should delete the hashref");
  ok(!$client->get(foo => 'bar')             , "should fetch UNDEF from Riak");
  ok(!$client->has_last_error,               , "should has no error - foo => bar is undefined");
}

my $client2 = Riak::Light->new(host => 'not.exist', port => 9999);  
  
ok(!$client2->get(foo => 'bar')             , "should return undef - it is an error");
ok( $client2->has_last_error,               , "should has error - could not connect");
is( $client2->last_error,    "Error: Invalid argument for host not.exist, port 9999");  