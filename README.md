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
    blib/lib/Riak/Light.pm        100.0   96.2  100.0  100.0    0.0   36.6   92.4
    ...b/Riak/Light/Connector.pm  100.0   85.7    n/a  100.0    0.0   17.9   94.8
    .../lib/Riak/Light/Driver.pm  100.0   83.3    n/a  100.0    0.0   14.5   93.3
    blib/lib/Riak/Light/PBC.pm    100.0    n/a    n/a  100.0    n/a   26.2  100.0
    ...lib/Riak/Light/Timeout.pm  100.0    n/a    n/a  100.0    n/a    1.2  100.0
    ...ak/Light/Timeout/Alarm.pm  100.0    n/a    n/a  100.0    0.0    1.4   96.0
    ...k/Light/Timeout/Select.pm  100.0    n/a    n/a  100.0    0.0    0.7   89.2
    ...t/Timeout/SelectOnRead.pm  100.0    n/a    n/a  100.0    0.0    0.9   89.5
    ...ght/Timeout/SetSockOpt.pm  100.0   50.0   33.3  100.0    0.0    0.5   85.0
    Total                         100.0   86.5   63.6  100.0    0.0  100.0   91.7
    ---------------------------- ------ ------ ------ ------ ------ ------ ------


Simple Benchmark
================

Only GET (`benchmark/compare_all_only_get.pl`)

                              Rate Data::Riak (REST) Net::Riak (REST) Riak::Tiny (REST) Data::Riak::Fast (REST) Net::Riak (PBC) Riak::Light (PBC)
    Data::Riak (REST)        304/s                --             -30%              -38%                    -39%            -64%              -91%
    Net::Riak (REST)         433/s               43%               --              -12%                    -12%            -48%              -87%
    Riak::Tiny (REST)        494/s               63%              14%                --                     -0%            -41%              -85%
    Data::Riak::Fast (REST)  495/s               63%              14%                0%                      --            -41%              -85%
    Net::Riak (PBC)          837/s              176%              93%               69%                     69%              --              -75%
    Riak::Light (PBC)       3306/s              988%             663%              569%                    568%            295%                --

Only PUT (`benchmark/compare_all_only_put.pl`)

                              Rate Net::Riak (REST) Data::Riak (REST) Riak::Tiny (REST) Net::Riak (PBC) Data::Riak::Fast (REST) Riak::Light (PBC)
    Net::Riak (REST)         389/s               --              -16%              -26%            -57%                    -59%              -89%
    Data::Riak (REST)        462/s              19%                --              -13%            -48%                    -51%              -87%
    Riak::Tiny (REST)        528/s              36%               14%                --            -41%                    -44%              -85%
    Net::Riak (PBC)          897/s             131%               94%               70%              --                     -5%              -75%
    Data::Riak::Fast (REST)  943/s             143%              104%               79%              5%                      --              -74%
    Riak::Light (PBC)       3604/s             827%              680%              582%            302%                    282%                --

Timeout Providers (`benchmark/compare_timeout_providers.pl`)

                    Rate Riak::Light 2 Riak::Light 3 Riak::Light 6 Riak::Light 4 Riak::Light 5 Riak::Light 1
    Riak::Light 2 2410/s            --          -19%          -21%          -23%          -34%          -36%
    Riak::Light 3 2985/s           24%            --           -2%           -5%          -19%          -20%
    Riak::Light 6 3053/s           27%            2%            --           -3%          -17%          -18%
    Riak::Light 4 3150/s           31%            6%            3%            --          -14%          -16%
    Riak::Light 5 3670/s           52%           23%           20%           17%            --           -2%
    Riak::Light 1 3738/s           55%           25%           22%           19%            2%            --

    1 - no timeout provider (default)
    2 - using Riak::Light::Timeout::Alarm  (based on Time::Out and Time::HiRes)
    3 - using Riak::Light::Timeout::Select (based on IO::Select)
    4 - using Riak::Light::Timeout::SelectOnRead (based on IO::Select only in read operations)
    5 - using Riak::Light::Timeout::SetSockOpt (EXPERIMENTAL)
    6 - just call get inside Time::Out timeout

Features
========

* be PBC only (ok)
* supports timeout (ok)
* use Moo (ok)
* doesn't create an object per key (ok)
* support an option to not die, but return undef (ok)
* be optimized for speed. (in progress)
* try to get 100% coverage. (ok)
* benchmark with Data::Riak, Net::Riak REST, etc... (ok)
* documentation (in progress)
 