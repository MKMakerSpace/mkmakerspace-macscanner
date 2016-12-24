#!/usr/bin/perl

use strict;
use warnings;

use WordPress::XMLRPC;
use DBI;
use Data::Dumper;

# Connect to sqlite3 database called mac.db
my $dbh = DBI->connect("dbi:SQLite:dbname=mac.db","","");
# CREATE TABLE addresses ( mac CHAR(12) PRIMARY KEY, lastseen DATETIME);

# Perform nmpa scan
my @nmap = `/usr/bin/nmap -on -sn 10.0.1.0/24`;
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

# Grab wordpress credentials from command arguments
my ($username,$password,$wordpressurl) = @ARGV;

my $o = WordPress::XMLRPC->new({
	username => $username,
	password => $password,
	proxy => $wordpressurl,
});

my $postid = 2; # wordpress post id
my $post = $o->getPost($postid);

# Find mac's seen within 10 minutes
my $sth = $dbh->prepare("SELECT mac,lastseen FROM addresses WHERE lastseen >= datetime ('now','-10 minute')");
$sth->execute();

$post->{description} = ""; # Clear post content otherwise it just appends
# iterate through addresses found in last 10 minutes
foreach (@{$sth->fetchall_arrayref}){
	# TODO: update this to display names of people opted in rather than all mac addresses
	$post->{description} .= $_->[0] . ", "; # just post the mac's for the moment
}
$post->{description} .= " are at the shed.";

# Publish to wordpress
$o->editPost($postid, $post, 1);
