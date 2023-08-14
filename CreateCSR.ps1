# -------------------------------------------------------------------------------
#  This script runs on the server to generate a certificate request.
#
# https://www.sslplus.de/wiki-en/Generating_a_CSR_in_MS_Windows_(using_certreq)
# -------------------------------------------------------------------------------

    Write-host "Running Create"
    #Get the local values
    $fqdn = [System.Net.Dns]::GetHostByName($env:computerName).HostName
    $IPaddr = (Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.status -ne "Disconnected"}).IPv4Address.IPAddress
    $DisplayNow = Get-Date -format "yyyyMMdd_HHmmss"                                    # Date time format yyymmdd_HHmmss
    
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

    $CSRFolder = "C:\Kyndryl\CSR"  
    If (-not (Test-Path $CSRFolder)) {
        # Folder does not exist, create it
        Try{
            New-Item -Path $CSRFolder -ItemType Directory
            Write-host "Folder created"
        } Catch{
            Exit 1
        }
    }

    #Build Log file path
    $LogFile = "C:\Kyndryl\certreq_{2}.log" -f $DisplayNow  
    # Create the log file
    #   + Check if file exists
    if (Test-Path $LogFile) {
        Write-host "File '$LogFile' already exists!" -f Yellow
    }
    else {
        #Create a new file
        New-Item -Path $LogFile -ItemType "File"
        Write-host "New File '$LogFile' Created!" -f Green
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
    # Create the certificate request configuration file INF
    Try{
        $INF | out-file -filepath $INFPath -force
        Add-Content -Path $LogFile -Value "Inf file created: " $INFPath
    } Catch{
        Exit 1
    } 
    
    # Check if a certificate request file already exists
    if (Test-Path -Path $CSRPath){
        Remove-Item $CSRPath
        Add-Content -Path $LogFile -Value "$CSRPath removed successfully."
    }
    else{
        Add-Content -Path $LogFile -Value "$CSRPath not found."
    }

    # Run the CERTREQ command to generate a certificate request     
    Try{
        certreq -new $INFPath $CSRPath
        Add-Content -Path $LogFile -Value "CRS file created: " $CSRPath
    } Catch{
        $Error[0].Exception.GetType().FullName | out-file -filepath $LogFile -force
        Exit 1
    } 
    
    # Remove the INF file
    Remove-Item $INFPath
    exit 0
