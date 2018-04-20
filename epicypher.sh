#!/usr/bin/env bash
#Time-stamp: "2018-04-19 22:36:31"


############################################################
# PART I dependency
############################################################
# Requirements: 1. barcodes.fa 2. bzcat/gzcat 3. blastn 



############################################################
# PART II usage info & parameters
############################################################

usage(){
    exit 1
}


# receiving arguments
while getopts ":i:b:k:m:" opt;
do
    case "$opt" in
        i) INPUT_FILE=$OPTARG;;  # input fastq file 
        b) BARCODE_FILE=$OPTARG;; # input barcodes fasta 
        k) KEEP_DB=$OPTARG;; # keep db or not (default not)
        m) MIS_MATCH=$OPTARG;; # mismatch
        \?) usage
            echo "input error"
            exit 1
            ;;
    esac
done

# set default 

if [  -z "$KEEP_DB" ]; then
    KEEP_DB="false"
fi

if [  -z "$BARCODE_FILE" ]; then
    BARCODE_FILE="K-MetStat_v1.0.fa"
fi
   


############################################################
# PART III 
############################################################
## 1. depress input fastq
ext=${INPUT_FILE##*.} # bz2,fastq, fq, fasta, fa, gz
fname=$(basename $INPUT_FILE)
id=${fname%%.${ext}} # bz2,fastq, fq, fasta, fa, gz
dir=${INPUT_FILE%/*}
work_dir=$(pwd)/epicypher; mkdir -p $work_dir 
log=${work_dir}/${id}.log

#input is fa/or fasta and we check if db exist 
if [[ $(ls -1  ${INPUT_FILE}*.nhr 2>/dev/null|wc -l) -gt 0 ]]  # check if db already built
then 
    if [ ! -e $log ]
    then
        echo "qseqid sseqid qlen length nident mismatch gapopen qstart qend sstart send evalue bitscore sstrand" > $log 
        blastn -db $INPUT_FILE -query $BARCODE_FILE -task "blastn" -outfmt "6 qseqid sseqid qlen length nident mismatch gapopen qstart qend sstart send evalue bitscore sstrand" \
            >> $log
    fi
else
    

fi
awk -v mm=$MIS_MATCH '(NR>1 && $3-$5<=mm)' $log | awk '{count[$1]++} END {for (word in count) print word, count[word]}'


## 2. make db
#tmp_fq=${tmp_dir}/${id}.fq
#tmp_db=${tmp_dir}/
#if [ $ext == "bz2" ]
#then
#     bzcat /home/zhc268/data/seqdata/SRC1651.fastq.bz2> $tmp_fq
#fi

