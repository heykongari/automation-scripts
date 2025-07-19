#!/bin/bash

launch_instances() {
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
}

read -p "Press Enter to continue..."
