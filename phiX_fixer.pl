#!/usr/bin/perl
# phiX_fixer.pl
# a perl to collate sequences that match phiX174
# and remove them from a fasta file
# Mark Blaxter
# version 0.2 16 05 2014
# usage is phiX_fixer.pl <infile> <blastfile> <outfile_name>

use strict;
use warnings;

# $infile is the input fasta file, likely a pair-merged, dereplicated fasta file
my $infile=$ARGV[0];

# $blastfile is the -m 8 -b 1 megablast output of a search using $infile against a phiX database
my $blastfile=$ARGV[1];

# $outfile just needs to have a new name
my $outfile=$ARGV[2];
 
# other variables
my $filesize;
my $blastline;
my $blasthit;
my $blastcollection;
my $fastaline;
my %fastahash;
my $hashkey="";
my $hashvalue="";


# check if theres anything in the blast file
$filesize = -s $blastfile;
if ($filesize==0) {
	print "The Blast file exists but appears to be empty.\n";
	print "The file $infile has been simply copied to $outfile.\n\n";
	system "cp $infile $outfile";
	exit;
	}
 
# reopen blastfile
open (BLAST, "<$blastfile");

# first populate a variable with the hits from the blastfile
while ($blastline=<BLAST>) {
    if ($blastline=~/^(\S+)\s/) {
        $blasthit=$1;
        $blastcollection.=$blasthit . " ";
        }
    else {
        print $blastline;
        }
    }
close BLAST;

# uncomment this to print $blastcollection to see what it looks like
# print $blastcollection;
 
# now make a hash of the fasta file allowing sequences in only if they DONT match the $blastcollection variable
open (FASTAIN, "<$infile");
while ($fastaline=<FASTAIN>) {
    chomp $fastaline;
    if ($fastaline=~/^\>/) {
        # some code to populate hash with previous event
        if ($blastcollection=~/$hashkey/) {
            print "Removing $hashkey\n";
            }
        else {
            $fastahash{$hashkey}=$hashvalue;
            }
        # and clear $hashkey and $hashvalue
        $hashkey="";
        $hashvalue="";
        $fastaline=~/^\>(\S+)/;
        $hashkey=$1;
        }
    else {
        $hashvalue.=$fastaline;
        }
    }
close FASTAIN;

# catch the last pair
if ($blastcollection=~/$hashkey/) {
    print "Removing $hashkey\n";
    }
else {
    $fastahash{$hashkey}=$hashvalue;
    }
    
# now write out the hash into the output file
my $outkey;
open (FASTAOUT, ">$outfile");
foreach $outkey (keys %fastahash) {
    if ($outkey=~/\S/) {
        print FASTAOUT "\>" . $outkey . "\n" . $fastahash{$outkey} . "\n";
        }
    }
close FASTAOUT;
