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
$jamfUser = "username"

###################################
## Functions
###################################
function getAuth()
{
    $url = "https://$JamfTennantId/v1/auth/token"
    $creds = Get-Credential

    $call = Invoke-RestMethod -Method Post -Credential $creds -Authentication Basic -Uri $url -ContentType "application/json;charset=UTF-8"
    return $call

}
function getAllComputers()
{
    $section="GENERAL"
    $uri = "https://$JamfTennantId/api/v1/computers-inventory?section=$section&page-size=9999&sort=id%3Aasc"
    $headers = @{Authorization = "Bearer $token"; "Content-Type" = "application/json; charset=utf-8"}

    $call = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers).results

    return $call
}

function getComputerDetail($computerId)
{
    $uri = "https://$JamfTennantId/api/v1/computers-inventory-detail/$computerId"
    
    $headers = @{Authorization = "Bearer $token"; "Content-Type" = "application/json; charset=utf-8"}

    $call = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

    return $call
}
function deleteAttatchment($computerId, $attatchmentId)
{
    $uri = "https://$JamfTennantId/api/v1/computers-inventory/$computerId/attachments/$attatchmentId"
    
    $headers = @{Authorization = "Bearer $token"; "Content-Type" = "application/json; charset=utf-8"}

    Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers
}
###################################
## Authenticate
###################################
$token = getAuth
$token = $token.token

###################################
## Runtime
###################################

#Get All computers and put their IDs into a list.
$computers = @()
$computers = getAllComputers
$computerIds = @()
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
