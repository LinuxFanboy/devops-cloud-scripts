#!/bin/bash

load_env() {
    if [[ -f .env ]]; then
        source .env
    else
        echo "Error: .env file not found."
        exit 1
    fi
}

show_help() {
    echo "Usage: $0 {start|stop|restart|status|help}"
    echo
    echo "Commands:"
    echo "  start    Start all Virtual Machines listed in the .env file"
    echo "  stop     Stop all Virtual Machines listed in the .env file"
    echo "  restart  Restart all Virtual Machines listed in the .env file"
    echo "  status   Check the power status of all Virtual Machines"
    echo "  help     Show this help message"
    echo
    echo "Ensure Azure CLI is installed and you are logged in using 'az login'."
}

manage_vm() {
    local operation=$1
    for entry in "${VM_LIST[@]}"; do
        IFS=';' read -r vm_name rg_name <<< "$entry"

        echo "Processing Virtual Machine: $vm_name (Resource Group: $rg_name)"

        case $operation in
            start)
                az vm start --name "$vm_name" --resource-group "$rg_name" --only-show-errors
                ;;
            stop)
                az vm stop --name "$vm_name" --resource-group "$rg_name" --only-show-errors
                ;;
            restart)
                az vm restart --name "$vm_name" --resource-group "$rg_name" --only-show-errors
                ;;
            status)
                az vm get-instance-view --name "$vm_name" --resource-group "$rg_name" \
                    --query "instanceView.statuses[?starts_with(code, 'PowerState/')]" --output table
                ;;
            *)
                echo "Error: Unknown operation: $operation"
                ;;
        esac
    done
}

main() {
    if [[ $# -eq 0 ]]; then
        echo "Error: No command provided."
        show_help
        exit 1
    fi

    local command=$1

    case $command in
        start|stop|restart|status)
            load_env
            manage_vm "$command"
            ;;
        help)
            show_help
            ;;
        *)
            echo "Error: Invalid command '$command'."
            show_help
            exit 1
            ;;
    esac
}

main "$@"

