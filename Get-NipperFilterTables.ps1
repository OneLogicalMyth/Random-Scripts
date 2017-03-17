# Created by Liam Glanfield
# 16/03/2017
# dirty script to extract Nipper filter tables as PS object, so you can export to CSV or HTML etc.
# update: now includes a function to generate the vulnerability table
# required input is a folder of Nipper XML files

Function Get-NipperVulnerabilityTable {
param($InputFolder)

    begin
    {
        # grab the new line obj
        $nl = [Environment]::NewLine
    
        try
        {
            $Files = Get-ChildItem -Path $InputFolder -Filter *.xml -Recurse
            # wrap in @() to support PowerShell v2
            $FileCount = @($Files).Count
            $i = 1
        }
        catch
        {
            throw 'InputFolder not found.'
        }
        
    
        Function Build-NipperTable {
        param($Tables)

            if(@($Tables).count -eq 0)
            {
                return
            }
            
            # Convert XML mess to PS object
            Foreach($Table IN $Tables)
            {
                $Headings = $Table.headings.heading
                Foreach($Row IN $Table.tablebody.tablerow)
                {
                    $Out = '' | Select-Object $Headings
                    0..(@($Headings).count - 1) | %{ $Out.$($Headings[$_]) = (Get-ItemData ($Row.tablecell[$_].item)) }
                    $Out
                }        
            }

        }    
    
    }
    
    
    process
    {
        Foreach($File in $Files)
        {
            $XML             = [xml](Get-Content $File.fullname)
            $VulnAudit       = $XML.document.report.part | ?{ $_.title -eq 'Vulnerability Audit' }
            $VulnConclusions = $VulnAudit.section | ?{ $_.title -eq 'Conclusions' }
            $VulnTable       = $VulnConclusions.table | ?{ $_.title -eq 'Vulnerability audit summary findings' }
            $VulnTable = Build-NipperTable -Tables $VulnTable

            Foreach($Row in $VulnTable)
            {
                $Out = '' | Select-Object 'Affected Devices', Vulnerability, 'CVSSv2 Score', Rating
                $Out.'Affected Devices' = $Row.'Affected Devices' -join $nl
                $Out.Vulnerability      = $Row.Vulnerability
                $Out.'CVSSv2 Score'     = $Row.'CVSSv2 Score'
                $Out.Rating             = $Row.Rating
                $Out
            }    
        }
    }
}


Function Get-NipperFilterTables {
param($InputFolder,$OutputFolder=$false)

    begin
    {
        try
        {
            $Files = Get-ChildItem -Path $InputFolder -Filter *.xml -Recurse
            # wrap in @() to support PowerShell v2
            $FileCount = @($Files).Count
            $i = 1
        }
        catch
        {
            throw 'InputFolder not found.'
        }
        
        if($OutputFolder)
        {
            if(-not (Test-Path $OutputFolder))
            {
                throw "$OutputFolder - path not found."
            }
        }
                
        Function Get-ItemData {
        param($node)
            if($node.'#text')
            {
                return $node.'#text'
            }else{
                return $node
            }
        }
    
        Function Build-NipperTable {
        param($Tables,$Title)
        
            if(@($Tables).count -eq 0)
            {
                return
            }
            
            # Convert XML mess to PS object
            $Results = Foreach($Table IN $Tables)
            {
                $Headings = $Table.headings.heading
                Foreach($Row IN $Table.tablebody.tablerow)
                {
                    $Out = '' | Select-Object $Headings
                    0..(@($Headings).count - 1) | %{ $Out.$($Headings[$_]) = (Get-ItemData ($Row.tablecell[$_].item)) }
                    $Out | Select-Object @{n='Table';e={$Table.title}},*
                }
                
            }
            
            # Clean up and return
            Foreach($Item in $Results)
            {
                if($Item.Table -like 'Extended Access Control List*')
                {
                    $FilterComment  = $Item.Table.split(' ')[5..$(@($Item.Table.split(' ')).count -3)] -join ' '
                    $FilterACL      = $Item.Table.split(' ')[4]
                }
                elseif($Item.Table -like 'Extended ACL*')
                {
                    $FilterComment  = $Item.Table.split(' ')[3..$(@($Item.Table.split(' ')).count -3)] -join ' '
                    $FilterACL      = $Item.Table.split(' ')[2]
                }
                else
                {
                    # no idea, so just spit out the raw and forget cutting it up
                    $FilterComment = $Item.Table
                }
                $FilterHostname = $Item.Table.split(' ')[$(@($Item.Table.split(' ')).count -1)]
                
                
                $Out = '' | Select-Object Host, ACL, Rule, Active, Action, Protocol, Source, 'Src Port', Destination, 'Dst Port', Service, Log, 'Issue Title', Comment
                $Out.Host          = $FilterHostname
                $Out.ACL           = $FilterACL
                $Out.Rule          = $Item.Rule
                $Out.Active        = $Item.Active
                $Out.Action        = $Item.Action
                $Out.Protocol      = $Item.Protocol
                $Out.Source        = $Item.Source
                $Out.'Src Port'    = $Item.'Src Port'
                $Out.Destination   = $Item.Destination
                $Out.'Dst Port'    = $Item.'Dst Port'
                $Out.Service       = $Item.Service
                $Out.Log           = $Item.Log
                $Out.'Issue Title' = $Title
                $Out.Comment       = $FilterComment
                $Out
            }
        
        }
        
        
        
    }
    
    process
    {
        $Data = Foreach($File in $Files)
        {
            # convert to XML object
            $XML = [xml]($File | Get-Content)
            
            # Grab a list of filter tables
            $FitlerTablesToExport = $XML.document.contents.tables.content | where-object { $_.ref -like 'FILTER*' } | Select-Object -ExpandProperty index
            
            # Process each table in the report
            Foreach($ReportSection in $XML.document.report.part)
            {
                Foreach($SectionDetail in $ReportSection.section)
                {
                    # grab the issue title
                    $SectionTitle = $SectionDetail.title
                    # yes Nipper XML is horrible to work with, could of done this better maybe *shrugs*
                    Foreach($SectionDetailPart in $SectionDetail.section)
                    {
                        $TablesFiltered = $SectionDetailPart.table | Where-Object { $FitlerTablesToExport -Contains $_.index }
                        if($TablesFiltered)
                        {
                            Build-NipperTable -Tables $TablesFiltered -Title $SectionTitle
                        }
                    }
                }            
            }   
        }
        
        if($OutputFolder)
        {
            # Save to CSV files based on issue type
            # first all filter rules
            $Data | Where-Object { $_.'Issue Title' -like 'Filter*Rule*' } | Export-Csv (Join-Path $OutputFolder 'FilterRules.csv') -NoTypeInformation
            # Now save the rest
            $Data | Where-Object { $_.'Issue Title' -notlike 'Filter*Rule*' } | Group-Object 'Issue Title' | Foreach {
                $Item = $_
                $_.group | Export-Csv (Join-Path $OutputFolder "$($Item.name.Replace(' ','')).csv") -NoTypeInformation
            }
            
        }else{
            $Data
        }
    }

}
