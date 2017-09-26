#Automated Job Check and Submission Script
#Steven Austin

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

echo "Dirnum is $dirnum"

error4=$(tail -1 $directory/charmm.out)

if [[ $error4 != "" ]]
      then

      if grep -q 'xbrst' $directory/job; then
         flag=1
      fi

      if [[ $flag -eq 0 ]] ; then
      /panfs/storage.local/home-1/sa14aa/catall.sh 2 $dirnum
      fi

      if [[ $flag -eq 1 ]] ; then
      /panfs/storage.local/home-1/sa14aa/catallxb.sh 2 $dirnum
      fi

      exit
fi

dirnum=$(( $dirnum - 1 ))

done
