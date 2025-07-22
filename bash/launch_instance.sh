#!/bin/bash

# Function to launch an EC2 instance on Ubuntu 24.04 OS
launch_instance() {

    echo "Loading key-pair and security group details..."

    # Select an existing key pair.
    KEY_NAME=$(aws ec2 describe-key-pairs --query "KeyPairs[0].KeyName" --output text)
    if [[ -n $KEY_NAME ]]; then
        echo "Key Pair: $KEY_NAME.pem"
    else
        echo "Error: Missing Key Pair."
        exit 1
    fi

    # Select an existing security group.
    SG_ID=$(aws ec2 describe-security-groups --query "SecurityGroups[0].GroupId" --output text)
    if [[ -n $SG_ID ]]; then
        echo "Security Group ID: $SG_ID"
    else
        echo "Error: Missing Security Group."
        exit 1
    fi

    # Launch EC2 instance. Limited to 9 instance(s) at once.
    while true; do
        echo ""
        read -p "Number of instance(s) to launch: " choice
        if [[ $choice =~ ^[0-9]+$ ]] && (( choice >= 1 )); then
            INSTANCE_ID=$(aws ec2 run-instances \
            --image-id ami-020cba7c55df1f615 \
            --instance-type t2.micro \
            --count $choice \
            --key-name $KEY_NAME \
            --security-group-ids $SG_ID \
            --query "Instances[*].InstanceId" \
            --output text)
            break
        else
            echo "Invalid Input. Try Again."
        fi
    done

    if [[ $? -eq 0 && -n $INSTANCE_ID ]]; then
        echo ""
        echo "Launched $choice EC2 Ubuntu 24.04 instance(s) successfully!"
        echo "Loading Instance info..."
        
        # wait for instance to enter 'running' state.
        #aws ec2 wait instance-running --instance-ids $INSTANCE_ID

        # Display details in tabular format.
        aws ec2 describe-instances \
        --query "Reservations[*].Instances[*].[ImageId,InstanceId,PublicIpAddress]" \
        --output table
    else
        echo "Failed to launch instance(s)."
        return 1
    fi
}

launch_instance