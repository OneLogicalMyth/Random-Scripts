# Function taken with thanks from https://blogs.technet.microsoft.com/heyscriptingguy/2011/08/20/use-powershell-to-work-with-any-ini-file/
function Get-IniContent ($filePath)
{
    $ini = @{}
    switch -regex -file $FilePath
    {
        “^\[(.+)\]” # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        “^(;.*)$” # Comment
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = “Comment” + $CommentCount
            $ini[$section][$name] = $value
        } 
        “(.+?)\s*=(.*)” # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

# Function to create a new security object
Function New-SecObj {
Param($SettingType,$Name,$DisplayName,$RawValue,$Value)

    $Out = '' | Select-Object SettingType, Name, DisplayName, RawValue, Value
    $Out.SettingType = $SettingType
    $Out.Name = $Name
    $Out.DisplayName = $DisplayName
    $Out.RawValue = $RawValue
    $Out.Value = $Value
    $Out

}

# Export the security policy
$ExportedPolicy = (Join-Path $env:TEMP SecurityPolicyExport.inf)

# Run the export of the security policy
$null = Invoke-Expression "secedit /export /cfg $ExportedPolicy"

# Check if successful or not
if($LASTEXITCODE -eq 0){
    # Successful so grab info
    $global:SecPol = Get-IniContent $ExportedPolicy

    # Convert to security policy to objects as it makes life easier
    $SystemAccess = New-Object psobject -Property $SecPol.'System Access'
    $AuditPolicy = New-Object psobject -Property $SecPol.'Event Audit'

    # Create empty array to store objects
    $FinalOutput = @()

    # Password Policy
    $FinalOutput += New-SecObj -SettingType PasswordPolicy -Name EnforcePasswordHistory -RawValue ([int]($SystemAccess.PasswordHistorySize)) -Value ([int]($SystemAccess.PasswordHistorySize))
    $FinalOutput += New-SecObj -SettingType PasswordPolicy -Name MaximumPasswordAge -RawValue ([int]($SystemAccess.MaximumPasswordAge)) -Value ([int]($SystemAccess.MaximumPasswordAge))
    $FinalOutput += New-SecObj -SettingType PasswordPolicy -Name MinimumPasswordAge -RawValue ([int]($SystemAccess.MinimumPasswordAge)) -Value ([int]($SystemAccess.MinimumPasswordAge))
    $FinalOutput += New-SecObj -SettingType PasswordPolicy -Name MinimumPasswordLength -RawValue ([int]($SystemAccess.MinimumPasswordLength)) -Value ([int]($SystemAccess.MinimumPasswordLength))
    $FinalOutput += New-SecObj -SettingType PasswordPolicy -Name PasswordComplexity -RawValue ([int]($SystemAccess.PasswordComplexity)) -Value ([bool]([int]($SystemAccess.PasswordComplexity)))
    $FinalOutput += New-SecObj -SettingType PasswordPolicy -Name ReversibleEncryption -RawValue ([int]($SystemAccess.ClearTextPassword)) -Value ([bool]([int]($SystemAccess.ClearTextPassword)))
    
    # Lockout Policy
    $FinalOutput += New-SecObj -SettingType LockoutPolicy -Name LockoutDuration -RawValue ([int]($SystemAccess.LockoutDuration)) -Value ([int]($SystemAccess.LockoutDuration))
    $FinalOutput += New-SecObj -SettingType LockoutPolicy -Name LockoutThreshold -RawValue ([int]($SystemAccess.LockoutBadCount)) -Value ([int]($SystemAccess.LockoutBadCount))
    $FinalOutput += New-SecObj -SettingType LockoutPolicy -Name ResetLockoutCount -RawValue ([int]($SystemAccess.ResetLockoutCount)) -Value ([int]($SystemAccess.ResetLockoutCount))

    # Audit Policy (legacy)
    function AuditType {
    param($RawValue)
        switch($RawValue)
        { 
            0 {"No Auditing"} 
            1 {"Success"} 
            2 {"Failure"} 
            3 {"Success, Failure"}
        }
    }
    
    $FinalOutput += New-SecObj -SettingType AuditPolicy -Name AuditAccountLogon -RawValue ([int]($AuditPolicy.AuditAccountLogon)) -Value (AuditType ([int]($AuditPolicy.AuditAccountLogon)))
    $FinalOutput += New-SecObj -SettingType AuditPolicy -Name AuditAccountManage -RawValue ([int]($AuditPolicy.AuditAccountManage)) -Value (AuditType ([int]($AuditPolicy.AuditAccountManage)))
    $FinalOutput += New-SecObj -SettingType AuditPolicy -Name AuditDSAccess -RawValue ([int]($AuditPolicy.AuditDSAccess)) -Value (AuditType ([int]($AuditPolicy.AuditDSAccess)))
    $FinalOutput += New-SecObj -SettingType AuditPolicy -Name AuditLogonEvents -RawValue ([int]($AuditPolicy.AuditLogonEvents)) -Value (AuditType ([int]($AuditPolicy.AuditLogonEvents)))
    $FinalOutput += New-SecObj -SettingType AuditPolicy -Name AuditObjectAccess -RawValue ([int]($AuditPolicy.AuditObjectAccess)) -Value (AuditType ([int]($AuditPolicy.AuditObjectAccess)))
    $FinalOutput += New-SecObj -SettingType AuditPolicy -Name AuditPolicyChange -RawValue ([int]($AuditPolicy.AuditPolicyChange)) -Value (AuditType ([int]($AuditPolicy.AuditPolicyChange)))
    $FinalOutput += New-SecObj -SettingType AuditPolicy -Name AuditPrivilegeUse -RawValue ([int]($AuditPolicy.AuditPrivilegeUse)) -Value (AuditType ([int]($AuditPolicy.AuditPrivilegeUse)))
    $FinalOutput += New-SecObj -SettingType AuditPolicy -Name AuditProcessTracking -RawValue ([int]($AuditPolicy.AuditProcessTracking)) -Value (AuditType ([int]($AuditPolicy.AuditProcessTracking)))
    $FinalOutput += New-SecObj -SettingType AuditPolicy -Name AuditSystemEvents -RawValue ([int]($AuditPolicy.AuditSystemEvents)) -Value (AuditType ([int]($AuditPolicy.AuditSystemEvents)))

    # Security Options (work in progress)
    function EorD {
    param($RawValue)

        switch($RawValue)
        {
            0 {"Disabled"}
            1 {"Enabled"}
        }

    }

    # Process MS account block status
	if($SecPol.'Registry Values'.'MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\NoConnectedUser'){
		$BlockMSAccountsRaw = $SecPol.'Registry Values'.'MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\NoConnectedUser'.Split(',')[1]
		$BlockMSAccountsValue = switch($BlockMSAccountsRaw)
	    {
			0 {"This policy is disabled"}
			1 {"Users can't add Microsoft accounts"}
			3 {"Users can't add or log on with Microsoft accounts"}
		}
	}else{
		$BlockMSAccountsRaw = -1
		$BlockMSAccountsValue = "Not Defined"
	}
	
    # console password use
    $LimitBlankPasswordUse = $SecPol.'Registry Values'.'MACHINE\System\CurrentControlSet\Control\Lsa\LimitBlankPasswordUse'.Split(',')[1]
  

    $FinalOutput += New-SecObj -SettingType SecurityOptions:Accounts -Name AdminAccountStatus -DisplayName 'Administrator account status' -RawValue ([int]($SystemAccess.EnableAdminAccount)) -Value (EorD ([int]($SystemAccess.EnableAdminAccount)))
    $FinalOutput += New-SecObj -SettingType SecurityOptions:Accounts -Name BlockMSAccounts -DisplayName 'Block Microsoft accounts' -RawValue ([int]($BlockMSAccountsRaw)) -Value $BlockMSAccountsValue
    $FinalOutput += New-SecObj -SettingType SecurityOptions:Accounts -Name GuestAccountStatus -DisplayName 'Guest account status' -RawValue ([int]($SystemAccess.EnableGuestAccount)) -Value (EorD ([int]($SystemAccess.EnableGuestAccount)))
    $FinalOutput += New-SecObj -SettingType SecurityOptions:Accounts -Name LimitBlankPasswordUse -DisplayName 'Limit local account use of blank passwords to console logon only' -RawValue ([int]($LimitBlankPasswordUse)) -Value (EorD ([int]($LimitBlankPasswordUse)))
    $FinalOutput += New-SecObj -SettingType SecurityOptions:Accounts -Name RenameAdministrator -DisplayName 'Rename administrator account' -RawValue ([string]($SystemAccess.NewAdministratorName).Replace('"','').trim()) -Value ([string]($SystemAccess.NewAdministratorName).Replace('"','').trim())
    $FinalOutput += New-SecObj -SettingType SecurityOptions:Accounts -Name RenameGuest -DisplayName 'Rename guest account' -RawValue ([string]($SystemAccess.NewGuestName).Replace('"','').trim()) -Value ([string]($SystemAccess.NewGuestName).Replace('"','').trim())


    # Output cleaned password policy
    $FinalOutput

    # Clean up remove exported policy
    Remove-Item $ExportedPolicy
}else{

    # Handle secedit error
    Write-Error "secedit failed to run - $(([ComponentModel.Win32Exception]$LASTEXITCODE).Message)" -TargetObject secedit -ErrorId $LASTEXITCODE

}