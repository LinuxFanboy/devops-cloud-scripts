param (
    [Parameter(Mandatory=$true)][ValidateSet("start", "stop", "restart", "status", "help")]$Command
)

function Load-Env {
    if (Test-Path ".env") {
        Get-Content ".env" | ForEach-Object {
            if ($_ -match 'VM_LIST=\((.*?)\)') {
                $global:VM_LIST = $Matches[1] -split '", "' -replace '(^"|"$)', ''
            }
        }
    } else {
        Write-Error "Error: .env file not found."
        exit 1
    }
}

function Show-Help {
    Write-Host "Usage: pwsh ./vm-mgr-azure.ps1 -Command {start|stop|restart|status|help}"
    Write-Host
    Write-Host "Commands:"
    Write-Host "  start    Start all Virtual Machines listed in the .env file"
    Write-Host "  stop     Stop all Virtual Machines listed in the .env file"
    Write-Host "  restart  Restart all Virtual Machines listed in the .env file"
    Write-Host "  status   Check the power status of all Virtual Machines"
    Write-Host "  help     Show this help message"
    Write-Host
    Write-Host "Ensure Azure CLI is installed and you are logged in using 'az login'."
}

function Manage-VM {
    param (
        [string]$Operation
    )

    foreach ($entry in $VM_LIST) {
        $split = $entry -split ';'
        $vmName = $split[0]
        $rgName = $split[1]

        Write-Host "Processing Virtual Machine: $vmName (Resource Group: $rgName)"

        switch ($Operation) {
            "start"   { az vm start --name $vmName --resource-group $rgName --only-show-errors }
            "stop"    { az vm stop --name $vmName --resource-group $rgName --only-show-errors }
            "restart" { az vm restart --name $vmName --resource-group $rgName --only-show-errors }
            "status"  { 
                az vm get-instance-view --name $vmName --resource-group $rgName `
                    --query "instanceView.statuses[?starts_with(code, 'PowerState/')]" --output table 
            }
            default   { Write-Error "Error: Unknown operation '$Operation'" }
        }
    }
}

switch ($Command) {
    "help" {
        Show-Help
    }
    "start" {
        Load-Env
        Manage-VM -Operation "start"
    }
    "stop" {
        Load-Env
        Manage-VM -Operation "stop"
    }
    "restart" {
        Load-Env
        Manage-VM -Operation "restart"
    }
    "status" {
        Load-Env
        Manage-VM -Operation "status"
    }
    default {
        Write-Error "Error: Invalid command '$Command'. Use 'help' for usage instructions."
    }
}

