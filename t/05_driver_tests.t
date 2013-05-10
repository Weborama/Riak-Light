use Test::More tests => 2;
use Test::Exception;
use Test::MockObject;
use Riak::Light::Driver;
use POSIX qw(ETIMEDOUT);

subtest "should call perform_request and return a valid value" => sub {
    plan tests => 1;
    my $mock = Test::MockObject->new;

    my $driver = Riak::Light::Driver->new( connector => $mock );

    $mock->set_true ('perform_request');
    $mock->mock( read_response => sub { pack( 'c a*', 2, q(lol) ) } );

    $driver->perform_request( body => q(), code => 1 );
    is_deeply(
        $driver->read_response(),
        { error => undef, code => 2, body => q(lol) }
    );
};

subtest "should call perform_request and return a valid value" => sub {
    plan tests => 1;
    my $mock = Test::MockObject->new;

    my $driver = Riak::Light::Driver->new( connector => $mock );

    $mock->set_true ('perform_request');
    $mock->set_false( 'read_response' );
    $! = ETIMEDOUT;
    
    $driver->perform_request( body => q(), code => 1 );
    is_deeply(
        $driver->read_response(),
        { error => 'Operation timed out', code => -1, body => undef }
    );
};
