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
use Carp;
use Params::Validate qw(validate_pos);
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

before [ qw<put del get> ] => sub {  
  undef $@
};

sub get {
  my ($self, $bucket, $key) = validate_pos(@_,1,1,1);
  
  $self->_process_response(
    $self->driver->perform_request(
      9, 
      RpbGetReq->encode({ 
        r => $self->r,
        key => $key,
        bucket => $bucket
      }),
      $bucket, 
      $key
      )
   )
}

sub put {
  my ($self, $bucket, $key, $value, %opts) = validate_pos(@_, 1,1,1,1,0);
  
  my $content_type  = $opts{content_type} // 'application/json';
  my $encoded_value = ($content_type eq 'application/json') ? encode_json($value) : $value;
  
  $self->_process_response(
    $self->driver->perform_request(
      11, 
      RpbPutReq->encode({ 
         key => $key,
         bucket => $bucket,    
         content => {
           content_type => $content_type,
           value => $encoded_value
        },
      }),
    $bucket, 
    $key
    )
  )
}

sub del {
  my ($self, $bucket, $key) = validate_pos(@_,1,1,1);

  $self->_process_response(
    $self->driver->perform_request(
      13,
      RpbDelReq->encode({ 
        key => $key,
        bucket => $bucket,
        dw => $self->rw
      }),
    $bucket, 
    $key
    )
  )
}

sub _process_response {
  my ($self, $code, $expected_code, $encoded_message, $error) = @_;
 
  return $self->_process_error($error) if ($error);

  if($code == $expected_code){
    return ($code == 10)? $self->_process_get_response($encoded_message) : 1
  }
 
  return $self->_process_err_response($encoded_message) if ($code == 0);
      
  undef
}


sub _process_get_response {
  my ($self, $encoded_message) = @_;
  
  my $decoded_message = RpbGetResp->decode($encoded_message);
  
  if(  $decoded_message 
    and blessed $decoded_message
    and defined $decoded_message->content
    and defined $decoded_message->content->[0]){
  
    my $value        = $decoded_message->content->[0]->value;
    my $content_type = $decoded_message->content->[0]->content_type;
    
    return ($content_type eq 'application/json') ? decode_json($value) : $value    
  }
  
  undef
}

sub _process_err_response {
  my ($self, $encoded_message) = @_;
  
  my $decoded_message = RpbErrorResp->decode($encoded_message);
  
  $self->_process_error($decoded_message->errmsg);
}

sub _process_error {
  my ($self, $error) = @_;
  
  $@ = $error; ## no critic (RequireLocalizedPunctuationVars)
  
  croak $error if $self->autodie;
  
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
  $client->put( foo => bar => { baz => 1024 }, content_type => 'application/json')
    or confess "ops... $@";

  # fetch hashref from bucket 'foo', key 'bar'
  my $hash = $client->get( foo => 'bar');

  # delete hashref from bucket 'foo', key 'bar'
  $client->del(foo => 'bar');