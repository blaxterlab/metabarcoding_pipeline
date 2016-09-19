# metabarcoding_pipeline
A simple metabarcoding analysis pipeline using usearch.

# METABARCODING SAMPLE PROCESSING
Mark Blaxter  
mark.blaxter@ed.ac.uk  
version 1.1 September 2014

## PURPOSE
These notes describe a workflow for the analysis of paired-end metabarcode sequence data using the usearch programme/suite of programmes. The flow is presented as a series of “disconnected” commands, but, rather obviously, these could be chained together to form a single script using shell or other scripting approaches. The process results in a dataset that is ready for ecological/community analysis (an “OTU table”).

These notes describe the protocol I use to analyse MiSeq metabarcoding data. My experience is largely with nSSU/eukaryotic metabarcoding, though we have also analysed bacterial 16S v3/v4 data. These approaches should also work well with other metabarcoding targets, as long as the data generated result in overlapping sequence reads.

## SETUP
usearch  
This protocol uses usearch. See http://drive5.com.  
The “free to academics” version of usearch (the 32 bit one) cannot process large files (as in more than a few Gb) and so if you want to use this version you will have to do some operations using a split dataset. The effects of doing this (apart from the annoyance) are minimal as far as I have been able to establish. If you plan to do a lot of analyses, it may be an idea to purchase the academic licence for the 64-bit version. I like the 64-bit version a lot.

FastQC  
FastQC is a nice graphical (java) tool that assesses the quality of next generation read datasets. It is not essential for this protocol, but because of its visualisations, is quite useful. usearch also has routines for data QC. You can run FastQC in a fully GUI mode, or from the command line. The command line lets you specify alternate parameters, which is good for assessment of long read data (such as 250 b or 300 b MiSeq).  
Download FastQC from http://www.bioinformatics.babraham.ac.uk/projects/fastqc/

## Conventions in this document

    Commands and filenames are in courier font below.

Note that commands as printed here may spread over two lines: they should be entered on ONE line in the terminal.  
File names and other variable texts are given in italic. The filename is called “your_reads”, and is in italic: you should substitute the correct name for your files. I like to increment the name of the file each time I do something to it, so that each file has its history in its name.

You may need to specify the full path to the programs (“executables”).

# THE WORKFLOW

The workflow starts when you have your raw data back from the facility in fastq format, split, based on the MIDs, into sample subsets.

STEP 1: RENAME THE FILES

The files will come back with a naming scheme that is dependent on the facility standard operating procedure. Its useful to rename these files to something you understand, and that is easier to remember and type.

You can do this in the operating system GUI, or by using the UNIX mv command. I would recommend collecting all the files in one directory for analysis. Through the workfflow, I find it useful to increment the output file names with a short postfix, so it is relatively easy to see where each one came from.

The raw paired end reads will probably come in separate files, called something like your_reads_1_1.sanfastq and your_reads_1_2.sanfastq, where your_reads_1 is the sample name. They may be delivered compressed (e.g. your_reads_1.sanfastq.gz). If so just decompress them with the relevant command or program (in many operating systems, double clicking on a compressed file will launch the decompression utility).

STEP 2: RAW DATA QC

Run fastqc on each sample. They should all look the same but its good to check.

    fastqc --nogroup your_reads_1_1.sanfastq

You can view the fastqc output in a browser: just open the fastqc_report.html file that the program creates in the your_reads_1.sanfastq.fastqc folder. You should at least check one forward and one reverse read file. It is good to check them all: they should all look the same. The --nogroup parameter makes fastqc assess each base position independently rather than grouping them in bins. This option is not available in the simple GUI version.

### NOTE: usearch fastq statistics  
usearch can also perform fastq assessment, but the output is not graphical/html as in FastQC.

    usearch -fastq_stats your_reads_1_1.sanfastq -log your_reads_1_1.log

The usearch command is more easily included in scripts.]

## STEP 3: MERGE THE PAIRED READS

This merging generates consensus sequences for the full insert from overlapping paired end reads. It should be performed for each sample set. I use usearch for this. You could use pear (http://sco.h-its.org/exelixis/web/software/pear/ - which is much better and faster in fact!) or other read mergers.

###[[do the following in each sample]]

    usearch -fastq_mergepairs your_reads_1_1.sanfastq -reverse your_reads_1_2.sanfastq -fastq_truncqual 3 -fastq_maxdiffs 8 -fastqout your_reads_1_me.fastq

## STEP 4: FILTER THE MERGED DATA

We now filter the merged reads in each sample to remove low quality ones and any that are too short. Change the minlen parameter to suit your amplicon size.

    usearch -fastq_filter your_reads_1_me.fastq -fastaout your_reads_1_me_fi_bc.fasta -relabel your_sample_name -eeout -fastq_maxee 1 -fastq_minlen 350

And repeat for your_reads_2_merged.fasta, your_reads_3_merged.fasta etc.

You now must add a flag to tell the process what “label” you want the data to have when you count the number of reads per sample per OTU. This is called the “barcodelabel”. It can be anything unique to your dataset. I use a text string that means something to me. The text “barcode=barcodelabeltext” is added to the end of the fasta header line of each sequence in each of your merged read files using the perl script add_barcode_label_for_usearch.pl (see end of document for this script).

    add_barcode_label_for_usearch.pl your_reads_1_me_fi.fasta barcodelabeltext your_reads_1_me_fi_bc.fasta

## STEP 5: SAMPLE DEREPLICATION

We now dereplicate the filtered sequences to generate a file of the unique sequences, and a count of how many different reads had that unique sequence. We do this by sample because the free version of usearch is 32-bit and cannot address more thhan 4 Gbyte of RAM. If you have the paid-for 64-bit version of usearch, you can use much more RAM, and will be able to run these steps on all your data at once.

    usearch -derep_fulllength your_reads_1_me_fi_bc.fasta -output your_reads_1_me_fi_bc_u.fasta -sizeout

And repeat for your_reads_2_me_fi_bc.fasta, your_reads_3_me_fi_bc.fasta etc.

## STEP 6: POOLED DEREPLICATION

We now catenate the files of unique sequences in each sample, and dereplicate these together to generate the “universal” list of unique sequences. We then need to add back the counts for each sample, which is done using a custom perl script (appended). The .uc file is a tabular report of the mapping of reads to clusters.

    cat your_reads_*_me_fi_bc_u.fasta  > your_reads_all_me_fi_bc_u.fasta 

Where your_reads_*_me_fi_bc_u.fasta uses the wildcard * to catch all the different files; you may have to alter this for the particular pattern of naming you use. In any case you can just do it in longhand, naming the files explicitly:

    cat file1 file2 file3 > file all

Now dereplicate the catenated files of unique sequences to generate a universal set of unique sequences from all the samples.

    usearch -derep_fulllength your_reads_all_me_fi_bc_u.fasta -output your_reads_all_me_fi_bc_u2.fasta -sizeout -uc your_reads_all_me_fi_bc_u2.uc

To add the individual counts back to the dereplicated uniques we use usearch_uc_parser2.pl, a custom perl script.

    ./usearch_uc_parser2.pl your_reads_all_me_fi_bc_u2.uc your_reads_all_me_fi_bc_u2.fasta your_reads_all_me_fi_bc_u3.fasta

Finally, to prepare for the clustering step, we sort the sequences by length

    usearch -sortbylength your_reads_all_me_fi_bc_u3.fasta -output your_reads_all_me_fi_bc_u3_s.fasta

## STEP 7: CLUSTERING

Now we use usearch clustering to cluster the unique reads into groups. You need to choose a cutoff. You can of course run the clustering at several different cutoffs if you choose. The command below is for 99% identity; change the -id parameter (and likely the centroids outfile name also) for other cutoffs.

    usearch -cluster_smallmem your_reads_all_me_fi_bc_u3.fasta -centroids your_reads_all_me_fi_bc_u3_c99.fasta -sizein -sizeout -id 0.99 -maxdiffs 1

## STEP 8: OTU CALLING

We now do the OTU calling. usearch calls OTUs and filters for chimaeras at the same time. To call chimaeras usearch uses the standard algorithm of assuming that more abundant sequences are more likely to be real, and conflicting chimaeras will be less abundant than their parents. So first we sort by size (the number of reads contributing to the cluster), and then define the OTUs.

    usearch -sortbysize your_reads_all_me_fi_bc_u3_c99.fasta -output your_reads_all_me_fi_bc_u3_c99_ss.fasta -minsize 2

Now define OTUs.

    usearch -cluster_otus your_reads_all_me_fi_bc_u3_c99_ss.fasta -otus your_reads_all_me_fi_bc_u3_c99_ss_OTUs.fasta

It is useful here to rename the sequences (the centroids taken to define the OTUs) so that they have a sensible name.

    python ../usearch/python/fasta_number.py your_reads_all_me_fi_bc_u3_c99_ss_OTUs.fasta your_project_name > your_reads_all_me_fi_bc_u3_c99_ss_OTUs_r.fasta

## STEP 9: ELIMINATE PHIX

The viral genome of phiX is used as a control in Illumina sequencing. While the viral libraries do not have MIDs on them, some phiX reads always creep through, possibly because the clusters “borrow” the signals from closely surrounding clusters that do. These phiX reads need to be removed. I do it here because we are then removing the phiX from the simplest dataset. You could do the removal at any stage. You will need a library of phiX genomes to do this, and the BLAST executable. The command line below is for pre-BLAST+ executables.

To catch all the phiX reads I have used a database of three phiX genomes. The Illumina phiX is not exactly like the reference genomes, so these three serve to catch all the variants.  
gi|410809623|gb|JX913857.1| Synthetic Enterobacteria phage phiX174.1f, complete genome  
gi|304442578|gb|HM753712.1| Enterobacteria phage phiX174 isolate XC+MbD22ic7, complete genome  
gi|125661633|gb|EF380032.1| Enterobacteria phage phiX174 isolate DEL4, complete genome  

You need to download these from GenBank/ENA, catenate them into one file, format them for BLAST searching, then do the BLASTs.

    /usr/local/ncbi/bin/megablast -d ../phiX/phixdb.fsa -b 1 -m 8 -i your_reads_all_me_fi_bc_u3_c99_ss_OTUs_r.fasta -o your_reads_all_me_fi_bc_u3_c99_ss_OTUs_r_megablast_out.txt

We remove sequences matching phiX from the fasta file using a perl script (see below).

    phixphixer.pl your_reads_all_me_fi_bc_u3_c99_ss_OTUs_r.fasta your_reads_all_me_fi_bc_u3_c99_ss_OTUs_r_megablast_out.txt your_reads_all_me_fi_bc_u3_c99_ss_OTUs_r_nx.fasta

## STEP 10: READ COUNTS PER SAMPLE

The reads are now mapped back to your reference set, and reads per unique reference sequence counted. If you have the 32-bit version of usearch it is likely you will have to do this in batches. The batches can be larger than those used previously. Obviously, if you have the 64-bit version, you can map many more reads at once.

# do mapping 1

    usearch -usearch_global your_reads_merged_l_1234.fasta -db your_reads_merged_l_u_s_c99_m2_otus_r_nx.fasta -strand plus -id 0.97 -uc your_reads_merged_uniques_l_u_s_c99_m2_otus_r_nx.map.uc

# turn mapping1 into table

    python ../usearch/python/uc2otutab.py your_reads_merged_uniques_l_u_s_c99_m2_otus_r_nx.map.uc  > your_reads_merged_l_u_s_c99_m2_otus_r_nx.otu_table.txt

# do mapping 2

    usearch -usearch_global your_reads_merged_l_5678.fasta -db your_reads_merged_l_u_s_c99_m2_otus_r_nx.fasta -strand plus -id 0.97 -uc your_reads_merged_uniques_l_u_s_c99_m2_otus_r_nx2.map.uc

# turn mapping2 into table

    python ../usearch/python/uc2otutab.py your_reads_merged_uniques_l_u_s_c99_m2_otus_r_nx2.map.uc  > your_reads_merged_l_u_s_c99_m2_otus_r_nx2.otu_table.txt

# merge tables

    usearch_table_merger.pl your_reads_merged_l_u_s_c99_m2_otus_r_nx.fasta your_reads_merged_l_u_s_c99_m2_otus_r_nx.otu_table.txt your_reads_merged_l_u_s_c99_m2_otus_r_nx2.otu_table.txt your_reads_merged_l_u_s_c99_m2_otus_r_nx_all.otu_table.txt
