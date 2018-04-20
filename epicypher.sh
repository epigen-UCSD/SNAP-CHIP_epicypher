#!/usr/bin/env bash
#Time-stamp: "2018-04-20 09:42:32"


############################################################
# PART I dependency
############################################################
# Requirements: 1. barcodes.fa 2. bzcat/gzcat 3. blastn 



############################################################
# PART II usage info & parameters
############################################################

function usage(){
    cat << EOF

Usage: epicypher.sh [-i <chr>] [-b <chr>] [-k <true|false>] [-m <int>] [-o <dir>] [-v]

Estimate spike in reads from SNAP-CHIP spikein

Options:
  [no option],             show this help message and exit
  -i input file (fastq|fq|gz|bz2|fa|fasta)
  -b barcode file in fasta format (default:K-MetStat_v1.0.fa)
  -k keep tmp file 
  -m number of mismatch allowed
  -o output dir
  -v show VERSION         

EOF
}


# receiving arguments
[[ $# -eq 0 ]] && usage &&exit

while getopts ":i:b:k:m:o:v" opt;
do
    case "$opt" in
        i) INPUT_FILE=$OPTARG;;  # input fastq file 
        b) BARCODE_FILE=$OPTARG;; # input barcodes fasta 
        k) KEEP_TMP=$OPTARG;; # keep db or not (default not)
        m) MIS_MATCH=$OPTARG;; # mismatch
        o) OUT_DIR=$OPTARG;; #output dir
        v) echo $(a=$(which epicypher.sh);cd ${a%/*};git describe --tags)
           exit
           ;;
        \?) usage
            echo "input error"
            exit 1
            ;;
    esac
done

# set default 
if [  -z "$KEEP_TMP" ]; then
    KEEP_TMP="false"
fi

if [  -z "$BARCODE_FILE" ]; then
    BARCODE_FILE="$(which K-MetStat_v1.0.fa)"
fi

if [  -z "$MIS_MATCH" ]; then
    MIS_MATCH=0
fi

if [  -z "$OUT_DIR" ]; then
    OUT_DIR=$(pwd)/epicypher;
fi

(>&2 echo [log]INPUT_FILE: $INPUT_FILE)   
(>&2 echo [log]BARCODE_FILE: $BARCODE_FILE)
(>&2 echo [log]KEEP_TMP: $KEEP_TMP)
(>&2 echo [log]MIS_MATCH: $MIS_MATCH)   
(>&2 echo [log]OUT_DIR: $OUT_DIR)   

############################################################
# PART III 
############################################################
## 1. depress input fastq
ext=${INPUT_FILE##*.} # bz2,fastq, fq, fasta, fa, gz
fname=$(basename $INPUT_FILE)
id=${fname%%.${ext}} # bz2,fastq, fq, fasta, fa, gz
id=${id%%.fastq} # bz2,fastq, fq, fasta, fa, gz
dir=${INPUT_FILE%/*}
work_dir=$OUT_DIR; mkdir -p $work_dir 
log=${work_dir}/${fname}.snap.log
fq=${work_dir}/${id}.fastq
fa=${work_dir}/${id}.fa; 


# not exist; then check if db exist
while [ $ext != BREAK ]; do
    
    # check which step we should begin with
    if [[ -e $log ]]; then
        (>&2 echo "[log]log exist"); ext=BREAK;
    elif [[ $(ls -1  ${fa}*.nhr 2>/dev/null|wc -l) -gt 0 ]]; then
        (>&2 echo "[log]db exist"); ext=db;
    elif  [[ $(ls -1  ${INPUT_FILE}*.nhr 2>/dev/null|wc -l) -gt 0 ]]; then
        (>&2 echo "[log]db exist");fa=${INPUT_FILE}; ext=db
    elif [[ -e $fa ]]; then
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
        fa) ;& 
        fasta)
            (>&2 echo "($(date)) Begin make db")            
            makeblastdb -in $fa -dbtype nucl
            (>&2 echo "($(date)) Finish make db")            
            ;;
        db) 
            echo "qseqid sseqid qlen length nident mismatch gapopen qstart qend sstart send evalue bitscore sstrand" > $log 
            blastn -db $fa -query $BARCODE_FILE -task "blastn" \
                   -outfmt "6 qseqid sseqid qlen length nident mismatch gapopen qstart qend sstart send evalue bitscore sstrand" \
                   >> $log
            ext=BREAK
            ;;
        BREAK) ;;
        *) echo wrong input format
           exit 1;;
    esac
done

## apply mismatch threshold 
awk -v mm=$MIS_MATCH '(NR>1 && $3-$5<=mm)' $log | awk '{count[$1]++} END {for (word in count) print word, count[word]}'

## rm tmp file
[[ $KEEP_TMP != "true" ]] && rm $fq ${fa}* 1> /dev/null 2>&1 
