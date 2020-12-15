#!/bin/bash
# submit-assignment - A script to allow students to submit an assignment

friendly_error="Please contact your System Administrator if you think this is incorrect"

echo "Hello"
echo "Please start the submission process by entering your student ID"
#Read inputted student ID
read student_id
#Get all students in the system
all_students=$(members student)
#If the ID is not in the students group, exit script
if [[ ! $all_students =~ $student_id ]]
then
	echo "Student ID $student_id is not recognised as a Student"
	echo $friendly_error
	exit 1
fi

echo "Please enter the Course you are submitting an assignment for"
#Read inputted course code
read course_code

#The course directory if it is a valid course code
dir="/home/UniX/$course_code"
#Validate if it exists
if [ ! -d "$dir" ]
then
	echo "Course code $course_code does not exist"
	echo $friendly_error
	exit 1
fi

echo "Please enter the Assignment number"
#Read inputted assignment number
read assignment_number
#Updated directory variable
dir="$dir/Assignment-$assignment_number"
#Validate if this assignment's folder exists
if [ ! -d "$dir" ]
then
	echo "Assignment $assignment_number does not exist"
	echo $friendly_error
	exit 1
fi

echo "Please enter the file name (including relative file path and file extension) of your assignment to submit"
#Read inputted file path
read submission

#Get filename from submission/filepath specified
#i.e. if user inputted /path/to/my/file.txt, extract 'file.txt' from string
isolated_filename=$(echo $submission | awk -F "/" '{print $NF}')
echo "Will submit $isolated_filename for Assignment $assignment_number in Course $course_code"
filename="${student_id}_${isolated_filename}"

echo "Please log in to complete submission"
#Prompt student's password; on success, copy over their submission to the Assignments directory
su - $student_id -c "cp $submission $dir/$filename"
#Previous command execution gets stored in $?, 0 if successful
if [ $? -eq 0 ]
then
	echo "Submission completed"
else
	echo "Submission aborted: please try again"
fi