Riak-Light
==========

Fast and lightweight Perl client for Riak

    # create a new instance - using pbc only
    my $client = Riak::Light->new(
      host => '127.0.0.1',
      port => 8087
    );

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
    blib/lib/Riak/Light.pm         93.1   64.3   42.1   91.3    0.0   31.0   79.5
    ...b/Riak/Light/Connector.pm   95.0   50.0   33.3  100.0    0.0    3.3   78.4
    .../lib/Riak/Light/Driver.pm   96.0   50.0   33.3   88.9    0.0    2.1   79.1
    blib/lib/Riak/Light/PBC.pm    100.0    n/a    n/a  100.0    n/a    2.3  100.0
    .../lib/Riak/Light/Socket.pm  100.0   60.0    n/a  100.0    0.0   61.3   88.3
    Total                          95.7   60.0   40.0   94.1    0.0  100.0   82.0
    
Simple Benchmark
================

                           Rate   Net::Riak only get Riak::Light only get
    Net::Riak only get   1017/s                   --                 -74%
    Riak::Light only get 3947/s                 288%                   --
  
Features
========

* be PBC only (ok)
* supports timeout (in progress)
* use Moo (ok)
* doesn't create an object per key (ok)
* support an option to not die, but return undef (todo)
* be optimized for speed. (in progress)
* try to get 100% coverage. (in progress)
* benchmark with Data::Riak, Net::Riak REST, etc... (todo)
 