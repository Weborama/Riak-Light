## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Driver;
## use critic

use English qw( −no_match_vars );
use Riak::Light::Connector;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

# ABSTRACT: Riak Driver, deal with the binary protocol

has connector => ( is => 'ro', required => 1 );

sub BUILDARGS {
    my ( $class, %args ) = @_;

    return +{%args} if exists $args{connector};

    if ( exists $args{socket} ) {
        my $connector = Riak::Light::Connector->new( socket => $args{socket} );

        $args{connector} = $connector;
    }

    +{%args};
}

sub perform_request {
    my ( $self, %request ) = @_;

    my $request_body = $request{body};
    my $request_code = $request{code};

    my $message = pack( 'c a*', $request_code, $request_body );

    my $response = $self->connector->perform_request($message);

    return $self->_parse_error() unless defined $response;

    $self->_parse_response($response);
}

sub _parse_response {
    my ( $self, $response ) = @_;
    my ( $code, $body ) = unpack( 'c a*', $response );

    { code => $code, body => $body, error => undef };
}

sub _parse_error {
    {   code => undef, body => undef, error => $ERRNO    # $EVAL_ERROR
    };
}

1;
