function Main{
    Write-Progress -Activity "Preparing Resources"
    $Process = get-ciminstance CIM_Process
    $service = get-ciminstance Cim_Service
    Write-Progress -Completed True
    $a = 1
    $b = $Process.Count
    foreach($x in $Process){
        $ProcName = $x.Name
        $ProcID = $x.ProcessID
        $percomp = ($a/$b) * 100
        Write-Progress -Activity "Writing Process Information" -Status "$ProcID - $ProcName    $a/$b" -PercentComplete $percomp
        ProcPrint $x
        try{
            if($service.ProcessID -eq $x.ProcessID){
                $_service = $service | ? ProcessID -eq $x.ProcessID
                Write-Host "`t<----- Services ----->"
                foreach($x in $_service){
                    ServicePrint $x
                }
            }
            }catch{
                $service = $null
            }
            try{
                if(get-nettcpconnection -OwningProcess $x.ProcessID){
                    $Conn = get-nettcpconnection -OwningProcess $x.ProcessID
                    write-host "`t<----- Connections ----->"
                    foreach($x in $conn){
                        ConnPrint $x
                    }
                }
            }catch{
                $Conn = $null
            }
        $a++
    }
    Write-Progress -Completed True
}

function ProcPrint($Process){
    $ParentPath = get-ciminstance CIM_Process | ? ProcessID -eq $Process.ParentProcessID
    write-host "<-----"$Process.Name"----->`n"
    write-host "`n`tProcess Name:"$Process.Name"`n`tProcess ID:"$Process.ProcessID"`n`tExecutable Path:"$Process.ExecutablePath
    write-host "`n`tPPID Name:"$ParentPath.Name"`n`tPPID:"$Process.ParentProcessID"`n`tPPID Path:"$ParentPath.ExecutablePath
    write-host
}

function ServicePrint($Service){
    write-Host "`t`tService Name:"$Service.Name"`n`t`tService State:"$Service.State
    write-host
}

function ConnPrint($Conn){
    write-host "`n`t`tLocal Address:"$Conn.LocalAddress":"$Conn.LocalPort
    write-host "`t`tRemote Address:"$Conn.RemoteAddress":"$Conn.RemotePort
    write-host

}
$global:ErrorActionPreference="SilentlyContinue"
Main