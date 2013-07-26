#!/usr/bin/env perl
use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ZMQ::Simple;

my $socket = ZMQ::Simple->push('tcp://127.0.0.1:9000');

say 'sending...';
$socket->send($_) for @ARGV;
