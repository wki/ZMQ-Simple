#!/usr/bin/env perl
use Modern::Perl;
use lib '../lib';
use ZMQ::Simple;

my $socket = ZMQ::Simple->push('tcp://127.0.0.1:9000');

$socket->send($_) for @ARGV;
