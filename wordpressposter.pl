#!/usr/bin/perl

use strict;
use warnings;

use WordPress::XMLRPC;
use DBI;
use Data::Dumper;

# Connect to sqlite3 database called mac.db
my $dbh = DBI->connect("dbi:SQLite:dbname=/root/mkmakerspace-macscanner/mac.db","","");
# CREATE TABLE addresses ( mac CHAR(12) PRIMARY KEY, lastseen DATETIME);


# Grab wordpress credentials from command arguments
my ($username,$password,$wordpressurl,$postid) = @ARGV;

my $o = WordPress::XMLRPC->new({
	username => $username,
	password => $password,
	proxy => $wordpressurl,
});

print "username = $username\n";
print "password = $password\n";
print "proxy = $wordpressurl\n";

my $post = $o->getPost($postid);

# Find mac's seen within 10 minutes
my $sth = $dbh->prepare("SELECT * FROM addresses INNER JOIN members ON addresses.mac = members.mac WHERE lastseen >= datetime ('now','-10 minute');");
$sth->execute();

$post->{description} = ""; # Clear post content otherwise it just appends
# iterate through addresses found in last 10 minutes
foreach (@{$sth->fetchall_arrayref}){
	# TODO: update this to display names of people opted in rather than all mac addresses
	print Dumper $_;	
	$post->{description} .= $_->[3] . ", "; # just post the mac's for the moment
}
$post->{description} =~ s/, $//;
$post->{description} .= " are at the shed.";

# Publish to wordpress
$o->editPost($postid, $post, 1);

print "$post->{description}";
