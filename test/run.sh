set=$1
SETDIR="/home/zhc268/data/outputs/setQCs/"
samplenames=(`cat $SETDIR${set}.txt`)

for s in  ${samplenames[@]};do
    echo $s
    time  bash epicypher.sh -i ~/data/seqdata/${s}.fastq.bz2 -m 0 \
          -o ~/data/outputs/libQCs/${s}/ \
          1> ~/data/outputs/libQCs/${s}/${s}.fastq.bz2.snap.run.log \
          2>&1 & sleep 5               
done

wait 
