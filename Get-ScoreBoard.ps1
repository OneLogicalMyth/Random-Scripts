
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