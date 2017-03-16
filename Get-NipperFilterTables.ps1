# Created by Liam Glanfield
# 16/03/2017
# dirty script to extract Nipper filter tables as PS object, so you can export to CSV or HTML etc.

Function Get-NipperFilterTables {
param($InputFolder,[switch]$RawOutput)

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
            Write-Error 'InputFolder not found.'
            return
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
        param($Tables)
        
            Foreach($Table IN $Tables)
            {
                $Headings = $Table.headings.heading
                Foreach($Row IN $Table.tablebody.tablerow)
                {
                    $Out = '' | Select-Object $Headings
                    0..(@($Headings).count - 1) | %{ $Out.$($Headings[$_]) = (Get-ItemData ($Row.tablecell[$_].item)) }
                    $Out | Select-Object @{n='Table';e={$Table.title}}, *
                }
                
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
                    # yes Nipper XML is horrible to work with, could of done this better maybe *shrugs*
                    Foreach($SectionDetailPart in $SectionDetail.section)
                    {
                        $SectionDetailPart.table | Where-Object { $FitlerTablesToExport -Contains $_.index }
                    }
                }            
            }   
        }

        if($RawOutput)
        {
            Build-NipperTable $Data
        }else{
            Foreach($Item in (Build-NipperTable $Data))
            {
                if($Item.Table -like 'Extended Access Control List*')
                {
                    $FilterComment  = $Item.Table.split(' ')[5..$(@($Item.Table.split(' ')).count -3)] -join ' '
                }
                elseif($Item.Table -like 'Extended ACL*')
                {
                    $FilterComment  = $Item.Table.split(' ')[3..$(@($Item.Table.split(' ')).count -3)] -join ' '
                }
                else
                {
                    # no idea, so just spit out the raw and forget cutting it up
                    $FilterComment = $Item.Table
                }
                $FilterHostname = $Item.Table.split(' ')[$(@($Item.Table.split(' ')).count -1)]
                $FilterACL      = $Item.Table.split(' ')[4]
                
                $Out = '' | Select-Object Host, ACL, Rule, Active, Action, Protocol, Source, 'Src Port', Destination, 'Dst Port', Service, Log, Comment
                $Out.Host         = $FilterHostname
                $Out.ACL          = $FilterACL
                $Out.Rule         = $Item.Rule
                $Out.Active       = $Item.Active
                $Out.Action       = $Item.Action
                $Out.Protocol     = $Item.Protocol
                $Out.Source       = $Item.Source
                $Out.'Src Port'   = $Item.'Src Port'
                $Out.Destination  = $Item.Destination
                $Out.'Dst Port'   = $Item.'Dst Port'
                $Out.Service      = $Item.Service
                $Out.Log          = $Item.Log
                $Out.Comment      = $FilterComment
                $Out

            }
        }
    }

}
