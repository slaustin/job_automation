n=$(awk 'END {print NR}' jobpath.txt)
k=1

while [ $k -le $n ]
do

echo "Submitting Jobs in $(awk "NR==$k" jobpath.txt)"
cd $(awk "NR==$k" jobpath.txt)  && sh /panfs/storage.local/home-1/sa14aa/job_automation/job_status.sh
cd /panfs/storage.local/home-1/sa14aa/job_automation

k=$(($k + 1))

done

m=$(awk 'END {print NR}' checkpath.txt)
l=1

while [ $l -le $m ]
do

echo "Submitting Jobs in $(awk "NR==$l" checkpath.txt)"
cd $(awk "NR==$l" checkpath.txt)  && sh /panfs/storage.local/home-1/sa14aa/job_automation/error_check.sh
cd /panfs/storage.local/home-1/sa14aa/job_automation

l=$(($l + 1))

done

echo "Job Check Completed"

./get_space.sh
cat space_log.txt tmp >tmp2 && mv tmp2 space_log.txt
rm tmp
