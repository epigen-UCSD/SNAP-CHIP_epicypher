set=$1
SETDIR="/home/zhc268/data/outputs/setQCs/"
samplenames=(`cat $SETDIR${set}.txt`)

for s in  ${samplenames[@]};do
    echo $s
    #rm ~/data/outputs/libQCs/${s}/${s}.fastq.bz2.snap.log
    bash epicypher.sh -i ~/data/seqdata/${s}.fastq.bz2 -m 0 -k false \
         -o ~/data/outputs/libQCs/${s}/ 1|tee  ~/data/outputs/libQCs/${s}/${s}.fastq.bz2.snap.cnt 
done
wait 



