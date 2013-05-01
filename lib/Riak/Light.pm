## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light;
## use critic
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;
use IO::Socket;
use Riak::Light::PBC;
use Riak::Light::Driver;
use JSON;
use Scalar::Util qw(blessed);
require bytes;

# ABSTRACT: Fast and lightweight Perl client for Riak

# TODO: refactor based on "BUILDARGS" ?
has port    => (is => 'ro', isa => Int,  required => 1);
has host    => (is => 'ro', isa => Str,  required => 1);
has timeout => (is => 'ro', isa => Num,  default  => sub { 0.5 });

has autodie => (is => 'ro', isa => Bool, default  => sub { 0 });

has r       => ( is => 'ro', isa => Int, default => sub { 2 });
has w       => ( is => 'ro', isa => Int, default => sub { 2 });
has rw      => ( is => 'ro', isa => Int, default => sub { 2 });

has last_error => (
  is => 'rwp', 
  clearer => 1,
  predicate => 1,
  default => sub { undef }
);

has driver  => (
  is => 'lazy',
);

sub _build_driver {
  my $self = shift;
  Riak::Light::Driver->new(
    port => $self->port, 
    host => $self->host, 
    timeout => $self->timeout
  )
}

my %decoder = (
  0 =>  'RpbErrorResp',
  10 => 'RpbGetResp',
);

sub get {
  my ($self, $bucket, $key) = @_;
  
  my $request = RpbGetReq->encode({ 
    r => $self->r,
    key => $key,
    bucket => $bucket
  });
  my $request_code = 9;
  my $response_code = 10;
  
  my ($code, $encoded_message, $error) = $self->driver->perform_request($request_code, $request);
  
  my $decoded_message;
  
  if( exists $decoder{$code} ){
    $decoded_message = $decoder{$code}->decode($encoded_message);
  }
  
  return decode_json($decoded_message->content->[0]->value)
    if ! defined $error
    and $code == $response_code
    and $decoded_message 
    and blessed $decoded_message
    and defined $decoded_message->content
    and defined $decoded_message->content->[0]
    and defined $decoded_message->content->[0]->value;
  
  $self->clear_last_error();
  $self->_set_last_error("unexpected response code") unless $code == $response_code;
  $self->_set_last_error($error) if defined($error);
    
  undef
}

sub put {
  my ($self, $bucket, $key, $value) = @_;
  
  my $request = RpbPutReq->encode({ 
    key => $key,
    bucket => $bucket,    
    content => {
      content_type => 'application/json',
      value => encode_json($value)
    },
  });
  
  my $request_code = 11; # request 11 => PUT, response 12 => PUT
  
  my ($code, $encoded_message, $error) = $self->driver->perform_request($request_code, $request);
  
  $code == 12
}

sub del {
  my ($self, $bucket, $key) = @_;
  
  my $request = RpbDelReq->encode({ 
    key => $key,
    bucket => $bucket,
    dw => $self->rw
  });
  
  my $request_code = 13; # request 13 => DEL, response 14 => DEL

  my ($code, $encoded_message, $error) = $self->driver->perform_request($request_code, $request);
  
  $code == 14
}


1;

=head1 NAME

  Riak::Light - Fast and lightweight Perl client for Riak

=head1 SYNOPSIS

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