#!/usr/bin/env perl

# send a message to pull_receiver

use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ZMQ::Simple;

my $socket = ZMQ::Simple->socket(push => 'tcp://192.168.2.11:9000');

say 'sending...';
$socket->send($_) for @ARGV;
