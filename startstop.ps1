$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID);

# Get the security principal for the administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;

# Check to see if we are currently running as an administrator
if ($myWindowsPrincipal.IsInRole($adminRole))
{
    # We are running as an administrator, so change the title and background colour to indicate this
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)";
    $Host.UI.RawUI.BackgroundColor = "DarkBlue";
    Clear-Host;
}
else {
    # We are not running as an administrator, so relaunch as administrator

    # Create a new process object that starts PowerShell
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";

    # Specify the current script path and name as a parameter with added scope and support for scripts with spaces in it's path
    $newProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"

    # Indicate that the process should be elevated
    $newProcess.Verb = "runas";

    # Start the new process
    [System.Diagnostics.Process]::Start($newProcess);

    # Exit from the current, unelevated, process
    Exit;
}
$Time = Get-Date -Format g
$olddate = [DateTime]::MaxValue
$newdate = [DateTime]::MinValue
$newfn = ""
$newFileName =""
$FileNameDate = Get-Date
 $Day = $FileNameDate.Day
 $Month = $FileNameDate.Month
 $Year = $FileNameDate.Year
 $Hour = $FileNameDate.Hour
 $Minute = $FileNameDate.Minute
 $Seconds = $FileNameDate.Second
 $newFileName = "$Day$Month$Year$Hour$Minute$Seconds"

Try
{
$ErrorActionPreference = "Stop";

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
[xml]$XmlDocument = Get-Content "$scriptDir\Services.xml"  -ErrorAction Stop
$logPath = "$scriptDir\logs" 
$directoryInfo = Get-ChildItem $logPath | Measure-Object 
get-childitem $logPath | ForEach-Object {
    if ($_.LastWriteTime -lt $olddate -and -not $_.PSIsContainer) {
        $oldfn = $_.Name
        $olddate = $_.LastWriteTime
    }
    if ($_.LastWriteTime -gt $newdate -and -not $_.PSIsContainer) {
        $newfn = $_.Name
        $newdate = $_.LastWriteTime
    
}

 
 }
$logFileName = $newfn;
$logFile = "$logPath\$logFileName"
#Write-Host $logFfileName
if((Get-Item $logFile).length -gt 5kb -or $directoryInfo.Count -le 0)
{
 $logFile = "$logPath\$newFileName.log"
 Add-content $logFile -Value ""
}

#Loop to read through Services in XML file
$i = 0
foreach($service in $XmlDocument.Services.Service)
{

[string]$serviceName = $service.Name
[string]$DisplayName = $service.DisplayName

 $i= $i+1
 $arrService = Get-Service -Name $ServiceName
 if ($arrService.Status -ne "Running"){
    Add-Content $logFile "$Time, $DisplayName, Service is stopped, starting service"
    Start-Service $ServiceName
    Add-Content $logFile "$Time, $DisplayName, Service is started"
  }
  else
  {
   Add-Content $logFile "$Time, $DisplayName, Service is running, stopping service"
   Stop-Service $ServiceName
   Start-Service $ServiceName
   Add-Content $logFile "$Time, $DisplayName, Service is started"
  }
}
}
Catch
{
 $ErrorActionPreference = "Continue";
$ErrorMessage = $_.Exception.Message
Write-Host  "An exception occured, $ErrorMessage"
 Break
}
finally
{
$Server = Read-Host -Prompt 'Press enter to continue'
}
 
