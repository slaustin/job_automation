#Automated VMD Visulization Creater
#Steven Austin

error=$(tail -1 *.vmd)

if [[ $error == "" ]]
      then
      echo "No VMD File, exiting!"
      exit
fi


#Find Last Job Directory
echo "Finding Restart Files"
find -maxdepth 1 -type d -name 'restart*'|sort -k 1.10n > directory.out
number=$(tail -1 'directory.out')
s=${#number}

if [[ $s -eq 11 ]]
then
i=$((${#number}-2))
dirnum=${number:$i:2}
        if [[ $dirnum -lt 10 ]]; then
               dirnum=$(echo $dirnum | head -c 2| tail -c 1)
        fi
fi

if [[ $s -eq 12 ]]
then
i=$((${#number}-3))
dirnum=${number:$i:3}
fi

if [[ $s -eq 13 ]]
then
i=$((${#number}-4))
dirnum=${number:$i:4}
fi


#Cycle Through Restarts to Find Last Completed Run
while [[ $dirnum -gt 0 ]]
do
        if [[ $dirnum -lt 10 ]] ; then
        directory=restart0$dirnum
        else
        directory=restart$dirnum
        fi

error=$(tail -1 $directory/dvdl.dat)

if [[ $error != "" ]]
      then
      dirnum_success=$dirnum
      break
fi

dirnum=$(( $dirnum - 1 ))

done

echo "Last Successful Directory is $dirnum_success"

original_vmd=$(ls *.vmd)

echo "Modifying $original_vmd"

grep -n "dcd" *.vmd > line_num.txt

cut_num=$(head -1 line_num.txt | cut -d ":" -f1)

awk -v n=${cut_num} 'NR<n' *.vmd >top_vmd.txt

cut_num=$(tail -1 line_num.txt | cut -d ":" -f1)

awk -v n=${cut_num} 'NR>n' *.vmd >bottom_vmd.txt

grep "dcd" *.vmd >dcd_vmd.txt

tail -1 dcd_vmd.txt >last_line.txt

awk '{print $3}' last_line.txt >vmd_last.txt

dcd_file=$(grep "/" vmd_last.txt | cut -d "/" -f1)

s=${#dcd_file}

if [[ $s -eq 9 ]]
then
i=$((${#dcd_file}-2))
dirnum=${dcd_file:$i:2}
        if [[ $dirnum -lt 10 ]]; then
               dirnum=$(echo $dirnum | head -c 2| tail -c 1)
        fi
fi

if [[ $s -eq 10 ]]
then
i=$((${#dcd_file}-3))
dirnum=${dcd_file:$i:3}
fi

if [[ $s -eq 11 ]]
then
i=$((${#dcd_file}-4))
dirnum=${dcd_file:$i:4}
fi

if [[ $dirnum_success == $dirnum ]]
then
echo "VMD file already up to date"
rm line_num.txt
rm top_vmd.txt
rm bottom_vmd.txt
rm last_line.txt
rm vmd_last.txt
rm dcd_vmd.txt
exit
fi

dirnum=$(( $dirnum + 1 ))

mv dcd_vmd.txt total_addin.txt

while [[ $dirnum -le $dirnum_success ]]
do

if [[ $dirnum -lt 10 ]] ; then
        directory=restart0$dirnum
        else
        directory=restart$dirnum
fi

added_restart=$(ls $directory/*.dcd)

awk {'print $1,$2,"'$added_restart'",$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17'} last_line.txt >add1.txt

cat total_addin.txt add1.txt >tmp && mv tmp total_addin.txt

dirnum=$(( $dirnum + 1 ))

done

cat top_vmd.txt total_addin.txt bottom_vmd.txt >new.vmd

mv new.vmd $original_vmd

echo "Cleaning Up..."
rm line_num.txt
rm top_vmd.txt
rm bottom_vmd.txt
rm last_line.txt
rm vmd_last.txt
rm add1.txt
rm total_addin.txt
echo "Done!"
