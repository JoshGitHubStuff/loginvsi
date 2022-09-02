$global:fqdn = "login-ent.login.lab"
$global:token = '0NgH5yCnF0am48E-x6dF-o4R660sLqjuNE95ZXdfpTA' 
$global:response = " "
$global:testid = '03b2f1b9-2b6d-4230-aa4b-9bf1f4dc2c57'

$code = @"
public class SSLHandler
{public static System.Net.Security.RemoteCertificateValidationCallback GetSSLHandler()
    {return new System.Net.Security.RemoteCertificateValidationCallback((sender, certificate, chain, policyErrors) => { return true; });}
}
"@
Add-Type -TypeDefinition $code


function Start-Test {
    Param (
        $testId,
        $comment   
    )
 

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
    
    
    $Body = [ordered]@{
        comment = $comment
    } | ConvertTo-Json
 
    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $params = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/tests/' + $testId + '/start'
        Headers     = $header
        Method      = 'PUT'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @params
    $Response
}
function Get-Test {
    Param (
        [Parameter(Mandatory)] [string] $testId,
        [Parameter(Mandatory)] [ValidateSet('none', 'environment', 'workload', 'thresholds', 'all')] [string] $include
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        include = $include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/tests/' + $testId
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response
}
function Wait-Test {
    Param (
        [Parameter(Mandatory)] [string] $testId
    )
    
    Write-Host "Waiting for test to complete" -ForegroundColor Green
    while (((Get-Test -testId $testid -include "none").state -eq "running") -or ((Get-Test -testId $testid -include "none").state -eq "stopping")) {
        Write-Host '.' -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host "test finished" -ForegroundColor Green
}

Start-test -testid $testid -comment 'My First Remote Test'
Wait-test -testid $testid
