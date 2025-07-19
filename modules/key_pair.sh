#!/bin/bash

check_key_pair() {
    echo "Searching for existing key-pair(s)..."

    # Get a list of existing key pairs in local folder.
    mapfile -t key_list < <(aws ec2 describe-key-pairs --query "KeyPairs[*].[KeyName]" --output text)

    KEY_NUM=${#key_list[@]}

    # Display a list of keys.
    if [[ $KEY_NUM -eq 0 ]]; then
        echo "No key-pair(s) found."
        return 1

    elif [[ -n ${!key_list[@]} ]]; then
        echo "Existing key-pair(s) found."

        for i in "${!key_list[@]}"; do
            name=$(echo "${key_list[$i]}" | awk '{print $1}')
            echo "$((i + 1)). $name"
        done
        echo ""
    else
        return 1
    fi

    # Select an existing key or create a new one.
    while true; do
        echo "Select an exisitng key-pair (or) Create a new key-pair?"
        read -p "Type 'select' or 'create': " action

        action=$(echo "$action" | tr '[:upper:]' '[:lower:]')

        case "$action" in
            select)
                if [[ $KEY_NUM -eq 1 ]]; then
                    SELECTED_KEY=$name
                    echo ""
                    echo "Selected key-pair: $SELECTED_KEY"
                else
                    #prompt user to select
                    while true; do
                        read -p "Select a key-pair (1 - $KEY_NUM): " choice
                        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= KEY_NUM)); then
                            SELECTED_KEY=$(echo "${key_list[((choice - 1))]}" | awk '{print $1}')
                            echo ""
                            echo "Selected key-pair: $SELECTED_KEY"
                            break
                        else
                            echo "Invalid choice. Please enter a number between 1 and $KEY_NUM"
                        fi
                    done
                fi
                break
                echo ""
                ;;
            create)
                create_key_pair
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

create_key_pair() {
    echo ""
    echo "Creating a new key-pair..."

    # specify key-name and key-region.
    while true; do
        read -p "Enter a name: " KEY_NAME
        if [[ -n $KEY_NAME ]]; then
            break
        else
            echo "Input cannot be empty. Please enter a valid name."
        fi
    done

    read -p "Enter a region (default: us-east-1): " KEY_REGION
    echo ""
    KEY_REGION=${KEY_REGION:-us-east-1}
    
    # ensure target directory exists.
    mkdir -p ~/.aws/

    # aws command to create a key pair.
    aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query "KeyMaterial" \
    --region $KEY_REGION \
    --output text > ~/.aws/"$KEY_NAME".pem

    # Change file permissions to read only. Mandatory.
    if [ $? -eq 0 ]; then
        SELECTED_KEY=$KEY_NAME
        chmod 400 ~/.aws/$KEY_NAME.pem
        echo "'$KEY_NAME' created and saved to ~/.aws/$KEY_NAME.pem successfully."
    else
        echo "Failed to create key-pair."
        return 1
    fi
}

read -p "Press Enter to continue..."
