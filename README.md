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

Only GET

                              Rate Data::Riak (REST) Net::Riak (REST) Riak::Tiny (REST) Data::Riak::Fast (REST) Net::Riak (PBC) Riak::Light (PBC)
    Data::Riak (REST)        304/s                --             -30%              -38%                    -39%            -64%              -91%
    Net::Riak (REST)         433/s               43%               --              -12%                    -12%            -48%              -87%
    Riak::Tiny (REST)        494/s               63%              14%                --                     -0%            -41%              -85%
    Data::Riak::Fast (REST)  495/s               63%              14%                0%                      --            -41%              -85%
    Net::Riak (PBC)          837/s              176%              93%               69%                     69%              --              -75%
    Riak::Light (PBC)       3306/s              988%             663%              569%                    568%            295%                --

Only PUT

                              Rate Net::Riak (REST) Data::Riak (REST) Riak::Tiny (REST) Net::Riak (PBC) Data::Riak::Fast (REST) Riak::Light (PBC)
    Net::Riak (REST)         389/s               --              -16%              -26%            -57%                    -59%              -89%
    Data::Riak (REST)        462/s              19%                --              -13%            -48%                    -51%              -87%
    Riak::Tiny (REST)        528/s              36%               14%                --            -41%                    -44%              -85%
    Net::Riak (PBC)          897/s             131%               94%               70%              --                     -5%              -75%
    Data::Riak::Fast (REST)  943/s             143%              104%               79%              5%                      --              -74%
    Riak::Light (PBC)       3604/s             827%              680%              582%            302%                    282%                --

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
 