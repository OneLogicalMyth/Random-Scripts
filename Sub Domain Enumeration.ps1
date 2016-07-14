$Domain = 'example.com'

if(-not (Test-Path .\subdomains.txt)){
    Write-Progress -Activity 'Enumerating Sub Domains' -CurrentOperation 'Downloading Sub Domain Wordlist'
    wget 'https://raw.githubusercontent.com/guelfoweb/knock/knock3/knockpy/wordlist/wordlist.txt' -OutFile subdomains.txt
}

$WordList = Get-Content .\subdomains.txt

$DomainPercentage = 100 / $WordList.Count
Write-Progress -Activity 'Enumerating Sub Domains' -Status 'Building Sub Domains' -Id 1 -PercentComplete 0
$i = 1
$Domains = $WordList | %{ Write-Progress -Id 1 -Activity 'Enumerating Sub Domains' -Status 'Building Sub Domains' -CurrentOperation "$($_).$($Domain)" -PercentComplete ($i * $DomainPercentage);$i++; "$($_).$($Domain)" }

$i = 1
$Results = $Domains | %{  $Name = $_; Write-Progress -Id 1 -Activity 'Enumerating Sub Domains' -Status 'Testing Sub Domains' -CurrentOperation "Resolving DNS for '$Name'" -PercentComplete ($i * $DomainPercentage);$i++; Resolve-DnsName $Name -ErrorAction SilentlyContinue | ?{ $_.Name -eq $Name } }

$Filtered = $Results | Where IP4Address -ne $Null | Select Name, IPAddress -Unique
$Filtered | Export-Csv "$Domain-SubDomains.csv" -NoTypeInformation

$Filtered