$global:fqdn = "FQDN"
$global:token = 'API_Key' 
$global:response = " "

$code = @"
public class SSLHandler
{public static System.Net.Security.RemoteCertificateValidationCallback GetSSLHandler()
    {return new System.Net.Security.RemoteCertificateValidationCallback((sender, certificate, chain, policyErrors) => { return true; });}
}
"@
Add-Type -TypeDefinition $code
$new = [Environment]::NewLine

#Create Main menu
function Show-Menu {
    param (
        [string]$Title = 'Login Enterprise Account Management'
    )
    Clear-Host
    Write-Host "================ $Title ================" -ForegroundColor Cyan
    $new
    Write-Host "1: To Create New User Accounts (Not Functional Yet)"
    Write-Host "2: To Create New Account Group"
    Write-Host "3: To Add Users to an Account Group"
    Write-Host "4: To Remove Users from an Account Group. #Todo add bulk account removal"
    Write-Host "5: To Delete Accounts (Not Functional yet)"
    Write-Host "Q: to Quit."
}

#Gets All Accounts in appliance
function Get-LeAccounts {
    Param (
        [string]$orderBy = "Username",
        [string]$Direction = "Ascending",
        [string]$Count = "29",
        [string]$Include = "none"
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
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/Accounts'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

#Account Group Data
function Get-LeAccountGroups {
    Param (
        [string]$orderBy = "Name",
        [string]$Direction = "Ascending",
        [string]$Count = "50",
        [string]$Include = "none"
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
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/account-groups'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function New-LeAccountGroup {
    [CmdletBinding(DefaultParametersetName = 'None')] 
    Param (
        [Parameter(Position = 0, Mandatory = $true)] [string]$Name,
        [Parameter(ParameterSetName = 'Filter', Mandatory = $true)][switch]$Filter,      
        [Parameter(ParameterSetName = 'Filter', Mandatory = $true)][string]$Condition,
        [Parameter(Mandatory = $true)][string]$Description,
        [Array]$MemberIds

    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    if ($Filter -eq $false) {
        $AccountGroup = @{
            '$type'     = "Selection"
            groupId     = New-Guid
            name        = $Name
            description = $Description
            memberIds   = $MemberIds
        } | ConvertTo-Json
    }
    else {
        $AccountGroup = @{
            '$type'     = "Filter"
            groupId     = New-Guid
            name        = $Name
            description = $Description
            condition   = $Condition
        } | ConvertTo-Json
    }

    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/account-groups'
        Headers     = $header
        Method      = 'POST'
        Body        = $AccountGroup
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.id
}

function Get-LeAccountGroupMembers {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$GroupId,
        [string]$orderBy = "Username",
        [string]$Direction = "Ascending",
        [string]$Count = "50"
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
        groupID   = $GroupId
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/account-groups/' + $GroupId + '/Members'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function New-LeAccountGroupMember {
    Param (
        [string]$GroupId,
        [string]$domain,
        [array]$ids
    )


    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()


    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = ConvertTo-Json @($ids) 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v6-preview/account-groups/' + $GroupId + '/members'
        Headers     = $Header
        Method      = 'POST'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function Remove-LeAccountGroups {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$GroupId,
        [array]$ids
    )
    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Body = ConvertTo-Json @($ids) 

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v6-preview/account-groups/' + $GroupId + '/members'
        Headers     = $header
        Method      = 'DELETE'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.id
}

#Getting Domain and Group Selection
Function Variable-Selection {
    #Domain Selection Menu
    Write-Host "All Domains Users Are Associated With: " -ForegroundColor Cyan

    $selectDomain | foreach -Begin {$i=0} -Process {
        $i++
        "{0} {1}" -f $i , $_
    } -outvariable menu
    $new

    $r = Read-Host "Select a Domain by number"
    $new

    Write-Host "Selecting $($menu[$r-1])" -ForegroundColor Green
    $script:domain = $menu[$r-1].Split($r)[1].Trim()
    $new

    #Group Selection Menu
    Write-Host "List of Available Groups: " -ForegroundColor Cyan

    $accountGroup | foreach -Begin {$i=0} -Process {
        $i++
        "{0} {1}" -f $i , $_.name
    } -OutVariable groupmenu
    $new

    $r = Read-Host "Select Group to add accounts to by number"
    $new

    Write-Host "Selecting $($groupmenu[$r-1].Split($r)[1])" -ForegroundColor Green
    $new

    $script:group = $groupmenu[$r-1].Split($r)[1].Trim()
    $script:groupId = $accountGroup | Where-Object -Property name -eq $group
}

Function Add-AccountToGroup {
    Variable-Selection
    #Getting number of accounts not in a group
    $script:accountsNotInGroup = $accounts | Where-Object {$_.groups.count -eq 0 -and $_.domain -eq $domain}
    $script:accountsNotInGroupCount = $accountsNotInGroup | Measure-Object

    $v = Read-Host "Select Y to add all available account to the group or N to only add selected amount of users. $($accountsNotInGroupCount.count) not in a group (y/n)?"

    #Logic to add users to group by either number needed or all users available based on the Domain Chosen
    if ($v -eq 'n') {
        $w = Read-Host "How many accounts to you want to add to this group? Currently you have $($accountsNotInGroupCount.count) not in a group.(0 will exit)"
        
        if(($w-1) -gt $accountsNotInGroupCount.count -and $w -ne 0) {
            Write-Host "Sorry you don't have that many avaiable accounts" -ForegroundColor Red
        }
        elseif($w -eq 0) {
            Write-Host "You entered 0 returning you to the Main Menu"
            break
        }
        else {
            
            #adding accounts to group
            Write-Host "Adding $w user accounts to selected group" -ForegroundColor Magenta
            $new

            New-LeAccountGroupMember -GroupId $groupId.groupId -ids $accountsNotInGroup[0..($w-1)].id

            #$accountGroupMembers = Get-LeAccountGroupMembers -GroupId $groupId.groupId

            Write-Host "The follow accounts were added to $group"
            $accountsNotInGroup[0..($w-1)].username
            #$accountGroupMembers | Select-Object -Property id, username, domain
        }

    }
    elseif ($v -eq 'y') {
        #adding all free accounts to group
        Write-Host "Adding all free user accounts to selected group" -ForegroundColor Magenta
        $new

        New-LeAccountGroupMember -GroupId $groupId.groupId -ids $accountsNotInGroup.id

        #$accountGroupMembers = Get-LeAccountGroupMembers -GroupId $groupId.groupId

        Write-Host "New members of $group account group were saved to log file"
        #$accountGroupMembers | Select-Object -Property id, username, domain
    }
    else {
        Write-Host "Invalid selection, start over please..." -ForegroundColor Red
    }
}

Function Remove-AccountFromGroup {
    Variable-Selection

    $accountGroupMembers = Get-LeAccountGroupMembers -GroupId $groupId.groupId

    Write-Host "List of Accounts in $group : " -ForegroundColor Cyan
    $new

    $accountGroupMembers | foreach -Begin {$i=0} -Process {
        $i++
        "{0} {1}" -f $i , $_.username
    } -outvariable accountRemove
    $new

    $a = Read-Host "Select Account to Remove"
    $new

    Write-Host "Selecting $($accountRemove[$a-1])" -ForegroundColor Green
    $script:removed = $accountRemove[$a-1].Split($a)[1].Trim()
    $new

    $script:accountId = ($accountGroupMembers | Where-Object username -eq $removed).id
    Remove-LeAccountGroups -GroupId $groupId.groupId -ids $accountId

    Write-Host "Removed $removed from $group"
}

##### To-Do #####
#password true up if account exists update password, if not create account
#toggle enable/disable of accounts
#Create-User
#Delete-User
#Remove-Group


#Time to do stuff
do {
    $accounts = Get-LeAccounts
    $selectDomain = $accounts.domain | Sort-Object -Unique
    $accountGroup = Get-LeAccountGroups | Select-Object -Property groupId, name, memberCount

    Show-Menu
    $new
    $selection = Read-Host "Please make a selection"
    switch ($selection) {
        '1' {"Create-User Place Holder"} 
        '2' {New-LeAccountGroup} 
        '3' {Add-AccountToGroup}
        '4' {Remove-AccountFromGroup}
        '5' {"Delete-User Place Holder"}
        'Q' {"Thanks for using my stuff"}
         Default {
            "Invalid Selection Try Again..."
        }
    }
    Pause
    
 }
 until ($selection -eq 'q')