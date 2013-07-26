#!/usr/bin/env perl
use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ZMQ::Simple;

my $socket = ZMQ::Simple->pull('tcp://127.0.0.1:9000');

say 'waiting for messages...';
while (1) {
    say 'Message: ', $socket->receive;
}
