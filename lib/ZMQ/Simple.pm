package ZMQ::Simple;
use Moose;
use ZMQ::LibZMQ3; # FIXME: can we make this dynamic somehow?
use ZMQ::Constants ':all';
# use namespace::autoclean;

my $debug = 0;
sub log {
    my $self = shift;

    print @_, "\n" if $debug;
}

=head1 NAME

ZMQ::Simple - simplify typical ZeroMQ use cases to one line

=head1 SYNOPSIS

    use ZMQ::Simple;

    # same thing:
    my $socket = ZMQ::Simple->push->bind('tcp://127.0.0.1:9000');
    my $socket = ZMQ::Simple->push('tcp://127.0.0.1:9000'); # auto bind for push

    my $socket = ZMQ::Simple->pull('tcp://127.0.0.1:9000'); # auto connect for pull
    #other methods: req/req, pub/sub, ...

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

=head2 socket_type

the type of socket to generate (PUSH, PULL, REQ, REP, PUB, SUB, ...).
for creating the socket, an upper-cased version of this type will be used.

=cut

has socket_type => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_socket_type',
);

has bind => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'must_bind',
    clearer   => 'do_not_bind',
);

has connect => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'must_connect',
    clearer   => 'do_not_connect',
);

after bind    => sub { $_[0]->do_not_connect };
after connect => sub { $_[0]->do_not_bind };

# the ZMQ context
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
    is         => 'ro',
    isa        => 'Any',
    lazy_build => 1,
);

sub _build__zmq_socket {
    my $self = shift;

    $self->log('build socket');

    die 'neither bind or connect called'
        if !$self->must_connect && !$self->must_bind;

    die 'no type specified'
        if !$self->has_socket_type;

    my $socket = zmq_socket($self->_zmq_context, $self->socket_type);

    if ($self->must_bind) {
        $self->log('bind: ' . $self->bind);
        zmq_bind($socket, $self->bind)
            and die "Bind failed: $!";
    } elsif ($self->must_connect) {
        $self->log('connect: ' . $self->connect);
        zmq_connect($socket, $self->connect);
    }

    return $socket;
}

=head1 METHODS

=cut

# geht das?
# foreach my $operation ( [ push => ZMQ_PUSH, 'bind'], ... ) {
#     my ($method, $type, $direction) = @$operation;
#
#     after $method => sub {
#         my $self = shift;
#
#         $self->type($type);
#         $self->$direction(@_) if $direction && @_;
#     };
# }

=head2 push ( [ $address ] )

set the socket type to PUSH and optionally bind a given address

=cut

sub push {
    my $class = shift;

    my $self = $class->new;
    $self->log('push');
    
    $self->socket_type(ZMQ_PUSH);
    $self->connect(@_) if @_;

    return $self;
}

=head2 pull

set the socket type to PULL and optionally connect to a given address

=cut

sub pull {
    my $class = shift;

    my $self = $class->new;
    $self->log('pull');

    $self->socket_type(ZMQ_PULL);
    $self->bind(@_) if @_;

    return $self;
}

# ... do more

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

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
