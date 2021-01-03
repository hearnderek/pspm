[CmdletBinding()]
param()

echo 'Stakeholder'

. .\funcs\Worker.ps1

class StakeHolder {

    [String] $Name
    [String] $Notes
    [String] $UpdateMethod
    [TimeSpan] $UpdateFrequency
    [Object] $Self
}