Riak-Light
==========

Fast and lightweight Perl client for Riak

    # create a new instance - using pbc only
    my $client = Riak::Light->new(
      host => '127.0.0.1',
      port => 8087
    );
    
    $client->ping() or die "ops, riak is not alive";

    # store hashref into bucket 'foo', key 'bar'
    # will serializer as 'application/json'
    $client->put( foo => bar => { baz => 1024 });
    
    # store text into bucket 'foo', key 'bar'
    $client->put( foo => baz => "sometext", 'text/plain');

    # fetch hashref from bucket 'foo', key 'bar'
    my $hash = $client->get( foo => 'bar');

    # delete hashref from bucket 'foo', key 'bar'
    $client->del(foo => 'bar');

Test Coverage
=============
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/Riak/Light.pm        100.0  100.0  100.0  100.0    0.0   17.1   89.9
    ...b/Riak/Light/Connector.pm  100.0  100.0    n/a  100.0    0.0    5.7   94.7
    .../lib/Riak/Light/Driver.pm  100.0  100.0    n/a  100.0    0.0    8.2   94.9
    blib/lib/Riak/Light/PBC.pm    100.0    n/a    n/a  100.0    n/a   29.5  100.0
    .../lib/Riak/Light/Socket.pm  100.0  100.0    n/a  100.0    0.0   39.4   95.2
    Total                         100.0  100.0  100.0  100.0    0.0  100.0   92.7
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    
Simple Benchmark
================

                           Rate   Net::Riak only get Riak::Light only get
    Net::Riak only get    937/s                   --                 -75%
    Riak::Light only get 3797/s                 305%                   --
  
Features
========

* be PBC only (ok)
* supports timeout (in progress)
* use Moo (ok)
* doesn't create an object per key (ok)
* support an option to not die, but return undef (todo)
* be optimized for speed. (in progress)
* try to get 100% coverage. (ok)
* benchmark with Data::Riak, Net::Riak REST, etc... (todo)
* documentation (in progress)
 