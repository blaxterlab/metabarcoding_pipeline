#!/usr/bin/perl
# usearch_uc_parser2.pl
# Mark Blaxter
# version 1
# script for parsing a uparse .uc file
# to add the summed counts of reads contributing to unique sequences
# in a fasta file generated from pooled pre-dereplicated fasta files
# following the running of the following usearch command:
#      usearch -derep_fulllength your_reads_all_me_fi_bc_u.fasta -output \
#      your_reads_all_me_fi_bc_u2.fasta -sizeout -uc \
#      your_reads_all_me_fi_bc_u2.uc
# usage could be
#      usearch_uc_parser2.pl your_reads_all_me_fi_bc_u2.uc \
#      your_reads_all_me_fi_bc_u2.fasta your_reads_all_me_fi_bc_u3.fasta

use strict;
use warnings;

my $ucfile = $ARGV[0];
my $ucline;
my $ucname;
my $uchit;
my $uniquename;
my $uniquecount;
my %uniquehash;

my $fastafile = $ARGV[1];
my $fastaline;
my $recount;

my $ucoutfile = $ARGV[2];

# parse the UC format file
open (UCFILE, "<$ucfile") or die "Cannot open UCFILE $ucfile.\n";
print "\nOpened $ucfile for parsing...\n";
while ($ucline=<UCFILE>) {
	chomp $ucline;
    if ($ucline=~/^C/) { 
    	next;
    	}
	if ($ucline=~/^S.+\t(\S+)\t\S$/) {
		$ucname=$1;
		$ucname=~/^(.+size=)(\d+)\;$/;
		$uniquename=$1;
		$uniquecount=$2;
		$uniquehash{$uniquename}+=$uniquecount;
	}
	elsif ($ucline=~/^H.+\t(\S+)\t(\S+)$/) {
		$uchit=$1;
		$ucname=$2;
		$uchit=~/^.+size=(\d+)\;$/;
		$uniquecount=$1;
		$ucname=~/^(.+size=)\d+\;$/;
		$uniquename=$1;		
		$uniquehash{$uniquename}+=$uniquecount;
		}
	else {print "error: $ucline"; exit;}
	}
print "Finished parsing $ucfile.\n";

# open the fastafile, grab the headers, add the new numbers
open (FASTAFILE, "<$fastafile") or die "Cannot open FASTAFILE $fastafile.\n";
print "\nOpened $fastafile for editing...\n";
while ($fastaline=<FASTAFILE>) {
	chomp $fastaline;
	if ($fastaline=~/^\>(.+size=)\d+/) {
		$uniquename=$1;
		$recount.=">" . $uniquename . $uniquehash{$uniquename} . ";\n";
		}
	else {
		$recount.= $fastaline . "\n";
		}
	}
print "Finished editing $fastafile.\n\n";

# print the resulting fasta file
open (OUT, ">$ucoutfile") or die "Cannot open UCOUTFILE $ucoutfile.\n";
print OUT $recount;
print "Finished writing $ucoutfile.\n\n";
