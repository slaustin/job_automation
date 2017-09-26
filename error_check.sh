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


flag=0
queuedjobs=0
error_count=0
error_num=0
runningjob=0
total_jobs=0
wallclock_count=0
echo "Determining Status"

#Cycle Through Restarts to Find Last Viable Run
while [[ $dirnum -gt 0 ]] && [[ $wallclock_count -le 15 ]]
do
	if [[ $dirnum -lt 10 ]] ; then
   	directory=restart0$dirnum
	else
   	directory=restart$dirnum
	fi

#Find Job Number
jobid=$(tail -n 1 $directory/numjob | awk '{print $4}')

#Determie if Error in Job Run
if [[ ! -f $directory/joboe.out ]] ; then
    squeue -j $jobid &> $directory/queuecheck.out
    inqueue=$(grep `expr $jobid` $directory/queuecheck.out)
    if [[ $inqueue == *`expr $jobid`* ]] ; then
        if [[ $dirnum -lt 10 ]] ; then
    	      echo "Restart0$dirnum is queued"
        else
              echo "Restart$dirnum is queued"
        fi
    	#echo "jobid=$jobid"
    	queuedjobs=$(( $queuedjobs + 1))
    	dirnum=$(( $dirnum - 1))
    fi

else
        error_prev=$error
	error=$(grep 'srun: error' $directory/joboe.out)
        error2=$(grep 'PREEMPTION' $directory/joboe.out)
        error3=$(wc -c $directory/*.dcd | awk '{print $1}')
        error4=$(tail -1 $directory/charmm.out)
       # echo "error4 = $error4"
        error5=$(grep 'EPHI: WARNING. bent improper torsion angle' $directory/charmm.out |  awk 'NR==1 {print}')
	wallclock=$(grep 'DUE TO TIME LIMIT' $directory/joboe.out)
        squeue -j $jobid &> $directory/queuecheck.out
	running=$(grep ' R ' $directory/queuecheck.out | awk '{print $5}')

	if [[ $error4 == *"No such file or directory"* ]]
        then
        echo "~~~~~~~~~~~~~~~!!!No charmm.out in restart$dirnum!!!~~~~~~~~~~~~~~~~";
        errornum=$dirnum
        error_count=$(( $error_count + 1))
        fi

        if [[ $wallclock != *"DUE TO TIME LIMIT"* ]]
        then	
           if [[ $error == *"srun: error"* ]]
	   then
  	      echo "~~~~~~~~~~~~~~~!!!Srun Error in restart$dirnum!!!~~~~~~~~~~~~~~~~";
        fi
        fi

        if [[ $error2 == *"PREEMPTION"* ]]
        then
        check=$(awk '/Nonbond update at step/' $directory/charmm.out | tail -1 | awk '{print $6}')
        	if [[ $check -lt 1000 ]] ; then
                echo "~~~~~~~~~~~~~~~!!!Preemption in restart$dirnum!!!~~~~~~~~~~~~~~~~";
        	errornum=$dirnum
        	error_count=$(( $error_count + 1))
                fi
                if [[ $check -gt 1000 ]] ; then
                	if [[ $dirnum -lt 10 ]] ; then
                		echo "Restart0$dirnum was preempted"
        		else
              			echo "Restart$dirnum is preempted"
        		fi
                   
                   wallclock_count=$(( $wallclock_count + 1 ))
                   error2=0
               fi
        fi

        if [[ $error5 == "EPHI: WARNING. bent improper torsion angle" ]]; then
        echo "Improper torsion angle in  restart$dirnum"
        fi

	if [[ $error3 -eq 0 ]]; then
        if [[ $running != 'R' ]]; then
        echo "~~~~~~~~~~~Trajectory File Currupted in restart$dirnum~~~~~~~~~~"
        errornum=$dirnum
        error_count=$(( $error_count + 1))
        fi
        fi    

        if [[ $error != *"srun: error"* ]]; then
        if [[ $error2 != *"PREEMPTION"* ]]; then
            if [[ $running == 'R' ]]; then
                if [[ $dirnum -lt 10 ]] ; then
              		echo "Restart0$dirnum is running"
        	else
              		echo "Restart$dirnum is running"
        	fi
                runningjob=$(( runningjob + 1))
            fi
        fi
        fi

        if [[ $wallclock == *"DUE TO TIME LIMIT"* ]]
        then
        	if [[ $dirnum -lt 10 ]] ; then
              		echo "Restart0$dirnum reached wallclock"
        	else
              		echo "Restart$dirnum reached wallclock"
        	fi
        wallclock_count=$(( $wallclock_count + 1 ))
        fi

        total_jobs=$(( $queuedjobs + $error_count + $runningjob + $wallclock_count ))
        #echo "Total jobs is $total_jobs"


        dirnum=$(( $dirnum - 1))

        if [[ $dirnum -lt 10 ]] ; then
        directory=restart0$dirnum
        else
        directory=restart$dirnum
        fi

fi

done


#Success Monitoring Module
if [[ $error_count != 0 ]]; then
dirnum_success=$(( $errornum - 1 ))
	if [[ $dirnum_success -lt 10 ]] ; then
                dirnum_success=0$dirnum_success
        fi
echo "Is this the last directory?.... $dirnum_success"
echo "Last viable Run Completed on $(date -r restart$dirnum_success/charmm.out)"
time_stamp=$(date -r restart$dirnum_success/charmm.out | awk '{print $3}')
current_date=$(date | awk '{print $3}')
        if [[ $current_date -lt $time_stamp ]]; then
        current_date=$(( $current_date + 30 ))
        fi
last_completion=$(( $current_date - $time_stamp ))
echo "Last viable run completed $last_completion day(s) ago"
	if [[ $last_completion -gt 3 ]]; then
        currentdirectory=${PWD}
        mail -s "Job Submission Errors" sa14aa@my.fsu.edu <<< "The jobs in path $currentdirectory have not been successful for $last_completion days."
        fi
fi

if [[ $error_count == 0 ]]; then
	s=${#number}
	if [[ $s -eq 11 ]]
	then
	i=$((${#number}-2))
	dirnum_viable=${number:$i:2}
	fi
	if [[ $s -eq 12 ]]
	then
	i=$((${#number}-3))
	dirnum_viable=${number:$i:3}
	fi
        if [[ $s -eq 13 ]]
        then
        i=$((${#number}-4))
        dirnum_viable=${number:$i:4}
        fi
dirnum_success=$(( $dirnum_viable - $queuedjobs - $runningjob ))
	if [[ $dirnum_success -lt 10 ]] ; then
        	dirnum_success=0$dirnum_success
	fi
echo "Last viable Run Completed on $(date -r restart$dirnum_success/charmm.out)"
time_stamp=$(date -r restart$dirnum_success/charmm.out | awk '{print $3}')
current_date=$(date | awk '{print $3}')
	if [[ $current_date -lt $time_stamp ]]; then
	current_date=$(( $current_date + 30 ))
	fi
last_completion=$(( $current_date - $time_stamp ))
echo "Last viable run completed $last_completion day(s) ago"
	if [[ $last_completion -gt 3 ]]; then
        currentdirectory=${PWD}
        mail -s "Job Submission Errors" sa14aa@my.fsu.edu <<< "The jobs in path $currentdirectory have not been successful in $last_completion days."
        fi
fi


echo "Enough Jobs Submitted..."
echo
