###If you have a multi-domain forest, consider checking against all global catalogs for users###
################################################################################################

$Users = Import-CSV -Path "C:\Temp\Terminated_UserIDs.csv"
$ExportCSV = "C:\Temp\Terminated_UserIDs_Status.csv"

#Custom Object to handle exceptions for UserIDs not found in AD.
$myObject = [PSCustomObject]@{
    SamAccountName = ''
    Enabled = 'NotInAD'
    }

#NetworkID is the column header
ForEach($User in $Users){
    Try{
        Get-ADUser $User.NetworkID -Properties SamAccountName, Enabled -ErrorAction Continue | Select SamAccountName, Enabled | Export-CSV $ExportCSV -Append -NoTypeInformation
        Write-Host "Found:" $User.NetworkID
        }
        Catch{
            Write-Host "Not found:" $User.NetworkID
            $myObject.SamAccountName = $User.NetworkID
            $myObject | Export-CSV $ExportCSV -Append -NoTypeInformation
        } 
}