#!/usr/bin/perl
# add_barcode_label_for_usearch.pl 
# a perl to add a "barcode label" to fasta files
# Mark Blaxter
# version 0.1 25 09 2014
 
# usage is 
#   add_barcode_label_for_usearch.pl <infile> <barcodelabel> <outfile_name>

use strict;
use warnings;

# $infile is the input fasta file, likely a pair-merged, dereplicated fasta file
my $infile=$ARGV[0];

# $barcodelabel is the text to describe this sequence set
my $barcodelabel=$ARGV[1];

# $outfile just needs to have a new name
my $outfile=$ARGV[2];
 
# other variables
my $filesize;
my $fastaline;
my %fastahash;
my $hashkey="";
my $hashvalue="";

# check if theres anything in the input file
$filesize = -s $infile;
if ($filesize==0) {
	print "The Input file exists but appears to be empty.\n";
	exit;
	}

# now make a hash of the fasta file
open (FASTAIN, "<$infile");
while ($fastaline=<FASTAIN>) {
    chomp $fastaline;
    if ($fastaline=~/^\>/) {
        # some code to populate hash with previous event
        $fastahash{$hashkey}=$hashvalue;
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
$fastahash{$hashkey}=$hashvalue;
    
# now write out the hash into the output file
my $outkey;
open (FASTAOUT, ">$outfile");
foreach $outkey (keys %fastahash) {
    if ($outkey=~/\S/) {
        print FASTAOUT "\>" . $outkey . "barcodelabel=" . $barcodelabel . "\n" . $fastahash{$outkey} . "\n";
        }
    }
close FASTAOUT;

