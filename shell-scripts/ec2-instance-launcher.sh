#!/bin/bash
 
##########   CONFIGURATION   ##########

AMI="ami-020cba7c55df1f615"
INSTANCE_TYPE="t2.micro"
KEY_NAME="key"
KEY_PATH="$HOME/.ssh/${KEY_NAME}.pem"


##########   FUNCTIONS   ##########

# Define a function that checks for a valid key pair, and creates one if it doesn't exist.
create_key_pair() {

    echo "checking for a valid key pair '$KEY_NAME'..."
    
    if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" > /dev/null 2>&1; then
        echo "Key pair not found. Creating a key pair..."
        aws ec2 create-key-pair --key-name "$KEY_NAME" --query "KeyMaterial" --output text > "$KEY_PATH"
        chmod 400 "$KEY_PATH"
        echo "Key pair created and saved to $KEY_PATH"
    else
        echo "Key pair check succesful. Using $KEY_NAME key pair..."
    fi
}

# Define a function to access the default security Group ID.
get_security_group() {
    SECURITY_GROUP=$(
        aws ec2 describe-security-groups \
        --filters Name=group-name,Values=default \
        --query "SecurityGroups[*].GroupId" \
        --output text
    )
    
    echo "Security group check successful. Using $SECURITY_GROUP group..."
}

# Define a function to launch EC2 instance(s).
launch_instances() {
    read -p "How many EC2 instances do you want to launch? " INSTANCE_COUNT
    echo "Launching $INSTANCE_COUNT EC2 instance(s)..."

    INSTANCE_IDS=$(
        aws ec2 run-instances \
        --image-id "$AMI" \
        --count "$INSTANCE_COUNT" \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-group-ids "$SECURITY_GROUP" \
        --query "Instances[*].InstanceId" \
        --output text 2>&1
    )

    if echo "$INSTANCE_IDS" | grep -iq "error"; then
        echo "Failed to launch instance(s): "
        echo "$INSTANCE_IDS"
        return
    fi

    echo "Launched successfully: $INSTANCE_IDS"
    echo "Waiting for instance(s) to be in 'running' state..."
    aws ec2 wait instance-running --instance-ids $INSTANCE_IDS
    
    echo "Instance details: "
    aws ec2 describe-instances \
    --instance-ids $INSTANCE_IDS \
    --query "Reservations[*].Instances[*].[ImageId,InstanceId,PublicIpAddress]" \
    --output table
}


##########   MAIN MENU   ##########

while true; do
echo "EC2 LAUNCHER MENU"
echo "1. Launch EC2 instance(s)"
echo "2. Exit"
read -p "Enter your choice [1-2]: " CHOICE

    case $CHOICE in
        1)
            create_key_pair
            get_security_group
            launch_instances
            ;;
        2)
            exit 0
            ;;
        *)
            echo "Invalid choice. Select 1 or 2"
            ;;
    esac
done