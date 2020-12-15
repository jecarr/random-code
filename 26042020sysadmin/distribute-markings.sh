#!/bin/bash
# distribute-markings - A script to distribute student submissions to tutors for marking

echo "Running distribute-markings.sh: you may be prompted for your password"
INDENT="     "

#We will be depending on the IFS (internal field separator) being a newline
OLDIFS=$IFS
IFS=$'\n'

#Find the Courses folders in UniX directory
#maxdepth 0 to prevent further folders in Course folders to be returned
courses="$(find /home/UniX/* -maxdepth 0 -type d)"

#Loop through each course
for c in $courses
do
	#Get Course name (after last backslash in $c)
	coursename=$(echo $c | awk -F "/" '{print $NF}')
	#Can read the second line in the course-info file to get tutors
	tutors_line=$(ls -l | sed -n 2p ${c}/${coursename}.txt)
	#Ignore the beginning part (substring "Tutor(s) = ", i.e. ending in "= ")
	tutors=$(echo $tutors_line | awk -F "= " '{print $NF}')
	#Replace ", " with our IFS delimiter \n - g for all instances
	tutors=$(echo $tutors | sed 's/, /\n/g')
	#Convert the newline-delimited string into an array
	tutors=($tutors)
	#keep track of our total number of tutors for this course
	total_tutors=${#tutors[@]}

	#declare markings variables to keep track of how many submissions each tutor is assigned to mark
	for t in ${tutors[@]}
	do
		#declare needs Bash version 2 or greater
		declare markings_$t=0
	done

	#Get all the assignment directories for this course
	assignments_all="$(find $c/* -maxdepth 0 -type d)"

	#keep track of which tutor we are assigning to
	index=0

	#Loop through each assignment
	for a in $assignments_all
	do
		#Skip the student-marks directories (name ends with "-student-marks")
		if [[ $a == *-student-marks ]]
		then
			continue
		fi

		echo "Working in assignment directory $a"
		
		#The assignments directories are restricted, need to sudo when listing contents
		submissions="$(sudo ls $a)"

		#Loop through each submission
		for s in $submissions
		do
			current_tutor=${tutors[index]}
			echo "${INDENT}Assigning $current_tutor submission $s"
			#Create the marking file for this submission and change the owner
			marking_file=${a}/marking_${s}
			sudo touch $marking_file
			sudo chown $current_tutor:tutor $marking_file
			#overwrite read-only default for tutors
			sudo setfacl -m g:tutor:rw $marking_file
			#Move along to the next tutor in array, start at 0 if we're currently on the last tutor
			index=$(( (index + 1 ) % total_tutors ))
			#Increment tutor-assignment count
			#count_var - the name of the variable we declared in the for loop
			count_var=$"markings_${current_tutor}"
			#Assign it to its old value + 1
			(( $"markings_${current_tutor}" = ${!count_var} + 1 ))
		#end of submissions loop
		done
	#end of assignment directories loop
	done

	echo
	echo "Tutor total markings for Course $coursename"
	for t in ${tutors[@]}
	do
		count_var=$"markings_${t}"
		echo "Tutor $t assigned ${!count_var} to mark"
	done
	echo

#end of course directories loop
done

IFS=$OLDIFS