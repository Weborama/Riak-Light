BEGIN {
    unless ( $ENV{RIAK_PBC_HOST} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'variable RIAK_PBC_HOST is not defined' );
    }
}

use Test::More tests => 1;
use Test::Differences;
use Test::Exception;
use Riak::Light;
use JSON;

subtest "map reduce" => sub {
    plan tests => 5;
  
    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Light->new(
        host             => $host, port => $port,
        timeout_provider => undef
    );

    ok( $client->ping(),     "should can ping" );
    
    my $keys = $client->get_keys('training');
    
    foreach my $key ( @{ $keys }){
      $client->del( training => $key);
    }
    
    $client->put( training => foo => 'pizza data goes here' ,'text/plain');
    $client->put( training => bar => 'pizza pizza pizza pizza' ,'text/plain');
    $client->put( training => baz => 'nothing to see here' ,'text/plain');
    $client->put( training => bam => 'pizza pizza pizza' ,'text/plain');
    
    my %expected = (
      'bar' => 4,
#      'baz' => 0,
      'bam' => 3,
      'foo' => 1,
    );
    
    
    my $json_hash = {
        inputs => "training",
        query => [{
          map => {
            language =>"javascript",
            source =>"function(riakObject) {
              var val = riakObject.values[0].data.match(/pizza/g);
              return [[riakObject.key, (val ? val.length : 0 )]];
            }"
          }
        }]
      };
    
    my $json_string = '{
        "inputs":"training",
        "query":[{"map":{"language":"javascript",
        "source":"function(riakObject) {
          var val = riakObject.values[0].data.match(/pizza/g);
          return [[riakObject.key, (val ? val.length : 0 )]];
        }"}}]}';  
        
    foreach my $json_query ( $json_string, $json_hash ){
      my $response = $client->map_reduce($json_query);

      # will return something like
      #[
      #  {'response' => [['foo',1]],'phase' => 0},
      #  {'response' => [['bam',3]],'phase' => 0},
      #  {'response' => [['bar',4]],'phase' => 0},
      #  {'response' => [['baz',0]],'phase' => 0}
      #]
      # now map the key => value

      my %got = map { 
          $_->{response}->[0]->[0] => $_->{response}->[0]->[1]
      } @{ $response };

      my $zero = delete $got{'baz'};

      ok (! $zero, 'baz should be zero or undef');
      eq_or_diff \%got , \%expected, "should return the proper data structure for query as: " 
        . ((ref $json_query) ? "reference" : "string") ;      
    }
};
