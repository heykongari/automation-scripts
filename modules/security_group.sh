#!/bin/bash

check_security_group() {

    echo "Searching for existing security groups with ssh access..."

    # Get security groups with group name and id
    mapfile -t sg_list < <(aws ec2 describe-security-groups \
    --filters Name=ip-permission.from-port,Values=22 Name=ip-permission.to-port,Values=22 \
    --query "SecurityGroups[*].[GroupName,GroupId]" \
    --output text)

    SG_NUM=${#sg_list[@]}

    if [[ $SG_NUM -eq 0 ]]; then
        echo "No security groups found."
        return 1
    
    elif [[ -n ${!sg_list[@]} ]]; then
        echo "Existing security group(s) found."

        # Dislay a list of security groups
        for i in "${!sg_list[@]}"; do
            name=$(echo "${sg_list[$i]}" | awk '{print $1}')
            id=$(echo "${sg_list[$i]}" | awk '{print $2}')
            echo "$((i + 1)). $name ($id)"
        done
        echo ""
    else
        return 1
    fi

    while true; do
        echo "Select an existing security group (or) Create a new security group?"
        read -p "Type 'select' or 'create': " action

        action=$(echo "$action" | tr '[:upper:]' '[:lower:]')

        case "$action" in
            select)
                if [[ $SG_NUM -eq 1 ]]; then
                    SELECTED_SG_NAME=$(echo "${sg_list[0]}" | awk '{print $1}')
                    SELECTED_SG_ID=$(echo "${sg_list[0]}" | awk '{print $2}')
                    echo ""
                    echo "Selected security group: $SELECTED_SG_NAME ($SELECTED_SG_ID)"
                else
                    #prompt user to select
                    while true; do
                        read -p "Select a security group (1 - $SG_NUM): " choice
                        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= SG_NUM )); then
                            SELECTED_SG_NAME=$(echo "${sg_list[$((choice - 1))]}" | awk '{print $1}')
                            SELECTED_SG_ID=$(echo "${sg_list[$((choice - 1))]}" | awk '{print $2}')
                            echo ""
                            echo "Selected security group: $SELECTED_SG_NAME ($SELECTED_SG_ID)"
                            break
                        else
                            echo "Invalid choice. Please enter a number between 1 and $SG_NUM."
                        fi
                    done
                fi
                break
                echo ""
                ;;
            create)
                create_security_group
                break
                echo ""
                ;;
            *)
                echo "Invalid input. Try again."
                echo ""
                ;;
        esac
    done

}

create_security_group() {
    echo ""
    echo "Creating a new security group..."
    
    # Get group info.
    while true; do
        read -p "Enter a name for the security group: " SG_NAME
        read -p "Enter a short description: " SG_DESC
        if [[ -n $SG_NAME && -n $SG_DESC ]]; then
            break
        else
            echo "Name and Description cannot be empty! Please enter a valid name and description."
        fi
    done

    read -p "Enter a region (default: us-east-1) : " SG_REGION
    echo ""
    SG_REGION=${SG_REGION:-us-east-1}

    SG_ID=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "$SG_DESC" \
    --region "$SG_REGION" \
    --query "GroupId" \
    --output text 2>/dev/null)

    if [[ $? -eq 0 && -n "$SG_ID" ]]; then
        SELECTED_SG_NAME="$SG_NAME"
        SELECTED_SG_ID="$SG_ID"
        echo "Security group created successfully."
        echo "$SELECTED_SG_NAME ($SELECTED_SG_ID)"
        echo ""

        # Add ssh ingress rule
        echo "Authorizing SSH ingress rule..."
        aws ec2 authorize-security-group-ingress \
        --group-id "$SELECTED_SG_ID" \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 \
        --region "$SG_REGION" \
        --output text > /dev/null 2>&1

        if [[ $? -eq 0 ]]; then
            echo "Authorization successful."
        else
            echo "SSH Authorization failed."
            return 1
        fi
    else
        echo "Failed to create security group."
        return 1
    fi
}

check_security_group