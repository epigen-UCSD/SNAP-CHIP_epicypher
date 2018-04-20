#!/usr/bin/env bash
#Time-stamp: "2018-04-20 00:22:44"


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

if [  -z "$MIS_MATCH" ]; then
    MIS_MATCH=0
fi

(>&2 echo [log]INPUT_FILE: $INPUT_FILE)   
(>&2 echo [log]BARCODE_FILE: $BARCODE_FILE)
(>&2 echo [log]KEEP_DB: $KEEP_DB)
(>&2 echo [log]MIS_MATCH: $MIS_MATCH)   


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
fq=${work_dir}/${id}.fastq
fa=${work_dir}/${id}.fa; 




# not exist; then check if db exist
while [ $ext != BREAK ]; do
    # check which step we should begin with
    [[ -e $log ]] && (>&2 echo "[log]log exist"); ext=BREAK
    [[ $(ls -1  ${fa}*.nhr 2>/dev/null|wc -l) -gt 0 ]] &&  (>&2 echo "[log]db exist"); ext=db
    [[ $(ls -1  ${INPUT_FILE}*.nhr 2>/dev/null|wc -l) -gt 0 ]]  &&  (>&2 echo "[log]db exist");fa=${INPUT_FILE}; ext=db
    if [[ -e $fa ]]; then
        (>&2 echo "[log]fasta exist"); ext=fasta;
    elif [[ -e $fq ]]; then
        (>&2 echo "[log]fastq exist"); ext=fastq;
    fi
                                                                                                     

    
    # main steps (based on ext) 
    case "$ext" in
        bz2) 
            (>&2 echo "($(date)) Begin decompress fastq")
            bzcat $INPUT_FILE > $fq
            (>&2 echo "($(date)) Finish decompress fastq")
            ;;
        gz)
            (>&2 echo "($(date)) Begin decompress fastq")
            zcat $INPUT_FILE > $fq
            (>&2 echo "($(date)) Finish decompress fastq")
            ;;        
        fq);&
        fastq)
            (>&2 echo "($(date)) Begin covert fastq to fasta")            
            seqtk seq -A $fq > $fa
            (>&2 echo "($(date)) Finish covert")
               ;;
        fasta)
            (>&2 echo "($(date)) Begin make db")            
            makeblastdb -in $fa -dbtype nucl
            (>&2 echo "($(date)) Finish make db")            
               ;;
        db) 
            echo "qseqid sseqid qlen length nident mismatch gapopen qstart qend sstart send evalue bitscore sstrand" > $log 
            blastn -db $INPUT_FILE -query $BARCODE_FILE -task "blastn" \
                   -outfmt "6 qseqid sseqid qlen length nident mismatch gapopen qstart qend sstart send evalue bitscore sstrand" \
                   >> $log
            ext=BREAK
            ;;
        *) echo wrong input format
           exit 1;;
    esac
done


awk -v mm=$MIS_MATCH '(NR>1 && $3-$5<=mm)' $log | awk '{count[$1]++} END {for (word in count) print word, count[word]}'


## 2. make db
#tmp_fq=${tmp_dir}/${id}.fq
#tmp_db=${tmp_dir}/
#if [ $ext == "bz2" ]
#then
#     bzcat /home/zhc268/data/seqdata/SRC1651.fastq.bz2> $tmp_fq
#fi

