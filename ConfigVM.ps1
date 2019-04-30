#################################################################################################################################
#  Name        : Configure-WinRM.ps1                                                                                            #
#                                                                                                                               #
#  Description : Configures the WinRM on a local machine                                                                        #
#                                                                                                                               #
#  Arguments   : HostName, specifies the ipaddress or FQDN of machine                                                           #
#################################################################################################################################

param
(
    [string] $hostname,
    [string] $protocol
)

#################################################################################################################################
#                                             Helper Functions                                                                  #
#################################################################################################################################

$ErrorActionPreference="Stop"
$winrmHttpPort=5985
$winrmHttpsPort=5986

$helpMsg = "Usage:
            To configure WinRM over Https:
                ./ConfigureWinRM.ps1 <fqdn\ipaddress> https

            To configure WinRM over Http:
                ./ConfigureWinRM.ps1 <fqdn\ipaddress> http"


function Is-InputValid
{  
    $isInputValid = $true

    if(-not $hostname -or ($protocol -ne "http" -and $protocol -ne "https"))
    {
        $isInputValid = $false
    }

    return $isInputValid
}

function Delete-WinRMListener
{
    $config = winrm enumerate winrm/config/listener
    foreach($conf in $config)
    {
        if($conf.Contains("HTTPS"))
        {
            Write-Verbose -Verbose "HTTPS is already configured. Deleting the exisiting configuration."

            winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
            break
        }
    }
}

function Configure-WinRMListener
{
    Write-Verbose -Verbose "Configuring the WinRM listener for $hostname over $protocol protocol. This operation takes little longer time, please wait..."

    if($protocol -ne "http")
    {
            Configure-WinRMHttpsListener -hostname $hostname -port $winrmHttpsPort
    }
    else
    {
            Configure-WinRMHttpListener
    }
    
    Write-Verbose -Verbose "Successfully Configured the WinRM listener for $hostname over $protocol protocol" 
}

function Configure-WinRMHttpListener
{
    winrm delete winrm/config/Listener?Address=*+Transport=HTTP
    winrm create winrm/config/Listener?Address=*+Transport=HTTP
}

function Configure-WinRMHttpsListener
{
    # Delete the WinRM Https listener if it is already configured
    Delete-WinRMListener

    # Create a test certificate
    $thumbprint = (New-SelfSignedCertificate -DnsName $hostname -CertStoreLocation "cert:\LocalMachine\My").Thumbprint
    if(-not $thumbprint)
    {
        throw "Failed to create the test certificate."
    }

    # Configure WinRM
    $WinrmCreate= "winrm create --% winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=`"$hostName`";CertificateThumbprint=`"$thumbPrint`"}"
    invoke-expression $WinrmCreate
    winrm set winrm/config/service/auth '@{Basic="true"}'
}

function Add-FirewallException
{
    if( $protocol -ne "http")
    {
        $port = $winrmHttpsPort
    }
    else
    {
        $port = $winrmHttpPort
    }

    # Delete an exisitng rule
    Write-Verbose -Verbose "Deleting the existing firewall exception for port $port"
    netsh advfirewall firewall delete rule name="Windows Remote Management (HTTPS-In)" dir=in protocol=TCP localport=$port | Out-Null

    # Add a new firewall rule
    Write-Verbose -Verbose "Adding the firewall exception for port $port"
    netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=$port | Out-Null
}

function Set-NetworkProfile
{
  Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
  Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.0.*" -Force
}

#################################################################################################################################
#                                              Configure WinRM                                                                  #
#################################################################################################################################

# Validate script arguments
if(-not (Is-InputValid))
{
    $hostname = (Test-Connection $env:COMPUTERNAME -Count 1).IPV4Address.IPAddressToString
	$protocol = "https"
   
}

function ConfigWINRM {
    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
    winrm quickconfig
    
    # The default MaxEnvelopeSizekb on Windows Server is 500 Kb which is very less. It needs to be at 8192 Kb. The small envelop size if not changed
    # results in WS-Management service responding with error that the request size exceeded the configured MaxEnvelopeSize quota.
    winrm set winrm/config '@{MaxEnvelopeSizekb = "8192"}'
    
    
    # Configure WinRM listener
    Configure-WinRMListener
    
    # Add firewall exception
    Add-FirewallException
    
    # List the listeners
    Write-Verbose -Verbose "Listing the WinRM listeners:"
    
    Write-Verbose -Verbose "Querying WinRM listeners by running command: winrm enumerate winrm/config/listener"
    winrm enumerate winrm/config/listener
    
    Set-NetworkProfile
}

<#
.SYNOPSIS
#

.DESCRIPTION
Install Chocolatey and required iis deploy tools

.EXAMPLE
An example

.NOTES
General notes
#>

function installChocolatey {
    # Set-ExecutionPolicy Bypass -Scope Process -Force; 
    # Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
function installTools {
    choco install webdeploy
}

function InstallTools {
    installChocolatey
    installTools
}

function main {
    ConfigWINRM
    InstallTools
}
Write-Verbose "###########Begining of config VM ###########"
main
Write-Verbose "###########End of config VM ###########"




#################################################################################################################################
#################################################################################################################################
