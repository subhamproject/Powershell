



"=============================Starting execution===============================" >> C:\temp\ServicesRestart.log
 
Get-Date >> C:\Temp\ServicesRestart.log  #adding the timestamp to the log files
Get-Date >> C:\Temp\ExceptionError.log  #adding the timestamp to the log files
 
"=============================Starting execution===============================" >>  C:\Temp\ExceptionError.log
 
 
$ComputerList  = Get-content C:\temp\Machines.txt
 
Write-Host  "=============================Starting execution===============================" -ForegroundColor Yellow
Write-Host  "**************Loaded the machine list from C:\Temp\Machines.txt**************" -ForegroundColor Yellow


 
foreach ($computer in $computerlist  )
  #loop for each machine
{
# Check if the machine is online
    if (Test-Connection -ComputerName $computer -Count 1 -Quiet)
    {
        try
        {
           #ADDING LOG
           Write-Host  "Working on machine $computer" -ForegroundColor Yellow
           "Working on machine $computer" >>C:\temp\ServicesRestart.log
        
 
 
           #STOPPING THE CCM SERVICE
           Write-Host  "-Stopping the CCMEXEC service on $computer" -ForegroundColor Green
           "-Stopping the CCMEXEC service on $computer">>C:\temp\ServicesRestart.log
           Get-Service -ComputerName $computer -Name CCMEXEC| Stop-Service -Force
    
 
 
          #STARTING THE SERVICE
           Write-Host  "-Starting the CCMEXEC service back on $computer" -ForegroundColor Green
           "-Starting the CCMEXEC service back on $computer">>C:\temp\ServicesRestart.log
           Get-Service -ComputerName $computer -Name CCMEXEC| Start-Service
 
           Write-Host  "-Operation completed on  $computer" -ForegroundColor Green
            "-Operation completed on  $computer">>C:\temp\ServicesRestart.log
       
 
        }
        catch
        {
            #Catch the exception here
 
            Write-host "-Exeception error on  $computer. Check logFile more details" -ForegroundColor Red
            "-Exeception error on  $computer. Check logFile more details">>C:\temp\ServicesRestart.log
 
            #Write the server name to c:\Temp\ExceptionError.log
 
            " $computer has thrown asn error $($_.exception)" >> C:\Temp\ExceptionError.log
        }
 
    }
    else
    {
        # offline machines
 
        "$Computer is offline" >> C:\Temp\ExceptionError.log
 
    }
 
    
}
 
Write-Host  "Completed the execution.. Thank You!" -ForegroundColor Yellow

"=============================Execution completed===============================" >> C:\temp\ServicesRestart.log
"=============================Execution completed===============================" >> C:\temp\ExceptionError.log




