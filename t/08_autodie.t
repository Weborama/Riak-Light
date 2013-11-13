use Test::More tests => 1;
use Test::Exception;
use Test::MockObject;
use Riak::Light;
use Riak::Light::PBC;

subtest "should die (default)" => sub {
    plan tests => 1;

    my $mock = Test::MockObject->new;

    my $client = Riak::Light->new(
        host   => 'host', port => 1234,
        driver => $mock
    );
    $mock->set_true('perform_request');
    $mock->set_always( read_response => { error => "ops" } );
    throws_ok { $client->ping } qr/Error in 'ping' : ops/, "should die";
};
