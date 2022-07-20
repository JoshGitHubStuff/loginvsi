## Script Variables
$global:url = "FQDN"
$global:token = "API_KEY"
$global:appname = "Application_Name"
$global:response = " "

#Location where script lives
$location =  "Script_Path"

$code = @"
public class SSLHandler
{public static System.Net.Security.RemoteCertificateValidationCallback GetSSLHandler()
    {return new System.Net.Security.RemoteCertificateValidationCallback((sender, certificate, chain, policyErrors) => { return true; });}
}
"@
Add-Type -TypeDefinition $code

#Function Definitions

#API Call to get all Applications
function Get-LeApplications {
    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        orderBy   = "Name"
        direction = "Ascending"
        count     = "5000"
        include   = "none" 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:url + '/publicApi/v4/applications'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

#API Call to update script in applications
function Update-LeScript {
    Param (
        [string]$id,
        $location
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    #$Body = @{
       # scriptContent  = $location
   # }

    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:url + '/publicApi/v6-preview/applications/' + $id + '/script'
        Headers     = $header
        Method      = 'POST'
        InFile      = $location
        ContentType = 'text/plain'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response
}

#API Call to get script in Application
function Get-LeScript {
    Param (
        [string]$id
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    #$Body = @{
       # scriptContent  = $location
   # }

    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:url + '/publicApi/v6-preview/applications/' + $id + '/script'
        Headers     = $header
        Method      = 'GET'
        ContentType = 'text/plain'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response
}

#Gets ID of the application you want to update then uses it to find the correct application when the update function runs
$id = Get-LeApplications | Where -Property Name -eq $appname

#Calling Update-LeScript Function to push code saved to $location variable at the beginning of script
Update-LeScript -id $id.id -location $location