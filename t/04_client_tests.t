use Test::More tests => 5;
use Test::Exception;
use Test::MockObject;
use Riak::Light;
use Riak::Light::PBC;
use JSON;

subtest "error handling" => sub {
  plan tests => 1;
  
  dies_ok { 
    Riak::Light->new(host => 'not.exist', port => 9999)
  };
};

subtest "ping" => sub {
  plan tests => 4;
  
  subtest "pong should return true in case of sucess" => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $mock_response = {
      error => undef,
      code => 2,
      body => q()
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    ok $client->ping(), "should return true";
  };
  
  subtest "ping should die in case of internal error" => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $mock_response = {
      error => "some error"
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    throws_ok { $client->ping() } qr/Error in 'ping' : some error/, "should die";
  };

  subtest "ping should die in case of riak error" => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $mock_response = {
      error => undef,
      code => 0,
      body => RpbErrorResp->encode({errmsg => "some riak error", errcode => 123})
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    throws_ok { $client->ping() } qr/Error in 'ping' : Riak Error \(code: 123\) 'some riak error'/, "should die";
  };
  
  subtest "ping should die in case of unexpected response" => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $mock_response = {
      error => undef,
      code => 10,
      body => q()
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    throws_ok { $client->ping() } qr/Error in 'ping' : Unexpected Response Code in \(got: 10, expected: 2\)/, "should die";
  };  
};

subtest "get" => sub {
  plan tests => 5;
  
  subtest "get fetch simple value " => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $hash   = { lol => 123 };  

    my $mock_response = {
      error => undef,
      code => 10,
      body => RpbGetResp->encode( { 
        content=> { 
          value => encode_json($hash),
          content_type => 'application/json'
        }
      })
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    is_deeply($client->get(foo => "bar"), $hash, "should return the same structure");    
  };
  
  subtest "get fetch simple text/plain value " => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $text   = "LOL";  

    my $mock_response = {
      error => undef,
      code => 10,
      body => RpbGetResp->encode( { 
        content=> { 
          value => $text,
          content_type => 'text/plain'
        }
      })
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    is($client->get(foo => "bar"), $text, "should return the same structure");    
  };  
  
  subtest "get fetch undef value" => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $mock_response = {
      error => undef,
      code => 10,
      body => RpbGetResp->encode( { 
        content=> undef
      })
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    ok(! $client->get(foo => "bar"), "should return nothing");    
  };
  
  subtest "get fetch undef body should die" => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $mock_response = {
      error => undef,
      code => 10,
      body => undef
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    throws_ok { $client->get(foo => "bar") } qr/Error in 'get' \(bucket: foo, key: bar\): Undefined Message/, "should return nothing";    
  };

  subtest "get fetch dies in case of error" => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $mock_response = {
      error => "some error"
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    throws_ok { $client->get(foo => "bar") } qr/Error in 'get' \(bucket: foo, key: bar\): some error/, "should die";
  };  
};
subtest "put" => sub {
  plan tests => 3;
  
  subtest "put simple data " => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $mock_response = {
      error => undef,
      code => 12,
      body => q()
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    my $hash = { foo => 123 };
    ok($client->put(foo => "bar", $hash), "should store data");    
  };
  
  subtest "put simple datain text/plain" => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $mock_response = {
      error => undef,
      code => 12,
      body => q()
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    my $hash = { foo => 123 };
    ok($client->put(foo => "bar", $hash, 'text/plain'), "should store data");    
  };
  
  
  subtest "put should die in case of error " => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;
    
    my $mock_response = {
      error => "some error"
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);
    my $hash = { foo => 123 };
    throws_ok { $client->put(foo => "bar", $hash) } qr/Error in 'put' \(bucket: foo, key: bar\): some error/, "should die";
  };  
};  
subtest "del" => sub {
  plan tests => 2;
  
  subtest "del simple data " => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $mock_response = {
      error => undef,
      code => 14,
      body => q()
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    ok($client->del(foo => "bar"), "should delete data");    
  };
  
  subtest "del should die in case of error " => sub {
    plan tests => 1;
    my $mock   = Test::MockObject->new;

    my $mock_response = {
      error => "some error"
    };

    $mock->set_always(perform_request => $mock_response);

    my $client = Riak::Light->new(host => 'host', port => 1234, autodie => 1, driver => $mock);

    throws_ok { $client->del(foo => "bar") } qr/Error in 'del' \(bucket: foo, key: bar\): some error/, "should die";
  };
};