sed 's/ \{2,\}/\t/g' K-AcStat_v0.5.txt  | awk -F'\t' -v OFS='\t' '{print ">"$1,$2,$4}'|sed 's/\t/_/1;s/\t/\n/1'> K-AcStat_v0.5.fa 
