#!/usr/bin/env perl

# send a command to rep_receiver and wait for answer

use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ZMQ::Simple;

my $socket = ZMQ::Simple->socket(req => 'tcp://192.168.2.11:9000');

foreach my $command (@ARGV) {
    say "sending Command '$command'...";
    $socket->send($command);

    my $answer = $socket->receive;
    say "got answer: '$answer'";
    
    say '';
}