## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::Alarm;
## use critic

use POSIX qw(ETIMEDOUT ECONNRESET);
use Time::HiRes qw(alarm);
use Moo;
use Carp;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

with 'Riak::Light::Timeout';

# ABSTRACT: proxy to read/write using Alarm as a timeout provider

has socket      => ( is => 'ro', required => 1 );
has in_timeout  => ( is => 'ro', isa      => Num, default => sub {0.5} );
has out_timeout => ( is => 'ro', isa      => Num, default => sub {0.5} );
has is_valid    => ( is => 'rw', isa      => Bool, default => sub {1} );

sub clean {
    my $self = shift;
    $self->socket->close;
    $self->is_valid(0);
}

around [qw(sysread syswrite)] => sub {
    my $orig = shift;
    my $self = shift;

    if ( !$self->is_valid ) {
        $! = ECONNRESET;    ## no critic (RequireLocalizedPunctuationVars)
        return;
    }

    $self->$orig(@_);
};

sub sysread {
    my $self = shift;

    my $buffer;
    my $seconds = $self->in_timeout;

    my $result = eval {
        local $SIG{'ALRM'} = sub { croak 'Timeout !' };
        alarm($seconds);

        my $readed = $self->socket->sysread(@_);

        alarm(0);

        $buffer = $_[0];    # NECESSARY, timeout does not map the alias @_ !!
        $readed;
    };
    if ($@) {
        $self->clean();
        $! = ETIMEDOUT;     ## no critic (RequireLocalizedPunctuationVars)
    }
    else {
        $_[0] = $buffer;
    }

    $result;
}

sub syswrite {
    my $self = shift;

    my $seconds = $self->out_timeout;
    my $result  = eval {
        local $SIG{'ALRM'} = sub { croak 'Timeout !' };
        alarm($seconds);

        my $readed = $self->socket->syswrite(@_);

        alarm(0);

        $readed;
    };
    if ($@) {
        $self->clean();
        $! = ETIMEDOUT;    ## no critic (RequireLocalizedPunctuationVars)
    }

    $result;
}

1;

__END__

=head1 NAME

  Riak::Light::Timeout::Alarm - IO Timeout based on sig alarm + time hires for Riak::Light

=head1 VERSION

  version 0.001

=head1 DESCRIPTION
  
  Internal class

