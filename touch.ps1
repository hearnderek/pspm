[CmdletBinding()]
param ( 
    [Parameter(Mandatory=$true)]
    [String] $FileName,

    [Parameter(Mandatory=$false)]
    [String] $Contents = "[CmdletBinding()]`nparam()`n`necho 'hello world'",

    [Parameter(Mandatory=$false)]
    [System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8
)


$root = [System.IO.Path]::GetPathRoot($FileName)

if([System.IO.Path]::IsPathRooted($FileName)){
    # No change
}else{
    # Update filename to current directory
    $FileName = [System.IO.Path]::Combine($PWD, $FileName)
}

$FileName
[System.IO.File]::WriteAllText($FileName, $Contents, $Encoding)