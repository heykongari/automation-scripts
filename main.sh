#!/bin/bash

# Load all function files
source ~/aws-ec2-launcher/modules/key_pair.sh
source ~/aws-ec2-launcher/modules/security_group.sh
source ~/aws-ec2-launcher/modules/instance.sh

while true; do
    echo "+------------------------------+"
    echo "| AWS EC2 LAUNCHER             |"
    echo "+------------------------------+"
    echo "| 1 | Create a Key Pair        |"
    echo "| 2 | Create a Security Group  |"
    echo "| 3 | Launch EC2 Instance      |"
    echo "| 4 | EXIT                     |"
    echo "+------------------------------+"
    read -p "Enter your choice [1-4]: " choice

    case $choice in
        1)
            check_key_pair
            ;;
        2)
            check_security_group
            ;;
        3)
            check_key_pair
            check_security_group
            launch_instances
            ;;
        4)
            exit 0
            ;;
        *)
            echo "Invalid Input. Try Again."
            sleep 1
            ;;
    esac
done