BEGIN {
    unless ( $ENV{RIAK_PBC_HOST} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'variable RIAK_PBC_HOST is not defined' );
    }
}

use Test::More;
use Test::Exception;
use Riak::Light;
use JSON;

subtest "insert data with 2i" => sub {

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Light->new(
        host             => $host, port => $port,
        timeout_provider => undef
    );

    my $scalar = '3.14159';
    my $hash = { baz => 1024 };

    ok( $client->ping(),     "should can ping" );
    ok( $client->is_alive(), "should can ping" );
    ok( $client->put( foo => "bar", $hash, undef, { 'blah:int' => 5 } ),
        "should store the hashref in Riak"
    );

    is_deeply(
        $client->get( foo => 'bar' ), $hash,
        "should fetch the stored hashref from Riak"
    );
};


done_testing;
