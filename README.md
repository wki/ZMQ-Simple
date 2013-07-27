ZMQ-Simple
==========

reduce typical ZMQ use cases to a single line

    use ZMQ::Simple;
    
    # create a socket, both do the same thing:
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
