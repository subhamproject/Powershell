############################   Candidate Validity check   ############################

if(-not (Get-Service 'ibm-ucdagent')){ return 'No uDeploy service => java Not required' }
if((Get-Service 'aspire' -ea SilentlyContinue)){ return 'aspire service => use aspire package' }

Set-Location $PSScriptRoot -ea Stop
### variables

$services = "ibm-ucdagent"
$processes = 'iexplore',"java*"
$uninstall_software_name = "Java ? Update *"
$install_dir = 'C:\Program Files\java\jre'
$install_arguments =  ' INSTALLDIR="'+$install_dir+'" INSTALL_SILENT=Enable AUTO_UPDATE=Disable REBOOT=Disable'

##############################    Pre steps  ##########################
Try{ 
    Get-Service -Name $services | Stop-Service -ea Stop -wa SilentlyContinue
    Get-Process $processes -ea SilentlyContinue | ? path -Like "C:\Program Files\Java*" | Stop-Process -Force -ea Stop
}Catch{
    return 'failed to stop service/process: '+$_
}

################################    uninstall java  ##########################################

$Applications = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$Applications += Get-ChildItem 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -ea SilentlyContinue

foreach ($App in $Applications){ 
    $name = $app.GetValue('DisplayName')
    if($name -like $uninstall_software_name) {
        $UninstallString = $app.GetValue('UninstallString') -replace 'MsiExec.exe',''
        Try{           
            Start-Process 'MsiExec.exe' -ArgumentList "$UninstallString /quiet /norestart" -Wait -LoadUserProfile -NoNewWindow  -ea stop
            if(gi ($app.PSPath) -ea SilentlyContinue){
                return "Uninstalled could not complete fully"
            }
            $unInstalled = $true
        }Catch{
            return "failed to uninstall $name : $UninstallString "+$_
        }
    }
}

# Remove-Item HKLM:\SOFTWARE\JavaSoft -Force -Recurse -ea SilentlyContinue
# Remove-Item HKLM:\SOFTWARE\Wow6432Node\JavaSoft -Force -Recurse -ea SilentlyContinue
Try { if(Test-path $install_dir){ Remove-Item $install_dir -Force -Recurse -ea Stop } }
Catch{  return "$install_dir files are in use"  }


########################          Install Java ##########################################

$exe = @(gi *.exe | select FullName,@{n='ProductVersion';e={$_.VersionInfo.ProductVersion}} | sort ProductVersion -Descending | select -ExpandProperty FullName)[0]
if(-not $exe){ return " no installer found" }

Try{ Start-Process $exe -ArgumentList $install_arguments -Wait -LoadUserProfile -NoNewWindow -ea stop }
Catch{ return " failed to install: "+$_ }


#########################   Post actions   ####################################

Try { 
    Get-Service -Name $services | Start-Service -ea Stop -wa SilentlyContinue
}Catch{
    return " uninstalled: $unInstalled; failed to start service : "+$_
}

Start-Sleep 5
Try{
    $file = gc 'E:\ProgramFiles\ibm-ucd\agent\var\log\agent.out' -ea Stop -Tail 3
    if($file){
        if($file | Select-String 'HTTP connection successful' -Quiet){
            return " uninstalled: $unInstalled; all Success"
        }else{
            return (" uninstalled: $unInstalled; "+'"HTTP connection successful" string not found in E:\ProgramFiles\ibm-ucd\agent\var\log\agent.out ; notify app owner')
        }

    }else{
        return (" uninstalled: $unInstalled; " +'no data found in E:\ProgramFiles\ibm-ucd\agent\var\log\agent.out ; notify app owner')
    }
}Catch{
    return (" uninstalled: $unInstalled; " +'ibm file not found E:\ProgramFiles\ibm-ucd\agent\var\log\agent.out ; notify app owner')
}


return "all success,  uninstalled old : $unInstalled; "

