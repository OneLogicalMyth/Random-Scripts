
Function ConvertFrom-MimiKatz {
param($MimiKatzOutput,[switch]$IncludeComputer)

    begin
    {
        Function Extract-Value {
        param($RawString,$Item)
        
            $ItemValue = $RawString -split "\*\s$($Item).*:\s(.*?)`n"
            if(@($ItemValue).count -gt 1)
            {
                $ItemValue[1].trim()
            }else{
                '(null)'
            }
        
        }
    }

    process
    {
        $Result = $MimiKatzOutput -split "\*\sUsername\s:\s(.*?)`n"
        $Total = @($Result).Count / 2
        $i = 1
        
        $Output = 1..$Total | Foreach{        
            $Out = '' | Select-Object Username, Domain, NTLM, SHA1, Password
            $Out.Username  = $Result[$i].trim()
            $Out.Domain    = (Extract-Value -RawString $Result[$i + 1] -Item Domain)
            $Out.NTLM      = (Extract-Value -RawString $Result[$i + 1] -Item NTLM)
            $Out.SHA1      = (Extract-Value -RawString $Result[$i + 1] -Item SHA1)
            $Out.Password  = (Extract-Value -RawString $Result[$i + 1] -Item Password)
            $Out
            
            $i = $i + 2
            
        } | Select-Object Username,Domain,NTLM,SHA1,Password -Unique
    }
    
    end
    {
        if(-not $IncludeComputer)
        {
            $Output = $Output | Where-Object { $_.Username -notlike '*$' }
        }
        
        $Output | Group-Object Username | Foreach {
            $Out = '' | Select-Object Username, Domain, NTLM, SHA1, Password
            $Out.Username  = $_.Name -replace '(,\(null\)|\(null\),|\(null\))'
            $Out.Domain    = (($_.Group | Select-Object -ExpandProperty Domain -Unique) -Join ',') -replace '(,\(null\)|\(null\),|\(null\))'
            $Out.NTLM      = (($_.Group | Select-Object -ExpandProperty NTLM -Unique) -Join ',') -replace '(,\(null\)|\(null\),|\(null\))'
            $Out.SHA1      = (($_.Group | Select-Object -ExpandProperty SHA1 -Unique) -Join ',') -replace '(,\(null\)|\(null\),|\(null\))'
            $Out.Password  = (($_.Group | Select-Object -ExpandProperty Password -Unique) -Join ',') -replace '(,\(null\)|\(null\),|\(null\))'
            $Out
        } | Where-Object { -not [string]::IsNullOrEmpty($_.Username) }
    }
    
}
