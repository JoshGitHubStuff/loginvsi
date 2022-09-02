#Used to run Desktop Connector remotely on multiple systems. Provided as is, and will only work if a user is already logged into the machine.

$computers = Get-Content "Enter Path computer host list ex: C:\LoginVSI\Computers.txt"

foreach($computer in $computers) {
    $LoggedOnUser = Get-WmiObject -ComputerName $computer -Class Win32_ComputerSystem | Select-Object UserName
    $LoggedOnuser = $LoggedOnUser.UserName
    #$LoggedOnUser = "Login01"
    #On the remote computer, create a scheduled task that runs the test remotely use must already be logged in
    Write-Host "Running task on $computer....."
    Invoke-Command -ComputerName $computer -ArgumentList $LoggedOnUser -ScriptBlock {
        param($loggedOnUser)

        $SchTaskParameters = @{
            TaskName = "LE_DesktopConnector"
            Description = "-"
            Action = (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "C:\logon\Desktop-Connector.ps1") #makes sure to put in proper path to connector file.
            Settings = (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd)
            RunLevel = "Highest"
            User = $loggedOnUser
            Force = $true
        }

        #Register and Start the task
        Register-ScheduledTask @SchTaskParameters | Out-Null
        Start-ScheduledTask -Taskname "LE_DesktopConnector"

        #Wait until the task finishes before continuing the LE Test will still be running this just waits on the script to execute to kick off test.
        do {
            Write-Host "Wait on task to finish on $computer..."
            $ScheduledTaskState = Get-ScheduledTask -Taskname "LE_DesktopConnector" | Select-Object -ExpandProperty State 
            start-sleep 1
        } until ($ScheduledTaskState -eq "Ready")

        #Delete the task after finished
        Unregister-ScheduledTask -TaskName "LE_DesktopConnector" -Confirm:$false
    }
    Write-Host "Task Completed on $Computer..."
}