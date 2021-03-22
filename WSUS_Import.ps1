### WSUS Automation Script
### Created by Eric Stevens
### Last updated 03/22/2021

<#
The goal of this script is to simplify the wsuscontent transfer, import, cleanup and approval process for disconnected WSUS environments.

All functions are optional and can be switched on or off by commenting out the function you don't want.
#>

$patchday = Read-host "Please enter the first day of the month you are patching in MM/DD/YYYY format. Example: 03/01/2021"
$WsusLocation = Get-ItemPropertyValue -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Update Services\Server\Setup\" -Name "ContentDir"
$metafile = Get-ChildItem $PSScriptRoot\* -include "*.xml.gz" | Select-Object Name -ExpandProperty Name
[String]$updateServer1 = hostname
[Boolean]$useSecureConnection = $False
[Int32]$portNumber = 8530
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$updateServer = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($updateServer1,$useSecureConnection,$portNumber)
$updatescope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$u = $updateServer.GetUpdates($updatescope)
$install = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::Install
$group = $updateServer.GetComputerTargetGroups() | Where-Object {$_.Name -eq "Update Testing"}

function Transfer-Content {
    $options = "/e" #insert any additional options you want inside the quotations.
    Write-host "
    Transferring latest wsuscontent from this drive into your wsuscontent repo. Please wait." -ForeGroundColor green
    Start-Process -FilePath "robocopy.exe" -ArgumentList "$PSScriptRoot\WsusContent $WsusLocation\WsusContent $options" -wait -passthru
}

function Import-metadata {
    Write-host "
    Importing the latest metadata into your WSuS Server. Please wait." -ForeGroundColor Green
    Start-process -FilePath "C:\Program Files\Update Services\Tools\Wsusutil.exe" -ArgumentList "import $PSScriptRoot\$metafile $WsusLocation\import.log" -wait -passthru
}

function Clean-WSUS {
    Write-Host "
    Performing all functions of the WSUS cleanup wizard except for removing obsolete computers. Please wait." -ForeGroundColor green
    Get-WsusServer | Invoke-WsusServerCleanup -DeclineExpiredUpdates -DeclineSupersededUpdates -CleanupObsoleteUpdates
}

function Decline-Superseded {
    Write-host "Declining Superseded updates..." -foregroundcolor green
    $count = 0
    foreach ($u1 in $u)
        {
        if ($u1.IsSuperseded -eq 'True')
            {
                $u1.Decline()
                $count = $count + 1
            }
        }
    write-host Total Declined Updates: $count
    }

function Approve-Nonsuperseded {
    Write-host "Creating new Computer Group to approve updates for installation..." -foregroundcolor green
    try {
        $updateserver.CreateComputerTargetGroup("Update Testing") 
        }
    catch {
        Write-host "Update Group already exists. Moving on..." -ForegroundColor Green
        }

    $count = 0
    Write-host "Approving new updates for installation..." -foregroundcolor green
    foreach ($u2 in $u )
        {
        if ($u2.IsDeclined -ne 'True' -and $u2.IsSuperseded -ne 'True' -and $u2.CreationDate -ge $PatchDay)
            {
                write-host Approving Update : $u2.Title
                $u2.Approve($install,$group)
                $count = $count + 1
            }
        }
    write-host Total Approved Updates: $count
}


Transfer-Content
Import-metadata
Clean-WSUS
Decline-Superseded
Approve-Nonsuperseded

Write-Host "WSUS import script complete. You may now approve the latest updates." -foregroundcolor green