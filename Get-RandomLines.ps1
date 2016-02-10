Function Get-RandomLines {
Param(
	# The filename can be relative or full path
	[Parameter(Mandatory = $true,
			   ValueFromPipelineByPropertyName = $true,
			   ValueFromPipeline = $true,
			   Position = 0)]
	[Alias('FullName','F')]
	[string]$FileName,
	# The value of the percentage
	[Parameter(Mandatory = $false,
			   Position = 1)]
	[Alias('P')]
	[int]$Percentage = 50)

    # Process file
    Process {
        
        # Check file exists
        if(-not (Test-Path $FileName)){
            Write-Error 'Unable to find file!' -TargetObject $FileName
            return
        }

        # Get unquie contents
        $Content = Get-Content $FileName | Select-Object -Unique

        # Calculate percentages and values
        $OnePercent   = 100 / $Content.Count
        $AmountNeeded = $OnePercent * $Percentage

        # Check percentage against line count
        if($AmountNeeded -gt $Content.Count){
            Write-Error 'This percentage requirement will send you into a deep black hole!' -TargetObject "$AmountNeeded%"
            return
        }




        # Random select X amount of lines
        [int[]]$SelectedLines = @()
        while($SelectedLines.Count -ne $AmountNeeded){

                # Get random number up to line count
                $Rand = Get-Random -Minimum 0 -Maximum ($Content.Count - 1)

                # Check if line has already been used if not add to array
                if($SelectedLines -notcontains $Rand){
                    $SelectedLines += $Rand
                }
        }

        # Output X amount of unquie lines based on percentage
        $Content[$SelectedLines]

    }


}