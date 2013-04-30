## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light;
## use critic
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;
use IO::Socket;

has port    => (is => 'ro', isa => Int,  required => 1);
has host    => (is => 'ro', isa => Str,  required => 1);
has timeout => (is => 'ro', isa => Num,  default  => sub { 0.5 });
has autodie => (is => 'ro', isa => Bool, default  => sub { 0 });

has r       => ( is => 'ro', isa => Int, default => sub { 2 });
has w       => ( is => 'ro', isa => Int, default => sub { 2 });
has dw      => ( is => 'ro', isa => Int, default => sub { 2 });

has socket  => (
  is => 'lazy'
);

sub _build_socket {
  my $self = shift;
  IO::Socket::INET->new(
    PeerAddr => $self->host,
    PeerPort => $self->port,
    Timeout  => $self->timeout,
    Proto    => 'tcp'
  )
}

has last_error => (
  is => 'rwp', 
  default => sub { "" }
);

sub get {
  undef
}

sub put {
  undef
}

sub del {
  undef
}

# ABSTRACT: Fast and lightweight Perl client for Riak

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