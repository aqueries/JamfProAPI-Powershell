<#
.SYNOPSIS
This is a script which deletes all computer attatchment files for all Macs enrolled in a Jamf Pro MDM.

.DESCRIPTION
I had a requirment to delete all Mac computer attatchments in our jamf tennant and there were no examples or pre-existing scripts out there so I made this bad boi up.
It was created in powershell Core 7.1.4 on MacOS.

Use this script at your own risk.

#>

###################################
## Global Variables
###################################
#Change the below variable to your Jamf Pro DNS name.
#If your Jamf Pro instance is running on a different port add the port to the below string as well.
#E.G: tenant.jamfcloud.com or jamf.domain.com:8443
$JamfTennantId = "tennant.jamfcloud.com"

###################################
## Functions
###################################

function getToken() {

    $Username = "jamfapiuser"
    $Password = "jamfapipassword"

    $pair = "$($Username):$($Password)"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"

    $headers=@{}
    $headers.Add("Accept", "*/*")
    $headers.Add("Authorization", $basicAuthValue)    
    $response = Invoke-WebRequest -Uri "https://$JamfTennantId/api/v1/auth/token" -Method POST -Headers $headers
    return ConvertFrom-Json $response.Content
}

function getComputersFromAdvancedSearch($searchId) {
    $token = getToken
    $RealToken = $token.token
    $tokenAuth = "Bearer $RealToken"

    $headers=@{}
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $tokenAuth)
    $response = Invoke-WebRequest -Uri "https://$JamfTennantId/JSSResource/advancedcomputersearches/id/$searchId" -Method GET -Headers $headers

    #return $response
    return (ConvertFrom-Json $response.Content).advanced_computer_search.computers

    }

function getComputerManagementIdByComputerId($computerId) {
    $token = getToken
    $RealToken = $token.token
    $tokenAuth = "Bearer $RealToken"

    $headers=@{}
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $tokenAuth)
    $response = Invoke-WebRequest -Uri "https://$JamfTennantId/api/v1/computers-inventory-detail/$computerId" -Method GET -Headers $headers

    #return $response
    return (ConvertFrom-Json $response.Content).general.managementId

    }

function sendEnableRecoveryLockPasswordMDMCommand ($computerManagmentId) {
    $token = getToken
    $RealToken = $token.token
    $tokenAuth = "Bearer $RealToken"

    $data = @{
        commandData = @{
            commandType = "SET_RECOVERY_LOCK"
            newPassword = $recoveryPassword
        }
        clientData = @(@{
            managementId = $computerManagmentId
        })
    }

    $json = $data | ConvertTo-Json
    

    $headers=@{}
    $headers.Add("Accept", "application/json")
    $headers.Add("content-type", "application/json")
    $headers.Add("Authorization", $tokenAuth)
    $response = Invoke-WebRequest -Uri "https://$JamfTennantId/api/preview/mdm/commands" -Method POST -Headers $headers -Body $json

    if ($response.StatusCode -eq 201) {
        Write-Host "Recovery Lock command sent to computer successfully"
        return "Recovery Lock command sent to computer successfully"
    }
    else {
        Write-Host "Something went wrong. Please check error for more details"
        return $response
    }
    
}
    
###################################
## Runtime
###################################

#Get All computers from the Jamf pro Advanced Search by the ID.
#You may enter the ID number below if desired (string)

$searchId=""

if (-not $searchId -or $searchId -eq "") {
    # Prompt the user for the ID number
    $searchId = Read-Host "Please enter the number of the advanced computer search you want to send the command to"
}

$recoveryPassword=""

if (-not $recoveryPassword -or $recoveryPassword -eq "") {
    # Prompt the user for the desired recovery password
    $searchId = Read-Host "Please enter the recovery password you would like to set on these computers"
}

$computers = getComputersFromAdvancedSearch($searchId)
#Write-Host $computers
foreach ($computer in $computers) {
    Write-Host "Processing computer:" $computer.name -ForegroundColor Yellow
    $computerManagmentId = getComputerManagementIdByComputerId($computer.id)
    Write-Host "Managment ID is:" $computerManagmentId -ForegroundColor Green
    sendEnableRecoveryLockPasswordMDMCommand($computerManagmentId)
    

}