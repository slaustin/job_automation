#Automated VMD Visulization Creater
#Steven Austin

mv total_ltrj.dat ltrj*_all.dat


last_step=$(tail -1 ltrj*_all.dat |awk {'print $1'})
if [[ $last_step == "" ]]
      then
      cp ltrj*.dat ltrj_all.dat
      last_step=$(tail -1 ltrj*_all.dat |awk {'print $1'})
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

error=$(tail -1 $directory/ltrj*.dat)

if [[ $error != "" ]]
      then
      dirnum_success=$dirnum
      break
fi

dirnum=$(( $dirnum - 1 ))

done

echo "Last Successful Restart is $dirnum_success"


dirnum=$dirnum_success

if [[ $dirnum -lt 10 ]] ; then
        directory=restart0$dirnum
        else
        directory=restart$dirnum
        fi

complete_check=$(tail -1 $directory/ltrj*.dat |awk '{print $1'})

if [[ $complete_check -eq $last_step ]];then
      mv ltrj*_all.dat total_ltrj.dat
      echo "Dvdl already fully combined..."
      exit
fi



dirnum=$dirnum_success

while [[ $dirnum -ge 1 ]]
do

if [[ $dirnum -lt 10 ]] ; then
        directory=restart0$dirnum
        else
        directory=restart$dirnum
        fi


compare_step=$(head -2 $directory/ltrj*.dat |awk 'NR==2 {print $1'})

last_compare=$(( $last_step - 1000 ))

echo "dirnum = $dirnum"

if [[ $compare_step -lt $last_compare ]];then
      dirnum_start=$(( $dirnum - 1 ))
      break
fi

dirnum=$(( $dirnum - 1 ))
done

echo "Catenating from Restart$dirnum_start"


while [[ $dirnum_start -le $dirnum_success ]]
do

if [[ $dirnum_start -lt 10 ]] ; then
        directory=restart0$dirnum_start
        else
        directory=restart$dirnum_start
        fi

cat ltrj*_all.dat $directory/ltrj*.dat > tmp && mv tmp ltrj*_all.dat

dirnum_start=$(( $dirnum_start + 1 ))

done

mv ltrj*_all.dat total_ltrj.dat
echo "Complete!"
