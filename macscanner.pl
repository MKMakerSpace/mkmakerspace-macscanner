#!/usr/bin/perl

use strict;
use warnings;

my @nmap = `/usr/bin/nmap -on -sn 10.0.1.0/24`;
my @macs;

foreach (@nmap) {

        next if ($_ !~ /^MAC Address/);

        chomp;
        s/^MAC Address: //;
        s/ \(.*$//;

        print "$_\n";

}
