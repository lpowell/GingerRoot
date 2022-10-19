# Full enumeration script
# Analysis as well
<# 

Scans 
    Process executables, Services, jobs, scheduled tasks, temp folders, registry, Connections, Firewall

On Active Directory,
    Users, Computers, OUs, GPOs

Log & events
    Get server roles for log specifics [IIS etc]
    Examine events for specific IDs [eg admin logon]

Analysis
    Signature analysis on all executables and files [proc & serv]
    Resolve all connections
    Verify file paths for critical applications [sys64 stuff]

Reporting
    Generate an HTML and text report
    Headers for each segment

Output
    -verbose for full information
    default output warnings and criticals only

Options
    Kill 
        Automatically execute fixes for all issues

Code
    CIM Instances > wmi
    pass to OutHTML(), OutText(), or OutConsole() for output
#>

<# 

    Parameters
        Verbose
            Display all info, not just warnings
        Report 
            HTML/TXT
        Help
#>


# # Command tests

# Get-CimInstance CIM_proces
# Get-CimInstance CIM_Service
# Get-job
# get-ScheduledTask | select State, Description, URI
# # Get-ChildItem /temp loc
# # check app reg locs
# # connections do some filters for connections that are actually using data or connected to remote locations 
# # match them to processes as well
# get-netfirewallrule

# # if ad server role
# get-aduser -filter *
# get-adcomputer 
# get-adGroup
# get-adorganizationalunit
# get-GPO -all
# # organize these
# <#

# Domain
#     Computer
#         OU
#             Group
#                 User

# #>
# #  --> Get-ADGroup -Filter * | %{echo $_.Name; Get-ADGroupMember -Identity $_.Name | Select NAme, SID; Write-Host;}
# # Script it

# # Server Roles for logfiles 
# # Get-WinEvent Security logs 
# <# 

# Find all event logs with X IDs and then do something with them
# Timestamps? 

# IIS logs parse for shell
# #>

# Code Start

param($Verbose,$Report,[switch]$Help)

# https://bazaar.abuse.ch/export/txt/md5/full/
# unzip
# use


# DEFAULT SCANS
function Default(){
    $Process = Get-CimInstance CIM_Process
    $a = 0
    $b = $Process.Count
    $Send =@()
    foreach($x in $Process){
        $a++
        write-Progress -Activity "Analyzing Process Executables" -Status "$a/$b"
        if($x.ExecutablePath -notmatch "C\:\\Windows" <#-and $x.ExecutablePath -notmatch "C\:\\Program"#>){
            $Send+= $x
        }
    }
    Write-Progress -Completed True
    Report "Process" $Send
    $Send =@()
    $Service = Get-CimInstance CIM_Service
    $a = 0
    $b = $Service.Count
    foreach($x in $Service){
        $a++
        Write-Progress -Activity "Analyzing Service Executables" -Status "$a/$b"
        if($x.PathName -notmatch "C\:\\Windows" -and $x.Name -ne $null<#-and $x.ExecutablePath -notmatch "C\:\\Program"#>){
            $Send += $x
        }
    }
    Write-Progress -Completed True
    Report "Service" $send
}

function Report($Stage, $ReportObject){
    if($Stage -eq "Process"){
        Write-Host "Processes running from non-system locations`n"
        $out =@()
        $connout =@()
        foreach($x in $ReportObject){
            if($x.ExecutablePath -notin $out){
                write-Host "Name:" $x.Name"`nPath:" $x.ExecutablePath"`n"
                try{
                    if(Get-NetTCPConnection -OwningProcess $x.ProcessID){
                        Write-Host "`tConnections"
                        $Conn = Get-NetTCPConnection -OwningProcess $x.ProcessID
                        foreach($y in $Conn){
                            Write-Host "`n`t`tLocal Address:" $y.LocalAddress":"$y.LocalPort
                            Write-Host "`t`tRemote Addres:" $y.RemoteAddress":"$y.RemotePort
                        }
                        write-host
                    }
                }catch{

                }
            }elseif($x.ExecutablePath -in $out){
                try{
                    if(Get-NetTCPConnection -OwningProcess $x.ProcessID){
                        if($conn -notin $connout){
                            write-Host "Name:" $x.Name"`nPath:" $x.ExecutablePath"`n"
                            Write-Host "`tConnections"
                            $Conn = Get-NetTCPConnection -OwningProcess $x.ProcessID
                            foreach($y in $Conn){
                                Write-Host "`n`t`tLocal Address:" $y.LocalAddress":"$y.LocalPort
                                Write-Host "`t`tRemote Addres:" $y.RemoteAddress":"$y.RemotePort
                            }
                            write-host
                        }
                    }
                }catch{}
            }
            $out += $x.ExecutablePath
            $connout += $conn
        }
    }
    if($Stage -eq "Service"){
        Write-Host "Service Executables not in System Paths`n"
        $Out =@()
        foreach($x in $ReportObject){
            if($x.PathName -ne $out){
                Write-Host "Name:"$x.Name"`nPathName:"$x.PathName"`nState:"$x.State"`n"
                $Out += $x.PathName
            }
        }
    }
}
$global:ErrorActionPreference="SilentlyContinue"
Default