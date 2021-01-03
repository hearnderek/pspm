[CmdletBinding()]
param()

class Identified {
    [Int] $Id
    [String] $Name

    static [Hashtable] $Ids = @{}
    
    static [Int] NewId($className) {
        return ([Identified]::Ids[$className]++)
    }

    [Int] NewId() {
        
        $className = $this.GetType().Name
        
        return [Identified]::NewId($className)
    }

    Identified() {
        $this.Id = $this.NewId()
    }
}

# All Tasks are projects
class Project : Identified {
    [String] $Goal
    [String] $Constraints
    [String] $Status
    [DateTime] $StartDate
    [DateTime] $DueDate
    [Project[]] $ParentProjects
    [Project[]] $Milestones
    [StakeHolder[]] $Stakeholders
    [Worker] $ProjectManager
    [Worker[]] $ProjectMembers
    [Int] $EstimatedWorkHours
    [TimeEntry[]] $TimeEntries
    [Project[]] $DependentOn
}


class TimeEntry : Identified {
    [DateTime] $StartDate
    [DateTime] $EndDate
}

class Worker : Identified {
    [String] $Title
    [Int] $HoursPerWeek
}

class StakeHolder : Identified {
    [String] $Notes
    [String] $UpdateMethod
    [TimeSpan] $UpdateFrequency
    [Worker] $Self
}

class AssignedProject {
    [Project] $project
    [Worker] $worker
    [Int] $ExpectedHours
}

# ------------ Test values

[Project] $proj = New-Object -TypeName Project
$proj.Id = 1
$proj.Name = "Powershell based project management tool"
$milestone1 = New-Object -TypeName Project
$milestone1.Name = 'Objects'
$milestone2 = New-Object -TypeName Project
$milestone2.Name = 'Saving Mechanism'
$milestone3 = New-Object -TypeName Project
$milestone3.Name = 'CLI'
$milestone3.DependentOn = @( $milestone1, $milestone2 )

$proj.Milestones = @( $milestone1, $milestone2, $milestone3 )

# ------------ 


[System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8


Function Get-ProjectObjectSaveLine ($obj){
    
    $members = @($obj | Get-Member |? {$_.MemberType -eq 'Property'})
    [String]::Join("`t", ($members |% {
        
        if($obj.($_.Name) -is [System.Array]) {
        
            [String]::Join(',', ($obj.($_.Name) |% {$_.Id} ))
        
        } elseif([String]::IsNullOrEmpty($obj.($_.Name).Id)) {
            # Standard values
        
            if($obj.($_.Name) -eq $null) {
                ''
            }else{
                $obj.($_.Name).ToString() 
            }
        } else {
            $obj.($_.Name).Id
        }
    }))
}

class SaveFile {
    [String] $FileName
    [String] $Contents
} 

Function Get-ProjectObjectHeader ($obj){
    
    $members = @($obj | Get-Member |? {$_.MemberType -eq 'Property'})
    [String]::Join("`t", ($members |% { $_.Name }))
}

Function Get-ProjectObjectsSaveFile ([Object[]] $objs){
    
    $ObjectName = ($objs | select -First 1).GetType().Name
    $FileName = $ObjectName + '.dat'
    $Header = Get-ProjectObjectHeader ($objs | select -First 1)
    $Contents = $objs |% {
        Get-ProjectObjectSaveLine $_
    }

    $file = New-Object -TypeName SaveFile
    $file.FileName = $FileName
    $file.Contents = $Header + "`n" + [String]::Join("`n", $Contents)

    $file
}

Function Read-ProjectObjectFile ([String] $FileName) {
    #TODO turn save file into objects
    $objectName = [System.IO.Path]::GetFileName($FileName) -replace '.dat', ''
    $lines = [System.IO.File]::ReadAllLines($FileName, $Encoding)

    $header = ($lines | select -First 1) -split "`t"

    $obj = New-Object -TypeName $objectName
    # parallel with Header
    $members = @($obj | Get-Member |? {$_.MemberType -eq 'Property'})
    # parallel with members
    $types = $members |% { 
        $_.Definition -replace '^(\S+).+', '$1'
    }

    $lines | select -Skip 1 |% {
    
        $line = $_
        $obj = New-Object -TypeName $objectName

        $i = 0
        $line -split "`t" |% {
            
            if($types[$i] -eq 'datetime'){
                $obj.($header[$i]) = $_
            } elseif($types[$i] -eq 'string') {
                $obj.($header[$i]) = $_
            } elseif($types[$i] -eq 'int') {
                $obj.($header[$i]) = $_
            } elseif($types[$i][-1] -eq ']') {
                
                # handle multiples of IDs
                $_ | write-warning
                $l = $_ -split ',' |% {
                   $o = New-Object -TypeName ($types[$i] -replace '\[\]', '')
                   $o.id = $_
                   $o
                }
                
                $obj.($header[$i]) = $l
            } else {
                

                Write-Warning ($types[$i] + " is not supported yet")
            }
            
            $i = $i + 1
        }


        $obj    
    }
    # TODO: build objects from IDs
}

Get-ProjectObjectSaveLine $proj
"-----"
[SaveFile] $file = Get-ProjectObjectsSaveFile $proj, $milestone1, $milestone2, $milestone3
$file.Contents | Out-File ('.\save\'+$file.FileName) -Encoding utf8 -Verbose
"-----"
$proj

$rProj = Read-ProjectObjectFile ('.\save\'+$file.FileName)
$rProj

[SaveFile] $file2 = Get-ProjectObjectsSaveFile $rProj
$file2.Contents

$file.Contents | Out-File ('.\save\'+$file.FileName) -Encoding utf8 -Verbose




# ------------ Test values
[Project[]] $projs = @()

$id = 1
[Project] $top = New-Object -TypeName Project
$top.Name = "Powershell based project management tool"
$projs += $top


[Project] $defineObjects = New-Object -TypeName Project
$defineObjects.Name = 'Define Objects'
$projs += $defineObjects
$top.Milestones += $defineObjects

[Project] $statusEnum = New-Object -TypeName Project
$statusEnum.Name = 'Define Status enum'
$projs += $statusEnum
$defineObjects.Milestones += $statusEnum

[Project] $priority = New-Object -TypeName Project
$priority.Name = 'Define priority system'
$projs += $priority
$defineObjects.Milestones += $priority


[Project] $savingMech = New-Object -TypeName Project
$savingMech.Name = 'Saving Mechanism'
$projs += $savingMech
$top.Milestones += $savingMech

[Project] $savingRef= New-Object -TypeName Project
$savingRef.Name = 'Object References Saving'
$projs += $savingRef
$savingMech.Milestones += $savingRef

[Project] $loadingRef = New-Object -TypeName Project
$loadingRef.Name = 'Object References Loading'
$projs += $loadingRef
$savingMech.Milestones += $loadingRef


[Project] $dogfood = New-Object -TypeName Project
$dogfood.Name = 'Write tasks as projects'
$projs += $dogfood
$top.Milestones += $dogfood

[Project] $features = New-Object -TypeName Project
$features.Name = 'define features'
$projs += $features
$top.Milestones += $features

[Project] $cli = New-Object -TypeName Project
$cli.Name = 'create user interface'
$projs += $cli
$top.Milestones += $cli

[Project] $cliProto = New-Object -TypeName Project
$cliProto.Name = 'draft up prototypes'
$projs += $cliProto
$cli.Milestones += $cliProto

[Project] $cliProto2 = New-Object -TypeName Project
$cliProto2.Name = 'decide on favorite prototype'
$projs += $cliProto2
$cli.Milestones += $cliProto2
$cliProto2.DependentOn += $cliProto

[SaveFile] $file3 = Get-ProjectObjectsSaveFile $projs
$file3.Contents | Out-File ('.\save\'+$file3.FileName) -Encoding utf8 -Verbose

# ------------ 


"All.ps1"