#!/usr/bin/env perl

# perform a roundtrip with vrious data sizes

use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Proc::Fork;
use ZMQ::Simple;
use Time::HiRes qw(gettimeofday tv_interval);

use constant {
    NR_CYCLES => 1000,
};

our $address = shift @ARGV // "ipc:///tmp/bench_$$";

run_fork {
    child  {
        receiver();
    }
    parent {
        my $child_pid = shift;
        
        sleep 1; # allow child to initialize
        
        sender();
        kill 3, $child_pid;
    }
};

say 'done.';
exit;

sub sender {
    say "starting sender, PID: $$...";

    my $socket = ZMQ::Simple->socket(req => $address);
    
    say "benchmarking $address";
    my $expected_nr = 0;
    foreach my $size (1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024) {
        my $data = join '', map { chr(32 + rand(64)) } (1 .. $size * 1024);
        
        my $t0 = [gettimeofday];
        
        my $nr_errors = 0;
        for (my $i = 0; $i < NR_CYCLES; $i++) {
            $socket->send($data);
            my $answer = $socket->receive;

            my $expected_answer = sprintf '%d/%d', $expected_nr++, $size * 1024;
            $nr_errors++ if $answer ne $expected_answer;
        }
        
        my $elapsed = tv_interval($t0, [gettimeofday]);
        my $speed   = sprintf '%0.1f', NR_CYCLES / $elapsed;
        say "Size: $size, Errors: $nr_errors, speed: $speed/s";
    }
}

sub receiver {
    say "starting receiver, PID: $$";

    my $socket = ZMQ::Simple->socket(rep => $address);

    my $i = 0;
    while (1) {
        my $message = $socket->receive;
        $socket->send( sprintf '%d/%d', $i++, length $message );
    }
}
