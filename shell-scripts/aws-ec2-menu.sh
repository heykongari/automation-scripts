#!/bin/bash

check_key_pair() {

    # checking for exisiting key-pairs and mapping in an array.
    mapfile -t pem_keys < <(find ~/.ssh -type f -name "*.pem")

    # no key-pair found.
    if [[ ${#pem_keys[@]} -eq 0 ]]; then
        echo "No existing key-pair(s) found. Make sure .pem file is in ~/.ssh/ directory."
        return
    fi

    # Proceed automatically if there's only one key.
    if [[ ${#pem_keys[@]} -eq 1 ]]; then
        selected_key=$(basename "${pem_keys[0]}" .pem)
        echo "One key-pair found. Using $selected_key.pem"
        return
    fi

    # Select a key if multiple keys found.
    echo "Choose a key to proceed: ${#pem_keys[@]}"
    select key in ${pem_keys[@]}; do
        if [[ -n "$key" ]]; then
            selected_key=$(basename "$key" .pem)
            echo "Using $selected_key.pem"
            break
        else
            echo "Invalid choice. Select a valid key number."
        fi
    done
}

check_key_pair
