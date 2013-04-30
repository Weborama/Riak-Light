Riak-Light
==========

Fast and lightweight Perl client for Riak

    # create a new instance - using pbc only
    my $client = Riak::Light->new(
      host => '127.0.0.1',
      port => 8087
    );

    # store hashref into bucket 'foo', key 'bar'
    $client->put( foo => bar => { baz => 1024 })
      or die "ops... " . $client->last_error;

    # fetch hashref from bucket 'foo', key 'bar'
    my $hash = $client->get( foo => 'bar');

    # delete hashref from bucket 'foo', key 'bar'
    $client->del(foo => 'bar');
