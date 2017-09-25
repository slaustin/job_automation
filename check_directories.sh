n=$(awk 'END {print NR}' checkpath.txt)
k=1

while [ $k -le $n ]
do

echo "Submitting Jobs in $(awk "NR==$k" checkpath.txt)"
cd $(awk "NR==$k" checkpath.txt)  && sh /panfs/storage.local/home-1/sa14aa/job_automation/error_check.sh
cd /panfs/storage.local/home-1/sa14aa/job_automation

k=$(($k + 1))

done
