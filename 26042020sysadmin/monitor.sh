#!/bin/bash
# monitor - A script to check the file permissions on the system

# Global variables for boolean checks
true=1
false=0
# and final reporting
failures=0
total=0

# Method to create a test user
create_user () {

	sudo useradd -m -N -G $2 $1
	#set the new user's password to be their username
	echo "$1:$1" | sudo chpasswd
	#set their primary group
	sudo usermod -g $3 $1
	#create the link to the UniX directory
	sudo ln -s /home/UniX /home/$1/UniX
}

# Method to delete user and their home directory
delete_user () {
	
	sudo userdel $1
	sudo rm -rf /home/$1
}

# Method to check a user can execute a command
check_command () {

	#execute the command as the user; do not print any output or errors
	sudo -S -u $1 $2 > /dev/null 2>&1
	# $? is 0 if successful
	# compare with parameter $3 if we expected a pass or fail
	check=$(( ($? == 0 && $3 == $true) || ($? != 0 && $3 == $false) ))

	#reporting statement prefix
	prefix="Has NO" && [[ $3 -eq 0 ]] && prefix="Has"

	if [ $check -eq 1 ]
	then
		echo "Pass: $1 Test: $prefix $4"
	else
		echo "!!!"
		echo "FAIL: $1 Test: $prefix $4"
		(( failures = $failures + 1 ))
	fi

	(( total = $total + 1 ))
}

# Create the test users
create_user "test_lecturer" "lecturer" "lecturer"
create_user "test_student" "student" "student"
create_user "test_student_2" "student" "student"
create_user "test_course_coordinator" "lecturer,course_coordinator" "course_coordinator"
create_user "test_course_auditor" "lecturer,course_auditor" "course_auditor"
create_user "test_tutor" "student,tutor" "tutor"
create_user "test_uni_x_sysadmin" "uni_x_sysadmin" "uni_x_sysadmin"

#copied from setup.sh to set up student-final-marks files
students=$(members student)
oldIFS=$IFS
IFS=$' '
#loop through each student...
for s in $students
do
	student_file="/home/UniX/$s.txt"
	sudo touch $student_file
	sudo chown test_uni_x_sysadmin:uni_x_sysadmin $student_file
	sudo setfacl -m u::--- $student_file
	sudo setfacl -m g::---,o::--- $student_file
	sudo setfacl -m g:course_coordinator:rw $student_file
	sudo setfacl -m u:$s:r $student_file
	sudo setfacl -m g:uni_x_sysadmin:--- $student_file
	sudo setfacl -m m::rw $student_file
done
IFS=$oldIFS

#Testing the UniX directory
testing="/home/UniX"
#Checks read permissions on the UniX directory
check_command "test_lecturer" "test -r $testing" $true "READ permissions on $testing"
check_command "test_student" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $true "READ permissions on $testing"
#Checks write permissions on the UniX directory
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $true "WRITE permissions on $testing"
#Checks execute permissions on the UniX directory
check_command "test_lecturer" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_student" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_course_coordinator" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_course_auditor" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_tutor" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -x $testing" $true "EXECUTE permissions on $testing"

#Testing a student-final-marks file
testing="/home/UniX/test_student.txt"
#Checks read permissions on the file
check_command "test_lecturer" "test -r $testing" $false "READ permissions on $testing"
check_command "test_student" "test -r $testing" $true "READ permissions on $testing"
check_command "test_student_2" "test -r $testing" $false "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $false "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $false "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $false "READ permissions on $testing"
#Checks write permissions on the file
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student_2" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $true "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $false "WRITE permissions on $testing"

#Testing course C101
testing="/home/UniX/C101"
#Checks read permissions on the course directory
check_command "test_lecturer" "test -r $testing" $true "READ permissions on $testing"
check_command "test_student" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $true "READ permissions on $testing"
#Checks write permissions on the course directory
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $true "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $true "WRITE permissions on $testing"
#Checks execute permissions on the course directory
check_command "test_lecturer" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_student" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_course_coordinator" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_course_auditor" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_tutor" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -x $testing" $true "EXECUTE permissions on $testing"

#Testing course info file
testing="/home/UniX/C101/C101.txt"
#Checks read permissions on the file
check_command "test_lecturer" "test -r $testing" $true "READ permissions on $testing"
check_command "test_student" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $true "READ permissions on $testing"
#Checks write permissions on the file
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $true "WRITE permissions on $testing"

#Testing C101 final exam
testing="/home/UniX/C101/finalExam.txt"
#Checks read permissions on the file
check_command "test_lecturer" "test -r $testing" $false "READ permissions on $testing"
check_command "test_student" "test -r $testing" $false "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $false "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $true "READ permissions on $testing"
#Checks write permissions on the file
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $true "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $false "WRITE permissions on $testing"

#Testing C101 final exam marking file
testing="/home/UniX/C101/finalExamMarking.txt"
#Checks read permissions on the file
check_command "test_lecturer" "test -r $testing" $false "READ permissions on $testing"
check_command "test_student" "test -r $testing" $false "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $false "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $false "READ permissions on $testing"
#Checks write permissions on the file
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $true "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $false "WRITE permissions on $testing"

#Imitate a lecture being created
testing="/home/UniX/C101/IGNORE_TEST_LECTURE.txt"
sudo -S -u test_course_coordinator touch $testing
#Checks read permissions on the file
check_command "test_lecturer" "test -r $testing" $true "READ permissions on $testing"
check_command "test_student" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $true "READ permissions on $testing"
#Checks write permissions on the file
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $true "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $false "WRITE permissions on $testing"
#Tidy up
sudo rm $testing

#Testing Assignment A001 directory
testing="/home/UniX/C101/Assignment-A001"
#Checks read permissions on the assignment directory
check_command "test_lecturer" "test -r $testing" $false "READ permissions on $testing"
check_command "test_student" "test -r $testing" $false "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $true "READ permissions on $testing"
#Checks write permissions on the assignment directory
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $true "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $true "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $true "WRITE permissions on $testing"
#Checks execute permissions on the assignment directory
check_command "test_lecturer" "test -x $testing" $false "EXECUTE permissions on $testing"
check_command "test_student" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_course_coordinator" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_course_auditor" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_tutor" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -x $testing" $true "EXECUTE permissions on $testing"

#Testing Assignment A001 student marks directory
testing="/home/UniX/C101/Assignment-A001-student-marks"
#Checks read permissions on the assignment student-marks directory
check_command "test_lecturer" "test -r $testing" $false "READ permissions on $testing"
check_command "test_student" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $true "READ permissions on $testing"
#Checks write permissions on the assignment student-marks directory
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $true "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $true "WRITE permissions on $testing"
#Checks execute permissions on the assignment student-marks directory
check_command "test_lecturer" "test -x $testing" $false "EXECUTE permissions on $testing"
check_command "test_student" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_course_coordinator" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_course_auditor" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_tutor" "test -x $testing" $true "EXECUTE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -x $testing" $true "EXECUTE permissions on $testing"

#Imitate a student submission
testing="/home/UniX/C101/Assignment-A001/IGNORE_TEST_SUBMISSION.txt"
sudo -S -u test_student touch "$testing"
#Checks read permissions on the file
check_command "test_lecturer" "test -r $testing" $false "READ permissions on $testing"
check_command "test_student" "test -r $testing" $true "READ permissions on $testing"
check_command "test_student_2" "test -r $testing" $false "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $true "READ permissions on $testing"
#Checks write permissions on the file
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $true "WRITE permissions on $testing"
check_command "test_student_2" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $false "WRITE permissions on $testing"
sudo rm $testing

#Imitate a tutor marking file copied to the student-marks folder by a course auditor
testing="/home/UniX/C101/Assignment-A001-student-marks/IGNORE_TEST_MARKING.txt"
sudo -S -u test_course_auditor touch "$testing"
#Checks read permissions on the file
check_command "test_lecturer" "test -r $testing" $false "READ permissions on $testing"
check_command "test_student" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $true "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $true "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $true "READ permissions on $testing"
#Checks write permissions on the file
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $false "WRITE permissions on $testing"
sudo rm $testing

#Testing logs folder
testing="/home/UniX/.logs"
#Checks read permissions on the assignment student-marks directory
check_command "test_lecturer" "test -r $testing" $false "READ permissions on $testing"
check_command "test_student" "test -r $testing" $false "READ permissions on $testing"
check_command "test_course_coordinator" "test -r $testing" $false "READ permissions on $testing"
check_command "test_course_auditor" "test -r $testing" $false "READ permissions on $testing"
check_command "test_tutor" "test -r $testing" $false "READ permissions on $testing"
check_command "test_uni_x_sysadmin" "test -r $testing" $true "READ permissions on $testing"
#Checks write permissions on the assignment student-marks directory
check_command "test_lecturer" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_student" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_coordinator" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_course_auditor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_tutor" "test -w $testing" $false "WRITE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -w $testing" $false "WRITE permissions on $testing"
#Checks execute permissions on the assignment student-marks directory
check_command "test_lecturer" "test -x $testing" $false "EXECUTE permissions on $testing"
check_command "test_student" "test -x $testing" $false "EXECUTE permissions on $testing"
check_command "test_course_coordinator" "test -x $testing" $false "EXECUTE permissions on $testing"
check_command "test_course_auditor" "test -x $testing" $false "EXECUTE permissions on $testing"
check_command "test_tutor" "test -x $testing" $false "EXECUTE permissions on $testing"
check_command "test_uni_x_sysadmin" "test -x $testing" $true "EXECUTE permissions on $testing"

#clean up
delete_user "test_lecturer"
delete_user "test_student"
delete_user "test_student_2"
delete_user "test_course_coordinator"
delete_user "test_course_auditor"
delete_user "test_tutor"
delete_user "test_uni_x_sysadmin"
sudo rm /home/UniX/test_student.txt
sudo rm /home/UniX/test_student_2.txt
sudo rm /home/UniX/test_tutor.txt

echo
echo "Finished with $failures failure(s) out of $total test cases"