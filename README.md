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
     blib/lib/Riak/Light.pm        100.0  100.0  100.0  100.0    0.0   10.2   93.2
     ...b/Riak/Light/Connector.pm  100.0   85.7    n/a  100.0    0.0   47.9   94.8
     .../lib/Riak/Light/Driver.pm  100.0   83.3    n/a  100.0    0.0    5.1   93.3
     blib/lib/Riak/Light/PBC.pm    100.0    n/a    n/a  100.0    n/a   10.8  100.0
     ...lib/Riak/Light/Timeout.pm  100.0    n/a    n/a  100.0    n/a    0.5  100.0
     ...ak/Light/Timeout/Alarm.pm   90.9   75.0    n/a  100.0    0.0   12.7   86.2
     ...k/Light/Timeout/Select.pm   87.5   75.0    n/a  100.0    0.0   12.8   80.0
     Total                          96.4   88.7  100.0  100.0    0.0  100.0   90.5
     ---------------------------- ------ ------ ------ ------ ------ ------ ------

    
Simple Benchmark
================

                         Rate Net::Riak only get Riak::Light 2 Riak::Light 3 Riak::Light 5 Riak::Light 4 Riak::Light 1
    Net::Riak only get  993/s                 --          -59%          -67%          -68%          -69%          -73%
    Riak::Light 2      2395/s               141%            --          -19%          -24%          -26%          -35%
    Riak::Light 3      2963/s               199%           24%            --           -6%           -8%          -20%
    Riak::Light 5      3150/s               217%           31%            6%            --           -2%          -15%
    Riak::Light 4      3226/s               225%           35%            9%            2%            --          -13%
    Riak::Light 1      3704/s               273%           55%           25%           18%           15%            --
    ------------------------------------------------------------------------------------------------------------------
    Riak::Light 1 - (DEFAULT) uses nothing to set timeout in input/output operations (like Net::Riak)
    Riak::Light 2 - uses Time::Out in input/output operations
    Riak::Light 3 - uses IO::Select in input/output operations
    Riak::Light 4 - uses IO::Select in input operations
    Riak::Light 5 - a simple wrap in (1) using Time::Out::timeout 0.5 => sub { $client->get(...) }    
  
Features
========

* be PBC only (ok)
* supports timeout (ok)
* use Moo (ok)
* doesn't create an object per key (ok)
* support an option to not die, but return undef (ok)
* be optimized for speed. (in progress)
* try to get 100% coverage. (in progress, 96.4%)
* benchmark with Data::Riak, Net::Riak REST, etc... (in progress)
* documentation (in progress)
 