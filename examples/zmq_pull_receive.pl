#!/usr/bin/env perl

# receive messages from push_send

use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ZMQ::Simple;

my $socket = ZMQ::Simple->socket(pull => 'tcp://*:9000');

say 'waiting for messages...';
while (1) {
    say 'Message: ', $socket->receive;
}
