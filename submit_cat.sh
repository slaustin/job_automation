n=$(awk 'END {print NR}' jobpath.txt)
k=1

while [ $k -le $n ]
do

echo "Submitting Jobs in $(awk "NR==$k" jobpath.txt)"
cd $(awk "NR==$k" jobpath.txt)
if grep -q 'xbrst' ./job; then
   sh /panfs/storage.local/home-1/sa14aa/job_automation/cat_ltrj.sh
   sh /panfs/storage.local/home-1/sa14aa/job_automation/modify_vmd_xb.sh
else
   sh /panfs/storage.local/home-1/sa14aa/job_automation/cat_dvdl.sh
   sh /panfs/storage.local/home-1/sa14aa/job_automation/modify_vmd.sh
fi
cd /panfs/storage.local/home-1/sa14aa/job_automation

k=$(($k + 1))

done

echo "Job Catanation Completed"
