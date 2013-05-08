use Test::More tests => 2;
use Test::Exception;
use Test::MockObject;
use Riak::Light::Driver;
use POSIX qw(ETIMEDOUT);

subtest "should call perform_request and return a valid value" => sub { 
  plan tests => 1;
  my $mock   = Test::MockObject->new;
          
  my $driver = Riak::Light::Driver->new(connector => $mock);
  
  $mock->mock(perform_request => sub{ pack('c a*', 2, q(lol))});
  
  is_deeply($driver->perform_request(body => q(), code => 1), {error => undef, code => 2, body => q(lol)});
};

subtest "should call perform_request and return a valid value" => sub { 
  plan tests => 1;
  my $mock   = Test::MockObject->new;
          
  my $driver = Riak::Light::Driver->new(connector => $mock);
  
  $mock->set_always(perform_request => undef);
  $!= ETIMEDOUT;
  is_deeply($driver->perform_request(body => q(), code => 1), {error => 'Operation timed out', code => undef, body => undef});
};