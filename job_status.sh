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
while [[ $dirnum -gt 0 ]] && [[ $total_jobs -le 25 ]]
do
	if [[ $dirnum -lt 10 ]] ; then
   	directory=restart0$dirnum
	else
   	directory=restart$dirnum
	fi

#echo "directory= $directory"

#Find Job Number
jobid=$(tail -n 1 $directory/numjob | awk '{print $4}')

#Determie if Error in Job Run
if [[ ! -f $directory/joboe.out ]] ; then
    squeue -j $jobid &> $directory/queuecheck.out
    inqueue=$(grep "$jobid" $directory/queuecheck.out | awk {'print $1'})
    #echo "inqueue=$inqueue"

    if [[ $inqueue != $jobid ]] ;then
    echo "Restart$directory being removed, numjob error"
    rm -r $directory
    dirnum=$(( $dirnum - 1))
    #break
    fi

    if [[ $inqueue == $jobid ]] ; then
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
        error5=$(grep 'EPHI: WARNING. bent improper torsion angle' $directory/charmm.out |  awk 'NR==1 {print}')
        #echo "error5 = $error5"
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
  	   echo "~~~~~~~~~~~~~~~!!!Error in restart$dirnum!!!~~~~~~~~~~~~~~~~";
           errornum=$dirnum
           error_count=$(( $error_count + 1))
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
              			echo "Restart$dirnum was preempted"
        		fi
                   wallclock_count=$(( $wallclock_count + 1 ))
                   error2=0
               fi
        fi

	if [[ $error3 -eq 0 ]]; then
        if [[ $running != 'R' ]]; then
        echo "~~~~~~~~~~~~~~~~Trajectory File Currupted~~~~~~~~~~"
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

        if [[ $error5 == *"EPHI: WARNING. bent improper torsion angle"* ]]; then
        	echo "~~~~~Improper torsion angle in  restart$dirnum~~~~~"
        	errornum=$dirnum
        	error_count=$(( $error_count + 1))
        fi

        total_jobs=$(( $queuedjobs + $error_count + $runningjob + $wallclock_count ))
        #echo "Total jobs is $total_jobs"

        	if [[ $error_count != 0 ]] && [[ $total_jobs -ge 25 ]]
        	then
                dirnum=$errornum

                #Copy Errors Into Log directory
                error_dir=$(date | awk {'print $1$2$3"_"$4'})
                mkdir ./error_log
                mkdir ./error_log/$error_dir
                cp restart$dirnum/joboe.out ./error_log/$error_dir/
                cp restart$dirnum/charmm.out ./error_log/$error_dir/                


                if [[ $dirnum -lt 10 ]] ; then
                directory=restart0$dirnum
                else
                directory=restart$dirnum
                fi


        	#Get Restart Information
		if grep -q 'bdrst' $directory/job; then
   		np=$(grep '#SBATCH -n *' $directory/job | awk '{print $3}')
   		qname=$(grep '#SBATCH -p *' $directory/job | awk '{print $3}')
   		jobname=$(grep 'job-name=**' $directory/job | awk -F '=' '{print $2}')
        	flag=1
        	fi
        
		if grep -q 'lzrst' $directory/job; then
   		np=$(grep '#SBATCH -n *' $directory/job | awk '{print $3}')
   		qname=$(grep '#SBATCH -p *' $directory/job | awk '{print $3}')
   		jobname=$(grep 'job-name=**' $directory/job | awk -F '=' '{print $2}')
        	flag=2
        	fi

		if grep -q 'dong' $directory/job; then
   		np=$(grep '#SBATCH -n *' $directory/job | awk '{print $3}')
   		qname=$(grep '#SBATCH -p *' $directory/job | awk '{print $3}')
   		jobname=$(grep 'job-name=**' $directory/job | awk -F '=' '{print $2}')
        	flag=3
        	fi

                if grep -q 'xbrst' $directory/job; then
                np=$(grep '#SBATCH -n *' $directory/job | awk '{print $3}')
                qname=$(grep '#SBATCH -p *' $directory/job | awk '{print $3}')
                jobname=$(grep 'job-name=**' $directory/job | awk -F '=' '{print $2}')
                flag=4
                fi

                if grep -q 'd_dis' $directory/job; then
                np=$(grep '#SBATCH -n *' $directory/job | awk '{print $3}')
                qname=$(grep '#SBATCH -p *' $directory/job | awk '{print $3}')
                jobname=$(grep 'job-name=**' $directory/job | awk -F '=' '{print $2}')
                flag=5
                fi
        
        	#Clean Jobs
        	echo Cleaning Restart$(( $errornum )) to Restart$(( $errornum + $error_count + $queuedjobs + $wallclock_count ))
        	/panfs/storage.local/home-1/sa14aa/clean/clean-jobm.sh $(( $errornum )) $(( $errornum + $error_count + $queuedjobs + $wallclock_count ))
        	/panfs/storage.local/home-1/sa14aa/clean/clean-dir.sh $(( $errornum )) $(( $errornum+ $error_count + $queuedjobs + $wallclock_count ))

        	#Submit Jobs
        	if [[ $flag == 1 ]]; then
        	/panfs/storage.local/home-1/sa14aa/rst/bdrst/dorst-buddy $(( $errornum )) $(( $errornum + 11)) $np $qname $jobname
        	fi

        	if [[ $flag == 2 ]]; then
        	/panfs/storage.local/home-1/sa14aa/rst/lzrst/dorst-nuts $(( $errornum )) $(( $errornum + 11)) $np $qname $jobname
        	fi

        	if [[ $flag == 3 ]]; then
        	/panfs/storage.local/home-1/sa14aa/rst/dong/dorst-dongsheng $(( $errornum )) $(( $errornum + 11)) $np $qname $jobname
        	fi

                if [[ $flag == 4 ]]; then
                /panfs/storage.local/home-1/sa14aa/rst/xbrst/dorst-xubin $(( $errornum )) $(( $errornum + 11)) $np $qname $jobname
                fi

                if [[ $flag == 5 ]]; then
                /panfs/storage.local/home-1/sa14aa/rst/dong_dis/dorst-dongsheng $(( $errornum )) $(( $errornum + 11)) $np $qname $jobname
                fi
                exit
                fi

        dirnum=$(( $dirnum - 1))
        if [[ $dirnum -lt 10 ]] ; then
        directory=restart0$dirnum
        else
        directory=restart$dirnum
        fi

fi

done

#echo "Edit Directory =$directory"

#Execute Clean Script to Remove Bad Runs
if [[ $(( $queuedjobs + $runningjob)) -lt 10 ]]
then
if [[ $error_count == 0 ]]
then
if [[ $flag == 0 ]]
then
dirnum=$(($dirnum + $queuedjobs + $runningjob + $wallclock_count))
#echo "dirnum=$dirnum"
numnew=$((10 - $queuedjobs))  #Makes number of pending jobs 10
#echo "directory=$directory"
echo Cleaning Restart$(( $dirnum + 1)) to Restart$(( $dirnum + $numnew))
/panfs/storage.local/home-1/sa14aa/clean/clean-jobm.sh $(( $dirnum + 1)) $(( $dirnum + $numnew))
/panfs/storage.local/home-1/sa14aa/clean/clean-dir.sh $(( $dirnum + 1)) $(( $dirnum + $numnew))

#Execute Restart Script
if grep -q 'bdrst' $directory/job; then
   np=$(grep '#SBATCH -n *' $directory/job | awk '{print $3}')
   qname=$(grep '#SBATCH -p *' $directory/job | awk '{print $3}')
   jobname=$(grep 'job-name=**' $directory/job | awk -F '=' '{print $2}')
   /panfs/storage.local/home-1/sa14aa/rst/bdrst/dorst-buddy $(( $dirnum + 1)) $(( $dirnum + $numnew)) $np $qname $jobname 
fi

if grep -q 'lzrst' $directory/job; then
   np=$(grep '#SBATCH -n *' $directory/job | awk '{print $3}')
   qname=$(grep '#SBATCH -p *' $directory/job | awk '{print $3}')
   jobname=$(grep 'job-name=**' $directory/job | awk -F '=' '{print $2}')
   /panfs/storage.local/home-1/sa14aa/rst/lzrst/dorst-nuts $(( $dirnum + 1)) $(( $dirnum + $numnew)) $np $qname $jobname
fi

if grep -q 'dong' $directory/job; then
   np=$(grep '#SBATCH -n *' $directory/job | awk '{print $3}')
   qname=$(grep '#SBATCH -p *' $directory/job | awk '{print $3}')
   jobname=$(grep 'job-name=**' $directory/job | awk -F '=' '{print $2}')
   /panfs/storage.local/home-1/sa14aa/rst/dong/dorst-dongsheng $(( $dirnum + 1)) $(( $dirnum + $numnew)) $np $qname $jobname
fi

if grep -q 'xbrst' $directory/job; then
   np=$(grep '#SBATCH -n *' $directory/job | awk '{print $3}')
   qname=$(grep '#SBATCH -p *' $directory/job | awk '{print $3}')
   jobname=$(grep 'job-name=**' $directory/job | awk -F '=' '{print $2}')
   /panfs/storage.local/home-1/sa14aa/rst/xbrst/dorst-xubin $(( $dirnum + 1 )) $(( $dirnum + $numnew)) $np $qname $jobname
fi

if grep -q 'd_dis' $directory/job; then
   np=$(grep '#SBATCH -n *' $directory/job | awk '{print $3}')
   qname=$(grep '#SBATCH -p *' $directory/job | awk '{print $3}')
   jobname=$(grep 'job-name=**' $directory/job | awk -F '=' '{print $2}')
   /panfs/storage.local/home-1/sa14aa/rst/dong_dis/dorst-dongsheng $(( $dirnum + 1)) $(( $dirnum + $numnew)) $np $qname $jobname
fi

fi
echo "Job Submission Complete"
else

if [[ $queuedjobs -eq 10 && $error -ne *"srun: error"* ]]
then
echo "Enough jobs submitted..."
echo
fi
fi
fi
echo "Enough Jobs Submitted..."
echo
