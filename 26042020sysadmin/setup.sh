#!/bin/bash
# setup - A script to create the groups, users and file system for the University of X's computer system 

# Global variables
sysadmin="x99999"
audit_root="/home/UniX/.logs"
# Current folder for audit logs
audit_dir=""

# Methods

# Method to update the current audit folder
set_up_audit_folder () {

	#Parameter $1 is a date, create a new folder for the specified date
	audit_dir="${audit_root}/${1}"
	sudo mkdir $audit_dir
}

# Method to restrict access to an object
restrict_access () {
	sudo setfacl -m g::---,o::--- $1
}

# Method to create a group
add_group () {

	echo "Adding group $1"
	#groupadd will state if group already exists
	sudo groupadd $1
}

# Method to create a user
create_user () {

	echo "Adding user $1 to group(s) $2"

	#useradd will state if user already exists
	# -m: create a home directory for the user
	# -N: we don't want a new group created and named after each user
	# -G: we are specifying the user's groups
	sudo useradd -m -N -G $2 $1

	#chpasswd expects username and new password when called
	#set the new user's password to be their username
	echo "$1:$1" | sudo chpasswd

	#set their primary group
	sudo usermod -g $3 $1

	#if this user is only in the system admins group, give them sudo rights
	#this assumes the sudoers file defaults with sudo access for the sudo group
	if [ $2 == "uni_x_sysadmin" ]
	then
		# -a: append
		sudo usermod -aG "sudo" $1		
	fi
}

# Method to create a user and give them access to the UniX directory
add_user () {
	
	#create the user first
	create_user $1 $2 $3

	#Set a shortcut/link to the directory where the University files will be in the user's home directory
	# -s: soft link not hard link (i.e. not creating a copy of the directory)
	sudo ln -s /home/UniX /home/$1/UniX

	#restrict others from accessing the user's home directory
	sudo setfacl -m g::---,o::--- /home/$1
	#allow the sysadmins as they have full control
	sudo setfacl -m g:uni_x_sysadmin:rwx /home/$1
}

# Method to audit a directory
# People recommend linux package tools such as inotify-tools
# These are not pre-installed, a different approach has been taken
audit_directory () {

	#Name the log file after the directory we are auditing ($1 is the parameter of this in a friendly format)
	logfile="${audit_dir}/${1}.txt"
	#Create the log file
	sudo touch $logfile

	#Output of the last time we ls'ed the directory
	last_ls="-1"
	#Current date in YYYY-MM-DD format 
	current_f=$(/bin/date +%F)

	#Always audit...
	while true
	do
		#Check we have the right audit folder for today
		#Get today's date
		now_f=$(/bin/date +%F)

		#Functionality to switch log files - requests sudo password: not feasible
		#If this doesn't match our current date...
		if [ "$now_f" != "$current_f" ]
		then
			#Set up the new audit directory for today 
			current_f=$now_f
			set_up_audit_folder $current_f
			logfile="${audit_dir}/${1}.txt"
			sudo touch $logfile
			last_ls=""
		fi

		# ls on the specified directory ($2); state 'full-time' to get differences within a minute
		# pipe output to awk to format it: don't match on lines beginning with 'd' (directory) 
		# and omit first line (FNR > 0) as this is a line stating the total number of items
		now_ls=$(sudo ls --full-time -l $2 | awk -vprefix='File ' '(!/^d/) && (FNR > 1) {print prefix $0}')
		#If this is different from the last ls output, log the change
		if [ ! "$now_ls" = "$last_ls" ]
		then
			last_ls=$now_ls
			now=$(/bin/date)

			printf "\n==============================\n" | sudo tee -a $logfile > /dev/null
			printf "Directory Audited ${now}\n\n" | sudo tee -a $logfile > /dev/null
			printf "${now_ls}\n" | sudo tee -a $logfile > /dev/null
			
		fi
		# Repeat this loop every second
		sleep 1

	done
}

# Method to start a background process to audit a directory
start_audit () {
	audit_directory $1 $2 &
}

# Method to create a course directory and its main files
create_course () {

	cd /home/UniX

	echo "Creating course $1"
	sudo mkdir $1
	#change owner accordingly
	sudo chown $2:course_coordinator $1

	#Allow course coordinators to create new content in the course directory
	sudo setfacl -m g:course_coordinator:rwx $1
	#Set defaults for course-future files
	sudo setfacl -dm g:course_coordinator:rwx,u::rwx,g:lecturer:r $1
	#Overwrite r-x user default as a course coordinator is now the owner and should be able to rwx
	sudo setfacl -m u::rwx $1

	cd $1
	
	#create course info file
	sudo touch $1.txt
	echo "Course Coordinator = $2" | sudo tee -a $1.txt
	echo "Tutor(s) = $3" | sudo tee -a $1.txt
	echo "Entered directory $1"

	#create final exam files
	sudo touch finalExam.txt
	sudo touch finalExamMarking.txt

	#set owners on these three files
	sudo chown $sysadmin:uni_x_sysadmin $1.txt
	sudo chown $2:course_coordinator finalExam.txt
	sudo chown $2:course_coordinator finalExamMarking.txt
	#restrict any one from seeing the final exam files
	restrict_access "finalExam.txt"
	restrict_access "finalExamMarking.txt"
	#Course coordinators are the only ones who write the exam or mark them
	sudo setfacl -m g:course_coordinator:rw,u::rw,g:lecturer:--- finalExam.txt
	sudo setfacl -m g:course_coordinator:rw,u::rw,g:lecturer:--- finalExamMarking.txt
	#Assume the sysadmin will only update the course info file (revert rwx default)
	sudo setfacl -m g:course_coordinator:r-- $1.txt
	#Course auditors and admins can read the exam (admins can read to be able to print)
	sudo setfacl -m g:course_auditor:r finalExam.txt
	sudo setfacl -m g:uni_x_sysadmin:r finalExam.txt
	#Course auditors can only view the final exam marks
	sudo setfacl -m g:course_auditor:r finalExamMarking.txt
	sudo setfacl -m g:uni_x_sysadmin:--- finalExamMarking.txt

	cd ..

	#By default, no one else can read what will be in the course directory
	sudo setfacl -dm o::--- $1
	#Students and Course Auditors can only read the lecture notes
	#Have to let sysadmins have read access to future files in directory
	sudo setfacl -dm g:uni_x_sysadmin:r,g:student:r,g:course_auditor:r $1

	#Start auditing for this course directory
	start_audit $1 "/home/UniX/${1}"
}

# Method to add an assignment to a course directory
add_assignment() {

	echo "Adding assignment $1 to course $2"
	cd /home/UniX/$2

	sudo mkdir Assignment-$1

	#Folder students can view their marks
	student_marks="Assignment-$1-student-marks"
	sudo mkdir $student_marks
	#Assume course auditors can copy over assingment marks when finished checking
	sudo setfacl -m g:course_auditor:rwx,g:lecturer:--- $student_marks
	#By default, no one should be further editing what is copied here
	sudo setfacl -dm g:course_coordinator:r,g:student:r,u::r $student_marks
	#Revert some defaults for this folder
	sudo setfacl -m g:course_coordinator:rx,g:student:rx,g:uni_x_sysadmin:rwx $student_marks

	#Allow students to enter the assignments directory and write/add to it (for submissions)
	#Tutors are also students who need to be able to create marking files
	sudo setfacl -m g:student:wx Assignment-$1
	sudo setfacl -m o::---,g:lecturer:--- Assignment-$1
	sudo setfacl -dm g::---,o::--- Assignment-$1
	#Set permissions for those who can enter the directory and what the default should be for future files
	sudo setfacl -m g:tutor:rx,g:course_auditor:rx,g:uni_x_sysadmin:rwx Assignment-$1
	sudo setfacl -dm g:tutor:r,g:course_auditor:r,g:student:--- Assignment-$1
	#Revert defaults for course coordinators
	sudo setfacl -dm g:course_coordinator:r Assignment-$1
	sudo setfacl -m g:course_coordinator:rx Assignment-$1

	#Start auditing these two directories
	start_audit "${2}-Assignment-${1}" "/home/UniX/${2}/Assignment-${1}"
	start_audit "${2}-Assignment-${1}-student-marks" "/home/UniX/${2}/Assignment-${1}-student-marks"
}

#Setup execution

# Call add_group for the different types of groups we want created
add_group "lecturer"
add_group "student"
add_group "course_coordinator"
add_group "course_auditor"
add_group "tutor"
add_group "uni_x_sysadmin"

#Create the main folder for the University of X's files
cd /home/
#need to sudo as we are in the /home/ directory
sudo mkdir UniX
echo "Created UniX directory"

#Create the users
#lecturers
add_user "x10101" "lecturer" "lecturer"
add_user "x22222" "lecturer" "lecturer"

#course coordinators
add_user "x44444" "lecturer,course_coordinator" "course_coordinator"
add_user "x34872" "lecturer,course_coordinator" "course_coordinator"
add_user "x69784" "lecturer,course_coordinator" "course_coordinator"

#course auditors
add_user "x55555" "lecturer,course_auditor" "course_auditor"
add_user "x65456" "lecturer,course_auditor" "course_auditor"

#students & tutors
add_user "x80912" "student" "student"
add_user "x77777" "student" "student"
add_user "x88854" "student,tutor" "tutor"
add_user "x70041" "student,tutor" "tutor"
add_user "x88877" "student,tutor" "tutor"
add_user "x70707" "student,tutor" "tutor"
add_user "x89744" "student,tutor" "tutor"

#sysadmin
add_user $sysadmin "uni_x_sysadmin" "uni_x_sysadmin"

#change UniX owner to sysadmin and their group
sudo chown $sysadmin:uni_x_sysadmin UniX

#Create the .logs folder, restrict access and set system admins as the owners
sudo mkdir $audit_root
restrict_access $audit_root
sudo chown $sysadmin:uni_x_sysadmin $audit_root
#Allow the admins to have a readonly view of the folder
sudo setfacl -m u::rx,g:uni_x_sysadmin:rx $audit_root
#And for future log (folders), no one to see them apart from admins 
sudo setfacl -dm g::---,o::--- $audit_root
sudo setfacl -dm u::rx,g:uni_x_sysadmin:rx $audit_root
#Set up a new folder in the .logs directory for today's date
set_up_audit_folder $(/bin/date +%F)

#System admins have full control so give them the same permissions
sudo setfacl -dm g:uni_x_sysadmin:rwx UniX
sudo setfacl -m g:uni_x_sysadmin:rwx UniX

#enter the UniX directory and set up final student marks files
cd UniX
echo "Entered UniX directory"

#Loop through all the students to set up their final mark files
students=$(members student)
#$students will be a space-delimited string, update the IFS - internal field separator - variable to reflect this
oldIFS=$IFS
IFS=$' '
#loop through each student...
for s in $students
do
	#create the final marks file
	sudo touch $s.txt
	#change owner to sysadmin and their group
	sudo chown $sysadmin:uni_x_sysadmin $s.txt
	#user by default can rw, revert this
	sudo setfacl -m u::--- $s.txt
	#restrict everyone from doing anything with this file
	restrict_access "$s.txt"
	#allow course coordinators to edit it
	sudo setfacl -m g:course_coordinator:rw $s.txt
	#allow the individual student to only view it
	sudo setfacl -m u:$s:r $s.txt
	echo "Created final student marks file $s.txt"

	#revert rwx default set for sysadmin group
	sudo setfacl -m g:uni_x_sysadmin:--- $s.txt
	#prevent the mask from limiting the permissions that have been set
	sudo setfacl -m m::rw $s.txt
done
IFS=$oldIFS

#Create some courses and assignments
create_course "C101" "x44444" "x88854, x70041, x88877"
add_assignment "A001" "C101" "x44444"
add_assignment "A002" "C101" "x44444"
create_course "C102" "x34872" "x88877, x70707, x89744, x70041"
add_assignment "A003" "C102" "x34872"
add_assignment "A007" "C102" "x34872"

#Wait for audit files to be set up 
sleep 3

#Final reporting

echo
echo "Finished set up"
echo "Created file system is as follows:"
sudo tree -paug /home/UniX
echo
echo "ACL for UniX directory"
sudo getfacl /home/UniX/
echo
echo "ACL for an example student file"
sudo getfacl /home/UniX/x77777.txt
echo
echo "ACL for an example course directory"
sudo getfacl /home/UniX/C101
echo
echo "ACL for an example course info file"
sudo getfacl /home/UniX/C101/C101.txt
echo
echo "ACL for an example course final exam"
sudo getfacl /home/UniX/C101/finalExam.txt
echo
echo "ACL for an example course final exam marking file"
sudo getfacl /home/UniX/C101/finalExamMarking.txt
echo
echo "ACL for an example course assignment directory"
sudo getfacl /home/UniX/C101/Assignment-A001
echo
echo "ACL for an example course assignment directory for student marks"
sudo getfacl /home/UniX/C101/Assignment-A001-student-marks
echo
echo "ACL for the audit-logs directory"
sudo getfacl /home/UniX/.logs