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

around [ qw<put del get> ] => sub {
  my $orig = shift;
  my $self = shift;
    
  $self->clear_last_error();
    
  my ($code, $expected_code, $encoded_message, $error) = $self->$orig(@_);
  
  return $self->_process_error($error) if ($error);
  return $self->_process_err_response($encoded_message) if ($code == 0);
  return $self->_process_get_response($encoded_message) if ($code == 10 && $code == $expected_code);
      
  $code == $expected_code  
};

sub put {
  my ($self, $bucket, $key, $value) = @_;
      
  my $request_code = 11;
  my $expected_code = 12;  
  my $request = RpbPutReq->encode({ 
     key => $key,
     bucket => $bucket,    
     content => {
       content_type => 'application/json',
       value => encode_json($value)
     },
   });
  my ($code, $encoded_message, $error) = $self->driver->perform_request($request_code, $request);
  
  ($code, $expected_code, $encoded_message, $error)
}

sub del {
  my ($self, $bucket, $key) = @_;
    
  my $request_code = 13;
  my $expected_code = 14;  
  my $request = RpbDelReq->encode({ 
    key => $key,
    bucket => $bucket,
    dw => $self->rw
  });
  my ($code, $encoded_message, $error) = $self->driver->perform_request($request_code, $request);
  
  ($code, $expected_code, $encoded_message, $error)
}

sub get {
  my ($self, $bucket, $key) = @_;
  
  my $request_code = 9;
  my $expected_code = 10;
  my $request = RpbGetReq->encode({ 
    r => $self->r,
    key => $key,
    bucket => $bucket
  });
  my ($code, $encoded_message, $error) = $self->driver->perform_request($request_code, $request);
  
  ($code, $expected_code, $encoded_message, $error)
}

sub _process_get_response {
  my ($self, $encoded_message) = @_;
  
  my $decoded_message = RpbGetResp->decode($encoded_message);
  
  return decode_json($decoded_message->content->[0]->value)
    if  $decoded_message 
    and blessed $decoded_message
    and defined $decoded_message->content
    and defined $decoded_message->content->[0]
    and defined $decoded_message->content->[0]->value;
  
  undef
}

sub _process_err_response {
  my ($self, $encoded_message) = @_;
  
  my $decoded_message = RpbErrorResp->decode($encoded_message);
  
  $self->_set_last_error($decoded_message->errmsg);
  
  undef;
}

sub _process_error {
  my ($self, $error) = @_;
  
  $self->_set_last_error($error);
  
  undef
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