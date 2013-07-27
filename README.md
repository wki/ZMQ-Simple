ZMQ-Simple
==========

reduce typical ZMQ use cases to a single line

    use ZMQ::Simple;
    
    # create a socket by specifying type and address
    my $socket = ZMQ::Simple->socket(push => 'tcp://127.0.0.1:9000');
    
    # getsockopt / setsockopt
    $socket->option('name', 'value');
    my $val = $socket->option('value');
    
    # send and receive
    $socket->send('abcd');
    my $message = $socket->receive;
