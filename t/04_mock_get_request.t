use Test::More tests => 3;
use Test::Exception;
use Test::MockObject;
use Riak::Light;
use Riak::Light::PBC;
use JSON;
require bytes;

subtest "should fetch data" => sub {
  plan tests => 1;  
  my $mock = Test::MockObject->new();
  
  $mock->set_true('syswrite');
  
  my $hash = { baz => 1024 };
    
  my $foo = RpbGetResp->encode({
    content => { value => encode_json($hash) }
  });
  my @calls = (pack('N', bytes::length($foo)+1), pack('c', 10), $foo);
  $mock->mock(sysread => sub {
    $_[1] = shift @calls;
    
    bytes::length $_[1];
  });
  
  my $client = Riak::Light->new(host => 'host', port => 1234, socket => $mock);
  
  is_deeply($client->get(foo => 'bar'), $hash, "should fetch the stored hashref from Riak");
};

subtest "should return error if receive 1 byte less" => sub {
  plan tests => 3;
  my $mock = Test::MockObject->new();
  
  $mock->set_true('syswrite');
  
  my $hash = { baz => 1024 };
    
  my $foo = RpbGetResp->encode({
    content => { value => encode_json($hash) }
  });
  
  my @calls = (pack('N', bytes::length($foo)+1), pack('c', 10), bytes::substr($foo,0,-1), "");
  $mock->mock(sysread => sub {
    $_[1] = shift @calls;
    
    #return undef unless defined $_[1];
    
    bytes::length $_[1];
  });
  
  my $client = Riak::Light->new(host => 'host', port => 1234, socket => $mock);
  
  ok(!$client->get(foo => 'bar'), "should return undef / error");
  ok( $client->has_last_error,    "should has last error");
  is( $client->last_error,        "sysread returns EOF - probably lost connection");
};

subtest "should return error if sysread return error" => sub {
  plan tests => 3;
  my $mock = Test::MockObject->new();
  
  $mock->set_true('syswrite');
  
  my $hash = { baz => 1024 };
    
  my $foo = RpbGetResp->encode({
    content => { value => encode_json($hash) }
  });
  
  my @calls = (pack('N', bytes::length($foo)+1), pack('c', 10), undef);
  $mock->mock(sysread => sub {
    $_[1] = shift @calls;
    
    unless (defined $_[1]) {
      $! = 50; # Network is down
    }
    
    bytes::length $_[1];
  });
  
  my $client = Riak::Light->new(host => 'host', port => 1234, socket => $mock);
  
  ok(!$client->get(foo => 'bar'), "should return undef / error");
  ok( $client->has_last_error,    "should has last error");
  is( $client->last_error,        "sysread returns Error - Network is down");
};