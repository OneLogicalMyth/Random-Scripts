Function Set-ADPhoto {
param($Picture,$Username)

    $Pic = [byte[]](Get-Content $Picture -Encoding byte)
    $AD = [ADSI]$(([adsisearcher]"(samaccountname=$Username)").findone().getdirectoryentry().path)
    $AD.thumbnailPhoto.Add($Pic)
    $AD.SetInfo()

}
