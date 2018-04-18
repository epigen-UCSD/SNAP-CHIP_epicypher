#!/bin/bash

for x in fastq/*.fastq.bz2; do
  id=`basename $x`
  id=${id%%.fastq.bz2}
  if ! [ -e $id.txt ]; then
    echo $id > $id.txt
    bzcat $x | awk 'NR%4==2' | ../epicypher.pl $id >> $id.txt & sleep 5
  fi
done

wait

awk -F '\t' '{print $1"\t"$3}' $id.txt > table.tsv
for x in fastq/*.fastq.bz2; do
  id=`basename $x`
  id=${id%%.fastq.bz2}
  txt=$id.txt
  paste table.tsv <(awk -F '\t' '{print $2}' $txt) > $$; mv $$ table.tsv
done
