use Test::More tests => 8;
use Test::Exception;
use Test::MockObject;
use Riak::Light::Socket;
use Test::TCP;


subtest "should not die if can connect" => sub {
  plan tests => 1;

  my $server = Test::TCP->new(
    code => sub {
      my $port = shift;    
      my $socket = IO::Socket::INET->new(
        Listen => 5,
        Timeout => 1,
        Reuse => 1,
        LocalPort => $port) or die "ops $!";

      while(1){
        $socket->accept()->close();   
      }
    },
  );
  
  lives_ok { 
    Riak::Light::Socket->new(
      host => '127.0.0.1', 
      port => $server->port
    ) 
  };
};

subtest "should die if cant connect" => sub {
  plan tests => 1;
  
  throws_ok { 
    Riak::Light::Socket->new(
      host => 'do.not.exist', 
      port => 9999
    ) } qr/Error \(.*\), can't connect to do.not.exist:9999/;
};

subtest "should send all bytes" => sub { 
  plan tests => 1;
  my $mock   = Test::MockObject->new;
  
  my $bytes = pack('N a*', 1, 'foo');
  
  $mock->set_always(syswrite => bytes::length($bytes));
  
  my $socket = Riak::Light::Socket->new(host => 'host', port => 1234, socket => $mock);
  
  ok($socket->send_all($bytes));
};

subtest "should return false in case of error" => sub { 
  plan tests => 1;
  my $mock   = Test::MockObject->new;
  
  my $bytes = pack('N a*', 1, 'foo');
  
  $mock->set_always(syswrite => undef);
  
  my $socket = Riak::Light::Socket->new(host => 'host', port => 1234, socket => $mock);
  
  ok(! $socket->send_all($bytes));
};

subtest "should return false in case of EOF" => sub { 
  plan tests => 1;
  my $mock   = Test::MockObject->new;
  
  my $bytes = pack('N a*', 1, 'foo');
  
  $mock->set_always(syswrite => 0);
  
  my $socket = Riak::Light::Socket->new(host => 'host', port => 1234, socket => $mock);
  
  ok(! $socket->send_all($bytes));
};

subtest "should read all bytes" => sub { 
  plan tests => 1;
  my $mock   = Test::MockObject->new;
  
  my $bytes = pack('N a*', 2, 'foo');
  
  $mock->mock(sysread => sub {
    $_[1] = $bytes;
    
    bytes::length($bytes)
  });
  
  my $socket = Riak::Light::Socket->new(host => 'host', port => 1234, socket => $mock);
  
  is($socket->read_all(bytes::length($bytes)), $bytes);
};

subtest "should return false in case of error" => sub { 
  plan tests => 1;
  my $mock   = Test::MockObject->new;
  
  my $bytes = pack('N a*', 2, 'foo');
  
  $mock->set_always(sysread => undef);
  
  my $socket = Riak::Light::Socket->new(host => 'host', port => 1234, socket => $mock);
  
  ok(! $socket->read_all(bytes::length($bytes)));
};

subtest "should return false in case of EOF" => sub { 
  plan tests => 1;
  my $mock   = Test::MockObject->new;
  
  my $bytes = pack('N a*', 2, 'foo');
  
  $mock->set_always(sysread => 0);
  
  my $socket = Riak::Light::Socket->new(host => 'host', port => 1234, socket => $mock);
  
  ok(! $socket->read_all(bytes::length($bytes)));
};