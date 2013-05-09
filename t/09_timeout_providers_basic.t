use Test::More tests => 4;
use Test::Exception;
use Test::MockObject;
use Riak::Light;
use Test::TCP;

subtest "should not die if can connect using a timeout::alarm as a timeout provider" => sub {
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
    Riak::Light->new(
      host => '127.0.0.1', 
      port => $server->port,
      timeout_provider => 'Riak::Light::Timeout::Alarm'
    ) 
  };
};

subtest "should not die if can connect using a timeout::select as a timeout provider" => sub {
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
    Riak::Light->new(
      host => '127.0.0.1', 
      port => $server->port,
      timeout_provider => 'Riak::Light::Timeout::Select'
    ) 
  };
};

subtest "should not die if can connect using a timeout::select as a timeout provider" => sub {
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
    Riak::Light->new(
      host => '127.0.0.1', 
      port => $server->port,
      timeout_provider => 'Riak::Light::Timeout::SelectOnRead'
    ) 
  };
};

subtest "should not die if can connect using a timeout::select as a timeout provider" => sub {
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
    Riak::Light->new(
      host => '127.0.0.1', 
      port => $server->port,
      timeout_provider => 'Riak::Light::Timeout::SetSockOpt'
    ) 
  };
};