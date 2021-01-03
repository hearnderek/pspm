[CmdletBinding()]
param()

echo 'Project'

. .\funcs\Stakeholder.ps1

class Proj {

    [String] $Name
    [String] $Goal
    [DateTime] $StartDate
    [DateTime] $DueDate
}

$proj = New-Object -TypeName Proj
$proj.Name = 'My Project'