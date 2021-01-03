[CmdletBinding()]
param()

echo 'Worker'

. .\funcs\Project.ps1

class Worker {

    [String] $Name
    [String] $Title
    [Int] $HoursPerWeek
}