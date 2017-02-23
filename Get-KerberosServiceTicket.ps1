
Function Get-KerberosServiceTicket {
param($username)

if($username -notlike '*@*'){
    Write-Warning 'You must have username@domain.name'
    return
}

#region Start collecting data
$WindowsVista = [System.Version]'6.0'
$OS           = Get-WmiObject win32_operatingsystem
$OSVersion    = [Version]$OS.Version

# Collecting logons for anything older than Vista/2008 R1 is too slow
if ($OSVersion.CompareTo($WindowsVista) -ge 0)
{
	# Build filter to only output logon events in the last 24 hours
	$XMLFilter = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">
					*[System[(EventID=4769)]]
						and
					*[EventData[Data[@Name="TargetUserName"]='$username']]
			</Select>
  </Query>
</QueryList>
"@

	$Output = Get-WinEvent -FilterXml $XMLFilter | ForEach-Object {

		$Event = $_

		$EventDateTime  = $Event.TimeCreated
		$EventXML       = [XML]$Event.ToXML()
		$EventData      = $EventXML.Event.EventData.Data
						
		$Username       = $EventData[0].'#text'
		$IPAddress      = $EventData[6].'#text'
						
						
		$Result = New-Object PSObject
		$Result | Add-Member NoteProperty Username $Username
		$Result | Add-Member NoteProperty IPAddress $IPAddress
		$Result | Add-Member NoteProperty DateTime $EventDateTime
		$Result

	} | Select-Object -Unique

}# End if OS is Vista or greater

$Output


}
