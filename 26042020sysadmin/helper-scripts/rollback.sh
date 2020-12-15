#!/bin/bash
# rollback - A script to revert changes made from setup.sh

cd /home/

sudo userdel x10101
sudo rm -rf x10101
sudo userdel x22222
sudo rm -rf x22222
sudo userdel x44444
sudo rm -rf x44444
sudo userdel x34872
sudo rm -rf x34872
sudo userdel x69784
sudo rm -rf x69784
sudo userdel x55555
sudo rm -rf x55555
sudo userdel x65456
sudo rm -rf x65456
sudo userdel x80912
sudo rm -rf x80912
sudo userdel x77777
sudo rm -rf x77777
sudo userdel x88854
sudo rm -rf x88854
sudo userdel x70041
sudo rm -rf x70041
sudo userdel x88877
sudo rm -rf x88877
sudo userdel x70707
sudo rm -rf x70707
sudo userdel x89744
sudo rm -rf x89744
sudo userdel x99999
sudo rm -rf x99999

echo "Deleted Uni X accounts and their home directories"

sudo groupdel lecturer
sudo groupdel student
sudo groupdel course_coordinator
sudo groupdel course_auditor
sudo groupdel tutor
sudo groupdel uni_x_sysadmin

echo "Deleted Uni X groups"

sudo rm -rf UniX

echo "Deleted Uni X core directory"

# stop ongoing ls commands started by the audit methods in setup.sh
killall setup.sh