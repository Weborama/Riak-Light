use Test::More tests => 7;
use Test::Exception;
use Test::MockObject;
use Riak::Light;
use Test::TCP;
require bytes;

sub create_server_with_timeout {
  my $in_timeout = shift;
  my $out_timeout = shift;
  
  Test::TCP->new(
    code => sub {
      my $port = shift;    
      my $socket = IO::Socket::INET->new(
        Listen => 5,
        Timeout => 1,
        Reuse => 1,
        Blocking => 1,
        LocalPort => $port) or die "ops $!";

      my $message = pack('c',2);
        
      my $buffer;  
      while(1){
        my $client = $socket->accept();
        
        sleep($in_timeout) if $in_timeout;
        my $x = $client->sysread($buffer,5);
        
        if($x){
          sleep($out_timeout) if $out_timeout;
          my $response = pack('N a*', bytes::length($message),$message);
          
          $client->syswrite( $response );
          sleep(1);
        }
        
        $client->close();
      }
    },
  )
}

subtest "should die if wait more than in_timeout" => sub {
  plan tests => 2;

  my $server = create_server_with_timeout(0,2);
  
  my $client = Riak::Light->new(
      host => '127.0.0.1', 
      port => $server->port,
      in_timeout => 0.1,
      timeout_provider => 'Riak::Light::Timeout::Select'
    );
      
  throws_ok { $client->ping() } qr/Error in 'ping' : Operation timed out/,      "should die in case of timeout";
  throws_ok { $client->ping() } qr/Error in 'ping' : Connection reset by peer/, "should close the connection";
};

subtest "should die if wait more than out_timeout" => sub {
  plan tests => 2;

  my $server = create_server_with_timeout(2,0);
  
  my $client = Riak::Light->new(
      host => '127.0.0.1', 
      port => $server->port,
      out_timeout => 0.1,
      timeout_provider => 'Riak::Light::Timeout::Select'
    );
      
  throws_ok { $client->ping() } qr/Error in 'ping' : Operation timed out/,      "should die in case of timeout";
  throws_ok { $client->ping() } qr/Error in 'ping' : Connection reset by peer/, "should close the connection";
};

subtest "should die if wait more than in_timeout" => sub {
  plan tests => 2;

  my $server = create_server_with_timeout(0,2);
  
  my $client = Riak::Light->new(
      host => '127.0.0.1', 
      port => $server->port,
      in_timeout => 0.1,
      timeout_provider => 'Riak::Light::Timeout::Alarm'
    );
      
  throws_ok { $client->ping() } qr/Error in 'ping' : Operation timed out/, "should die in case of timeout";
  throws_ok { $client->ping() } qr/Error in 'ping' : Connection reset by peer/, "should close the connection";
};

subtest "should die if wait more than out_timeout" => sub {
  plan tests => 2;

  my $server = create_server_with_timeout(2,0);
  
  my $client = Riak::Light->new(
      host => '127.0.0.1', 
      port => $server->port,
      out_timeout => 0.1,
      timeout_provider => 'Riak::Light::Timeout::Alarm'
    );
      
  throws_ok { $client->ping() } qr/Error in 'ping' : Operation timed out/, "should die in case of timeout";
  throws_ok { $client->ping() } qr/Error in 'ping' : Connection reset by peer/, "should close the connection";
};

subtest "should not die without a timeout provider" => sub {
  plan tests => 1;

  my $server = create_server_with_timeout(0,2);
  
  my $client = Riak::Light->new(
      host => '127.0.0.1', 
      port => $server->port,
      in_timeout => 0.1,      
      timeout_provider => 'IO::Socket::INET'
    );
      
  lives_ok { $client->ping() } "should wait";
};


subtest "should not die with a timeout provider based on Select" => sub {
  plan tests => 1;

  my $server = create_server_with_timeout(0,0);
  
  my $client = Riak::Light->new(
      host => '127.0.0.1', 
      port => $server->port,
      timeout => 2,      
      timeout_provider => 'Riak::Light::Timeout::Select'
    );
      
  lives_ok { $client->ping() } "should wait";
};

subtest "should not die with a timeout provider based on Alarm" => sub {
  plan tests => 1;

  my $server = create_server_with_timeout(0,0);
  
  my $client = Riak::Light->new(
      host => '127.0.0.1', 
      port => $server->port,
      timeout => 2,  
      timeout_provider => 'Riak::Light::Timeout::Alarm'
    );
      
  lives_ok { $client->ping() } "should wait";
};