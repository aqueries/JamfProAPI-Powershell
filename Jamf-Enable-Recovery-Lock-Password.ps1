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

function getAuth() {
    $uri = "https://$JamfTennantId/api/v1/auth/token"
    
    # Check if a token exists in the environment
    if ($env:JamfToken) {
        Write-Host "Using existing token."
        return @{
            'token' = $env:JamfToken
        }
    } else {
        $creds = Get-Credential

        $call = Invoke-RestMethod -Method Post -Credential $creds -Authentication Basic -Uri $uri -ContentType "application/json;charset=UTF-8"
        
        # Store the token in the environment
        $env:JamfToken = $call.token

        return $call
    }
}


function endAuth($token)
{
    $uri = "https://$JamfTennantId/api/v1/auth/invalidate-token"
    $headers = @{Authorization = "Bearer $token"}
    Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
    
}

function getComputersFromAdvancedSearch($searchId)
{
    
    $uri = "https://$JamfTennantId/JSSResource/advancedcomputersearches/id/$searchId"
    Write-Host $uri
    $headers = @{Authorization = "Bearer $token"; "Content-Type" = "application/json; charset=utf-8"}

    #$call = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers).results

    $call = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

    Write-Host $call

    return $call
}
###################################
## Authenticate
###################################

$token = getAuth
$token = $token.token

###################################
## Runtime
###################################

#Get All computers from the Jamf pro Advanced Search by the ID.
#You may enter the ID number below if desired (string)

$searchId="90"

if (-not $searchId) {
    # Prompt the user for the ID number
    $searchId = Read-Host "Please enter the number of the advanced computer search you want to send the command to"
}

$recoveryPassword="http80Webserver#$"

if (-not $recoveryPassword) {
    # Prompt the user for the desired recovery password
    $searchId = Read-Host "Please enter the recovery password you would like to set on these computers"
}

$computerIds = @()

$computers = getComputersFromAdvancedSearch($searchId)
Write-Host $computers

foreach ($computer in $computers) {
    Write-Host $computer
}



#endAuth($token)
<#


foreach ($computer in $computers) 
{
    $computerIds = $computerIds + $computer.id
}

$count = 0

#loop through Computer IDs.
foreach ($computerId in $computerIds)
{   
    $count++
    Write-Host "Computer No:" $count -ForegroundColor Yellow
    Write-Host "Computer ID:" $computerId
    #Get Detailed info for Computer
    $computerDetails = getComputerDetail -computerId $computerId
    Write-Host "Computer Name:" $computerDetails.general.name
    Write-Host "Attatchment IDs:" $computerDetails.attachments.id
    Write-Host "Attatchment Names:" $computerDetails.attachments.name
    Write-Host ""
    #Get attatchments and put IDs into a list.
    $attatchmentIds = $computerDetails.attachments.id
    #Loop over attatchment list and delete attatchment.
    foreach ($attatchmentId in $attatchmentIds) {
        Write-Host "This attatchment ID is:" $attatchmentId
        deleteAttatchment -computerId $computerId -attatchmentId $attatchmentId
    }

}
#>