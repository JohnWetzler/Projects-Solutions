#Import CSV of term'd UserIDs
$TermUsers = Import-CSV -Path "$PSScriptRoot\Terminated_Users.csv"
$Date = Get-Date -Format MM-dd-yyyy -ErrorAction SilentlyContinue
$Comma = ","

#Get all existing user profiles paths that are not system/built-ins.
$Profiles = Get-CimInstance -Class Win32_UserProfile | Where-Object {($_.LocalPath -match 'Users') -and ($_.LocalPath -notmatch 'Administrator') -and ($_.LocalPath -notmatch 'AltAdmAcct')} #| Select LocalPath

#Output existing profiles to a txt file to use with CMPivot FileContent.
ForEach ($Profile in $Profiles){ 
    $env:COMPUTERNAME+$Comma+"Existing"+$Comma+$Profile.LocalPath+$Comma+$Date | Add-Content "C:\Temp\ProfileStatus.txt" -Force -ErrorAction SilentlyContinue
}

ForEach ($Profile in $Profiles){
   
    #Loop through each profile to get UserID from the end of the profile path. Could probably use directory.name instead.
    #Replace "C:\Users\" with nothing so only userid remains: ie. C:\Users\JohnDoe becomes JohnDoe
    $UserID = ($Profile.LocalPath).replace('C:\Users\','')   
    
    #Search CSV for UserID, if it exists select it
    #CSV contains 1 column header NetworkID and is the actual UserID of the confirmed terminated user.
    If($TermUsers | Where-Object {$_.NetworkID -eq $UserID} | Select-Object){
        
        #Output if UserID is found in term'd list.
        Write-Host "Found:" $UserID " | " $Profile.LocalPath

        #Pre-Removal: Get C:\ Size & Remaining Size
        $PreSize = Get-Volume C | Select Size, SizeRemaining -ErrorAction SilentlyContinue
        
        #Remove profile
        $Profile | Remove-CimInstance -Verbose -WhatIf

        #Post-Removal: Get C:\ Remaining Size
        $PostSize = Get-Volume C | Select SizeRemaining -ErrorAction SilentlyContinue

            #Check to see if the profile path was removed, if so, write to txt for use with CMPivot.
            If(!(Test-Path $Profile.LocalPath)){
                $env:COMPUTERNAME+$Comma+"Removed"+$Comma+$Profile.LocalPath+$Comma+$Date+$Comma+$PreSize.Size+$Comma+$PreSize.SizeRemaining+$Comma+$PostSize.SizeRemaining | Add-Content "C:\Temp\ProfileStatus.txt" -Force -ErrorAction SilentlyContinue
            }
    }    
}