pan_df -h /panfs/storage.local/imb/yang/ >space.txt
awk {'print $3'} space.txt >tmp && mv tmp space.txt
awk 'NR==3 {print $0}' space.txt > tmp && mv tmp space.txt
space_left=$(awk -F'[^0-9]*' {'print $1'} space.txt)
current_date=$(date)
echo "$space_left GB Available on Yang Disk at $current_date"
echo "$space_left GB Available on Yang Disk at $current_date" >tmp
if [[ $space_left -lt 75 ]]; then
      mail -s "Yang Disk at $space_left GB" sa14aa@my.fsu.edu <<< "The Yang disk has $space_left GB available"
fi
rm space.txt
