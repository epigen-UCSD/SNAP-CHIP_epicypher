
SETDIR="/home/zhc268/data/outputs/setQCs/"
export PATH=$PATH:/home/zhc268/data/software/SNAP-CHIP_epicypher

set=$1
samplenames=(`cat $SETDIR${set}.txt`)
for s in ${samplenames[@]}
do echo $s;
   #rm ~/data/outputs/libQCs/${s}/${s}_R[1-2].fastq.gz.snap.log
   bash epicypher.sh -i ~/data/seqdata/${s}_R1.fastq.gz -m 2 -k true -o ~/data/outputs/libQCs/${s}/ 1 | tee ~/data/outputs/libQCs/${s}/${s}_R1.fastq.gz.snap.cnt.tab & sleep 5
   bash epicypher.sh -i ~/data/seqdata/${s}_R2.fastq.gz -m 2 -k true -o ~/data/outputs/libQCs/${s}/ 1 |tee ~/data/outputs/libQCs/${s}/${s}_R2.fastq.gz.snap.cnt.tab & sleep 5

done
wait
echo "finished"

