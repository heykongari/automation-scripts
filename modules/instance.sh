#!/bin/bash

launch_instances() {
    echo "Preparing to launch ec2 instnce(s)..."
    echo "Free-tier eligible AMI-IDs in (us-east-1):"
    echo ""

    # associative array
    declare -A ami_list
    ami_list["amazon-linux-6.1"]="ami-0150ccaf51ab55a51"
    ami_list["amazon-linux-6.12"]="ami-050fd9796aa387c0d"
    ami_list["ubuntu-24.04"]="ami-020cba7c55df1f615"
    ami_list["ubuntu-22.04"]="ami-0a7d80731ae1b2435"

    for item in "${!ami_list[@]}"; do
        echo "- $item (${ami_list[$item]})"
    done

    echo ""
    echo "1. Select ami-id from the above list."
    echo "2. Enter your own ami-id."

    while true; do
        read -p "Select (1 or 2): " choice
        echo ""
        if [[ "$choice" == "1" ]]; then
            read -p "Enter the name of the AMI (e.g., ubuntu-24.04): " option
            if [[ -n "${ami_list[$option]}" ]]; then
                SELECTED_AMI_ID="${ami_list[$option]}"
                read -p "Enter the region for AMI (default: us-east-1): " SELECTED_AMI_REGION
                SELECTED_AMI_REGION="${SELECTED_AMI_REGION:-us-east-1}"
                echo "Selected AMI-ID: $SELECTED_AMI_ID"
                break
            else
                echo "Invalid name. Please type exactly as shown in the list."
            fi

        elif [[ "$choice" == "2" ]]; then
            read -p "Enter a valid AMI-ID (e.g., ami-020cba7c55df1f615): " AMI_ID
            if [[ $AMI_ID == ami-* ]]; then
                SELECTED_AMI_ID="$AMI_ID"
                read -p "Enter the region for AMI (default: us-east-1): " SELECTED_AMI_REGION
                SELECTED_AMI_REGION="${SELECTED_AMI_REGION:-us-east-1}"
                echo "Selected AMI-ID: $SELECTED_AMI_ID"
                break
            else
                echo "Invalid AMI-ID format. Must start with 'ami-'."
            fi

        else
            echo "Invalid selection. Please choose 1 or 2."
        fi
    done
    echo ""

    echo "How many instance(s) do you wish to launch?"
    while true; do
        read -p "Enter a number: " count
        if [[ "$count" =~ ^[1-9]$ ]]; then
            INSTANCE_COUNT=$count
            break
        else
            echo "Invalid input. Enter a number."
        fi
    done
    echo ""

    echo "Launching $INSTANCE_COUNT EC2 instance(s)..."
    INSTANCE_IDS=$(aws ec2 run-instances \
    --image-id "$SELECTED_AMI_ID"\
    --count "$INSTANCE_COUNT" \
    --instance-type t2.micro \
    --key-name "$SELECTED_KEY"\
    --security-group-ids "$SELECTED_SG_ID"\
    --region "$SELECTED_AMI_REGION" \
    --query "Instances[*].InstanceId" \
    --output text)

    if [[ -n $INSTANCE_IDS ]]; then
        echo "Waiting for instances to enter 'running' state..."
        aws ec2 wait instance-running --instance-ids $INSTANCE_IDS

        echo "Launched instance(s) successfully."
        aws ec2 describe-instances \
        --query "Reservations[*].Instances[*].[ImageId,InstanceId,PublicIpAddress]" \
        --output table
    else
        echo "Failed to launch instance(s)."
        return 1
    fi

}

read -p "Press enter to continue..."
