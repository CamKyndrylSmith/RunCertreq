# -------------------------------------------------------------------------------
#  This script runs on the server to generate a certificate request.
#
# https://www.sslplus.de/wiki-en/Generating_a_CSR_in_MS_Windows_(using_certreq)
# -------------------------------------------------------------------------------
param (
      #----- Define parameters -----#
      [String]$jumpBox = ''                                                     # Certiificate Authority server location  
)
    Write-host "Running Create"
    #Get the local values
    $fqdn = [System.Net.Dns]::GetHostByName($env:computerName).HostName
    $IPaddr = (Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.status -ne "Disconnected"}).IPv4Address.IPAddress
    
    $CSRFolder = "\\{0}\C$\Kyndryl\CSR" -f $jumpBox
    If (-not (Test-Path $CSRFolder)) {
        # Folder does not exist, create it
        Try{
            New-Item -Path $CSRFolder -ItemType Directory
            Write-host "Folder created"
        } Catch{
            Exit 2
        }
    }
    
    $INFFolder = "C:\Kyndryl"
    If (-not (Test-Path $INFFolder)) {
        # Folder does not exist, create it
        Try{
            New-Item -Path $INFFolder -ItemType Directory
            Write-host "Folder created on host "
        } Catch{
            Exit 2
        }    
    }

    $CSRPath = "{0}\{1}.csr" -f $CSRFolder,$fqdn 
    $INFPath = "{0}\{1}.inf" -f $INFFolder,$fqdn

    # Create the INF file for the certificate requests
    $INF =
@"
[NewRequest]
Subject = "CN=$fqdn"
KeyLength = 2048
HashAlgorithm = SHA384
RequestType = PKCS10
FriendlyName = "Kyndryl CACF"
[Extensions]
2.5.29.17 = "{text}"
_continue_ = "dns=$fqdn&"
_continue_ = "IPAddress=$IPaddr&"
"@
    #write-host $INF
    Try{
        $INF | out-file -filepath $INFPath -force
        Write-host "Inf file created: " $INFPath
    } Catch{
        Exit 3
    } 
    
    Try{
        certreq -new $INFPath $CSRPath
        Write-host "CRS file created: " $CSRPath
    } Catch{
        $Error[0].Exception.GetType().FullName | out-file -filepath $CSRPath -force
        Exit 4
    } 
          
    Remove-Item $INFPath
    exit 0
