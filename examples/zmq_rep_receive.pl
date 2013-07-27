#!/usr/bin/env perl

# wait for commands from req_send and send an answer

use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ZMQ::Simple;

my $socket = ZMQ::Simple->socket(rep => 'tcp://*:9000');

say 'waiting for commands...';
while (1) {
    my $message = $socket->receive;
    say "Message: '$message'";

    sleep 1;

    $socket->send("answer for '$message'");
}
