#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use Data::Dumper;

# Connect to sqlite3 database called mac.db
my $dbh = DBI->connect("dbi:SQLite:dbname=/root/mkmakerspace-macscanner/mac.db","","");
# CREATE TABLE addresses ( mac CHAR(12) PRIMARY KEY, lastseen DATETIME);

# Perform nmap scan
my @nmap = `/usr/bin/nmap -on -sn 192.168.0.0/24`;
my @macs;

foreach (@nmap) {

	next if ($_ !~ /^MAC Address/);

	chomp;
	s/^MAC Address: //;
	s/ \(.*$//;

	# Add or update mac's last seen date/time in database
	my $sth = $dbh->prepare("INSERT OR REPLACE INTO addresses VALUES (?, CURRENT_TIMESTAMP)");
	$sth->execute($_);

	print "$_ found\n";

}
