#!/bin/bash

launch_instances() {
    echo "List of free-tier-eligible AMI-IDs in (us-east-1)..."

    # associated array
    declare -A ami_list
    ami_list["AmazonLinux1"]="ami-05ffe3c48a9991133"
    ami_list["AmazonLinux2"]="ami-000ec6c25978d5999"
    ami_list["Ubuntu1"]="ami-020cba7c55df1f615"
    ami_list["Ubuntu2"]="ami-0a7d80731ae1b2435"

    i=1
    for item in "${!ami_list[@]}"; do
        echo "$i. $item (${ami_list[$item]})"
        ((i++))
    done
    total=$((i - 1))

    echo ""
    echo "Select an AMI-ID from the list (or) Enter your own AMI-ID."
    read -p "Type 'select' or 'id' : " action
    action=$(echo "$action" | tr '[:upper:]' '[:lower:]')

    case "$action" in
        select)
            echo ""
            while true; do
                read -p "Select an AMI-ID from the list (1 - $total): " choice
                if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= $total )); then
                    SELECTED_AMI_ID=${ami_list[$choice]}
                    echo "Selected AMI-ID: $SELECTED_AMI_ID"
                    break
                else
                    echo "Invalid choice. Please enter a number between 1 and $total."
                fi
            done
            ;;
        *)
            echo "Invalid input. Try again."
            return 1
            ;;
    esac

}

read -p "Press Enter to continue..."