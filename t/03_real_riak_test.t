use Test::More tests => 3;
use Riak::Light;

SKIP: {
  skip("variable RIAK_PBC_HOST is not defined", 2) 
    unless $ENV{RIAK_PBC_HOST};

  subtest "simple get/set/delete test" => sub {
    plan tests => 5;
  
    my ($host, $port) = split ':', $ENV{RIAK_PBC_HOST};
  
    my $client = Riak::Light->new(host => $host, port => $port);
  
    my $hash = { baz => 1024 };
  
    ok( $client->put(foo => "bar", $hash)      , "should store the hashref in Riak");
    is_deeply($client->get(foo => 'bar'), $hash, "should fetch the stored hashref from Riak");
    ok( $client->del(foo => 'bar')             , "should delete the hashref");
    ok(!$client->get(foo => 'bar')             , "should fetch UNDEF from Riak");
  
    ok(!$@, "should has no error - foo => bar is undefined");  
  };

  subtest "sequence of 1024 get/set" => sub {
    plan tests => 1024;

    my ($host, $port) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Light->new(host => $host, port => $port);

    my $hash = {
      foo => bar => baz => 123,
      something => very => complex => [1,2,3,4,5] 
    };

    my ($bucket, $key);      
    for(1..1024){
      ($bucket, $key) = ( "bucket" . int(rand(1024)), "key" . int(rand(1024)) );

      $hash->{random} = int(rand(1024));

      $client->put( $bucket => $key => $hash);

      my $got_complex_structure = $client->get( $bucket => $key );
      is_deeply($got_complex_structure, $hash, "get($bucket=>$key)should got the same structure");    
    }
  };
  
}

subtest "error handling" => sub {
  plan tests => 3;
  my $client2 = Riak::Light->new(host => 'not.exist', port => 9999);  

  ok(!$client2->get(foo => 'bar')             , "should return undef - it is an error");
  ok( $@,   "should has error - could not connect");
  is( $@,   "Error: Invalid argument for host not.exist, port 9999");  
};