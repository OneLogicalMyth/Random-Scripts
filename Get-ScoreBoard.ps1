
Function Get-ScoreBoard {
param([string]$TeamName=[string]::Empty,[int]$SelectTop=0)

    begin {

        # Convert scoreboard table into native object for easy processing

        # Download webpage and extract all contents of tbody then build an XML object
        $Webpage = (Invoke-WebRequest https://ctf.internetwache.org/scoreboard).Content
        $Regex   = [regex]"<tbody>(.|\n)*?</tbody>"
        $Results = ([xml]($regex.Match($webpage).Value)).tbody.tr

        # Loop through the XML object and build a cleaned PS custom object
        # Sort by position and team to match website output
        $Results = $Results | Foreach {    
            $Out          = '' | Select-Object Position, Team, Score
            $Out.Position = [int]($_.td[0])
            $Out.Team     = [string]($_.td[1].Trim())
            $Out.Score    = [int]($_.td[2])
            $Out
        } | Sort-Object -Property Position, Team

    }

    process {

        # if team name given filter on team name
        # You could do team* to return all starting with team, * for wildcard
        if($TeamName -ne [string]::Empty){
            $Results = $Results | Where-Object { $_.Team -like $TeamName }
        }

        # if select top # is given return the top # of results
        if($SelectTop -gt 0){
            $Results = $Results | Select-Object -First $SelectTop
        }

    }

    end {

        # return results
        $Results

    }

}


Function Invoke-ScoreBoardSummary {
param(
        [string]$TeamName,
        [ValidateSet('html', 'text', IgnoreCase = $true)]
        [string]$Format='text',
        [int]$SelectTop=10
    )

    Begin {

        $Results      = Get-ScoreBoard -SelectTop 10
        $TeamResults  = Get-ScoreBoard -TeamName $TeamName
        $TeamPosition = $TeamResults[0].Position
        $TeamScore    = $TeamResults[0].Score

    }

    process {

    
        if($Format -eq 'text'){
            $Output = "Internetwache CTF 2016 - Score Board Update`r`n`r`n"
            $Output += "-- Top $SelectTop Teams --`r`n"
            $Output += "------------------"
            $Output += $Results | Format-Table -AutoSize | Out-String
            $Output += "-- $TeamName --`r`n"
            $Output += (1..($TeamName.Length + 6) | %{ '-' }) -join ''
            $Output += "`r`n"
            $Output += "Current Position: $TeamPosition`r`n"
            $Output += "Current Score:    $TeamScore"
        }
        if($Format -eq 'html'){
            $Output = "<strong>Internetwache CTF 2016 &#45; Score Board Update</strong><br><br>"
            $Output += "<strong><em>Top 10 Teams</em></strong><br>"
            $Output += $Results | ConvertTo-Html -Fragment | Out-String
            $Output += "<br>"
            $Output += "<strong><em>$TeamName</em></strong><br>"
            $Output += "Current Position:&nbsp;<strong>$TeamPosition</strong><br>"
            $Output += "Current Score:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>$TeamScore</strong>"
        }
         
    }

    end {

        $Output

    }

}