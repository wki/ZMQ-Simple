package ZMQ::Simple;
use Moose;
use Moose::Util::TypeConstraints;
use ZMQ::LibZMQ3; # FIXME: can we make this dynamic somehow?
use ZMQ::Constants ':all';
# no namespace::autoclean as zmq_* methods would vanish
# use namespace::autoclean;

my $debug = 0;
sub log { print @_[1..$#_], "\n" if $debug }

=head1 NAME

ZMQ::Simple - simplify typical ZeroMQ use cases to one line

=head1 SYNOPSIS

    use ZMQ::Simple;

    # create a socket by specifying type and address
    # each type has a typical socket behavor (bind/connect)
    my $socket = ZMQ::Simple->socket(push => 'tcp://127.0.0.1:9000');
    
    # the long version
    my $socket = ZMQ::Simple->socket('push')->connect('tcp://127.0.0.1:9000');

    # getsockopt / setsockopt
    $socket->option('name', 'value');
    my $val = $socket->option('value');

    # send and receive
    $socket->send('abcd');
    my $message = $socket->receive;

    # TODO: poll

=head1 DESCRIPTION

=head1 ATTRIBUTES

=cut

our %info_for = (
    PUSH => { type => ZMQ_PUSH,  method => 'connect' },
    PULL => { type => ZMQ_PULL,  method => 'bind' },
    PUB  => { type => ZMQ_PUB,   method => 'bind' },
    SUB  => { type => ZMQ_SUB,   method => 'connect', }, # filter!
    REQ  => { type => ZMQ_REQ,   method => 'connect' },
    REP  => { type => ZMQ_REP,   method => 'bind' },
);

has socket_type => (
    is  => 'rw',
    isa => 'Str',
);

has address => (
    is        => 'rw',
    isa       => 'Str', ### TODO: allow arrayref
    predicate => 'has_address',
);

enum 'SocketMethod', [qw(bind connect)];
has method => (
    is         => 'rw',
    isa        => 'SocketMethod',
    lazy_build => 1,
);

sub _build_method {
    my $self = shift;
    
    $info_for{$self->socket_type}->method;
}

### TODO: _zmq_context should be a singleton
has _zmq_context => (
    is         => 'ro',
    isa        => 'Any',
    lazy_build => 1,
);

sub _build__zmq_context {
    my $self = shift;

    $self->log('zmq_init');

    return zmq_init
}

has _zmq_socket => (
    is         => 'rw',
    isa        => 'Any',
    lazy_build => 1,
);

sub _build__zmq_socket {
    my $self = shift;
    
    my $type = $self->socket_type;
    $self->log("build socket of type '$type'");

    my $info = $info_for{$type} or die "unknown type '$type'";
    my $socket = zmq_socket($self->_zmq_context, $info->{type});

    die 'no address to bind/connect to' if !$self->has_address;
    
    no strict 'refs';
    $self->log("$info->{method} '${\$self->address}'");
    my $zmq_method = "zmq_$info->{method}";
    $zmq_method->($socket, $self->address)
        and die "$info->{operation} '${\$self->address}' failed: $!";
    use strict 'refs';
    
    return $socket;
}

=head1 METHODS

=cut

sub DEMOLISH {
    my $self = shift;
    
    $self->log('close socket');
    zmq_close($self->_zmq_socket) if $self->_has_zmq_socket;
}

=head2 socket ( type, address [, additional info ] )

creates and returns a socket of specified type. Depending on the type the
socket will either connect to or bind the specified address.

TODO: if address is a hashref execute multiple binds or connects

=cut

sub socket {
    my $class   = shift;
    my $type    = uc shift;
    my $address = shift;

    my $self = $class->new(
        socket_type => $type,
        ($address ? (address => $address) : ()),
    );
    
    # what to do with additional info?
    # SUB: rc = zmq_setsockopt (subscriber, ZMQ_SUBSCRIBE, filter, strlen (filter));

    return $self;
}

# ... do more

=head2 bind ( $address )

bind an address

=cut

sub bind {
    my ($self, $address) = @_;
    
    $self->method('bind');
    $self->address($address);
    
    return $self;
}

=head2 connect ( $address )

connect to an address

=cut

sub connect {
    my ($self, $address) = @_;
    
    $self->method('connect');
    $self->address($address);
    
    return $self;
}

=head2 send ( $message [, $flags] )

send a message

=cut

sub send {
    my $self = shift;

    $self->log('send');

    zmq_sendmsg($self->_zmq_socket, @_);
}

=head2 receive

receive a message. may block

=cut

sub receive {
    my $self = shift;

    $self->log('receive');

    my $message = zmq_recvmsg($self->_zmq_socket);
    my $data = zmq_msg_data($message);
    zmq_msg_close($message);

    return $data;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

=over

=item L<ZMQx::Class|https://github.com/domm/ZMQx-Class>

=back

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
