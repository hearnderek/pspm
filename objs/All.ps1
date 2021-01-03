[CmdletBinding()]
param()

$Encoding = [System.Text.Encoding]::UTF8

# Used as a return structure within [Id]
class SaveFile {
    [String] $FileName
    [String] $Contents
}

# Everything should have a name
# Everything gets an ID
# Everything with an ID can be stored in a TSV file
class Id {
    
    # --- Member Variables (Serialized)

    [Int] $Id
    [String] $Name
    


    # --- Static Variables (Not Serialized)

    # Stores the next id for every class
    static [Hashtable] $Ids = @{}

    # Stores every created class
    # This could be a nested hash instead of an array
    static [Hashtable] $CreatedObjects = @{}
    
    
    
    # --- Constructor

    Id() {
        $this.Id = $this.NewId()

        $this.AddThis()
    }


    # --- Members

    # Use class name of Child Class $this to build ID
    [Int] NewId() {
        
        $className = $this.GetType().Name
        
        return [Id]::NewId($className)
    }

    AddThis() {
        $className = $this.GetType().Name

        if(![Id]::CreatedObjects[$className]){
            [Id]::CreatedObjects[$className] = @()
        }
        [Id]::CreatedObjects[$className] += @($this)
        
    }



    # --- Static Functions

    # If this object is reused between runs, previous objects will persist.
    # Run this if you do not want that default functionality 
    static Reset() {
        [Id]::Ids = @{}
        [Id]::CreatedObjects = @{}
    }

    # A short method of giving each class their own seperate IDs using static variables
    static [Int] NewId($className) {
        return ([Id]::Ids[$className]++)
    }

    # Prepare save file for all of the registered $className
    static [SaveFile] ProjectObjectsSaveFile ($className){
        
        "ProjectObjectsSaveFile" | Write-Warning
        $objs = [Id]::CreatedObjects[$className]
        $FileName = $className + '.dat'
        $Header = [Id]::ProjectObjectHeader( ($objs | select -First 1) )
        $Contents = $objs |% {
            [Id]::ProjectObjectSaveLine($_)
        }

        [SaveFile] $file = New-Object SaveFile
        $file.FileName = $FileName
        $file.Contents = $Header + "`n" + [String]::Join("`n", $Contents)

        return $file
    }

    # Prepare TSV header for save file of generic object
    static [String] ProjectObjectHeader ($obj){
        $obj | Write-Warning
        $members = @($obj | Get-Member |? {$_.MemberType -eq 'Property'})
        return [String]::Join("`t", ($members |% { $_.Name }))
    }

    # Prepare TSV for save file of generic object
    # In the case of an array, save only the IDs in a CSV style string.
    static [String] ProjectObjectSaveLine ($obj){
    
        $members = @($obj | Get-Member |? {$_.MemberType -eq 'Property'})
        return [String]::Join("`t", ($members |% {
        
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

    # Prepare save file contents for every registered class
    static [SaveFile[]] ProjectSaveFiles() {
        return [Id]::CreatedObjects.Keys | %{
            [Id]::ProjectObjectsSaveFile($_)
        }
    }
}

enum Status {
    NotStarted = 0
    Reqs = 1
    Design = 2
    Spec = 3
    Proto = 4
    InProgress = 5
    Block = 6
    Complete = 7
    Cancelled = 8
    Backburner = 9
}

[Enum]::num

# All Tasks are projects
class Project : Id {
    [String] $Goal
    [String] $Constraints
    
    # When milestones are present, this is largely automatic.
    [Status] $Status
    [DateTime] $StartDate
    [DateTime] $DueDate
    [Project[]] $ParentProjects
    [Project[]] $Milestones
    [StakeHolder[]] $Stakeholders
    [Worker] $ProjectManager
    [Worker[]] $ProjectMembers
    [Int] $EstimatedWorkHours
    [TimeEntry[]] $TimeEntries

    # Useful for showing what should be focused on
    [Project[]] $DependentOn

    [boolean] IsComplete() {
        if($this.Milestones.length -gt 0) {
            $this.Milestones |% {$ret = $ret -and $_.IsComplete()}
        } else {
            return [boolean]($_.status -eq [Status]::Complete)
        }
        return $false
    }

    [int] CompletedMilestoneCount() {
        if($this.Milestones) {
            return ($this.Milestones |? { $_.IsComplete() }).Length 
        } else {
            return 0
        }

    }

    [string[]] Tree() {
        $spacer = ' |'
        $box = "<>  "
        $box = $box.Insert(1, $this.Status)
        [String]$completedCount = $this.CompletedMilestoneCount()
        $innerCount = "  [$completedCount/$($this.Milestones.Length)]"
        $blocked = ""
        if($this.DependentOn.Length) {
            "$($this.name) blocked"
            $notCompleteBlockers = $this.DependentOn |? {! $_.IsComplete()} 
            if($notCompleteBlockers.Length -gt 0){
                $blocked = " !! Blocked by [$($notCompleteBlockers[0].Name)]"
            }
        }
        
        # TODO: Get Blocked
        
        if($this.Milestones.length -gt 0) {
            $self = "- " + $this.Name + $innerCount
        } else {
            $self = "- " + $box + $this.Name + $blocked
        }
        [string[]]$ret = @( $self )
        if(! ($this.Milestones -eq $null )) {
            $this.Milestones |% {
                $_.Tree() |% {
                    $ret += ( $spacer + $_ )
                }
            }
        }

        return [string[]] $ret
    }

    [Project] GetFromTree([int] $index) {
        if($index -eq 0){
            return $this
        } else {
            return $this.TreeAsList()[$index]
        }
    }

    [Project[]] TreeAsList() {
        if(! ($this.Milestones -eq $null)) {
            return @($this) + [Project[]]($this.Milestones |% {
                $_.TreeAsList() 
            })
        }
        return @($this)
    }
}


class TimeEntry : Id {
    [DateTime] $StartDate
    [DateTime] $EndDate
}

class Worker : Id {
    [String] $Title
    [Int] $HoursPerWeek
}

class StakeHolder : Id {
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


Function Read-ProjectObjectFile ([String] $FileName) {
    # need to reset everything to allow ids to get set properly
    [Id]::Reset()

    #TODO turn save file into objects
    $objectName = [System.IO.Path]::GetFileName($FileName) -replace '.dat', ''
    $fileName | Write-Warning
    $lines = [System.IO.File]::ReadAllLines($FileName, $Encoding)

    $header = ($lines | select -First 1) -split "`t"

    $obj = New-Object $objectName
    # parallel with Header
    $members = @($obj | Get-Member |? {$_.MemberType -eq 'Property'})
    # parallel with members
    $types = $members |% {
        # take first word from definition
        $_.Definition -replace '^(\S+).+', '$1'
    }

    $lines | select -Skip 1 |% {
    
        $line = $_
        $obj = New-Object $objectName

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
                    $o = New-Object ($types[$i] -replace '\[\]', '')
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

# --- General Functions

## Design
## .. parent item
##  1 item 1
## 99 item 99

### Controls
### prompt asking for number
function Select-FromList ([string[]] $xs, [switch] $ReturnNumber) {
    
    # number of characters
    [int] $pad = $xs.Length.ToString().Length
    for($Local:i = 0; $Local:i -lt $xs.Length; $Local:i++) {
        #todo: add left pad to numbers 
        [string] $local:s = $Local:i
        [int] $toPad = $pad - $local:s.Length
        " " * $toPad + $Local:s + '  ' + $xs[$Local:i] | Write-Host
    }
    
    [string] $userInput = Read-Host -Prompt "Selection"
    [int] $selected = $userInput
    if($userInput -and $selected -ge 0 -and $selected -lt $xs.Length) {
        if($ReturnNumber){
            return $selected
        }else {
            return $xs[$selected]
        }
    } else {
        "Invalid Selection" | Write-Warning
        return Select-FromList $xs -ReturnNumber:$ReturnNumber
    }
}

# Interactive New Project

## Design 1
## [S]kip [B]ack [C]ancel [D]one, or enter value
## :

## Design Proto Simple
## Prompt name only

function New-ProjectInteractive ([Project] $Parent) {
    # using proto simple design
    $name = Read-Host -Prompt "Name"
    [Project] $Local:newProject = @{
        Name = $name
    }

    if($Parent){
        $Parent.Milestones += $Local:newProject    
    }

    return $Local:newProject
}

function Update-ProjectStatusInteractive([Project] $project) {
    $selection = Select-FromList ([Enum]::GetNames([Status]))
    $project.Status = $selection
    return $project
}




# ------------ Test values
[Id]::Reset()

[Project] $top = @{
    Name = "Powershell based project management tool"
}

[Project] $defineObjects = @{
    Name = 'Define Objects'
}
$top.Milestones += $defineObjects


[Project] $dom1 = @{
    name='First attempt'
    status='Complete'
}
$defineObjects.Milestones += $dom1

[Project] $dom2 = @{
    name='with inheritance'
    status='Complete'
}
$defineObjects.Milestones += $dom2

[Project] $statusEnum = @{
    Name = 'Define Status enum'
    Status = 'Complete'
}
$defineObjects.Milestones += $statusEnum

[Project] $priority = @{
    Name = 'Define priority system'
}
$defineObjects.Milestones += $priority


[Project] $savingMech = @{
    Name = 'Saving Mechanism'
}
$top.Milestones += $savingMech

[Project] $savingRef= @{
    Name = 'Object References Saving'
    Status = 'Complete'
}
$savingMech.Milestones += $savingRef

[Project] $loadingRef = @{
    Name = 'Object References Loading'
    Status = 'InProgress'
}
$savingMech.Milestones += $loadingRef

[Project] $loadingRefIndentified = @{
    Name = 'Load through Id method'
}
$loadingRef.Milestones += $loadingRefIndentified


[Project] $dogfood = @{
    Name = 'Write tasks as projects'
    Status = 'InProgress'
}
$top.Milestones += $dogfood

[Project] $features = @{
    Name = 'define features'
}
$top.Milestones += $features

[Project] $cli = @{
    Name = 'create user interface'
}
$top.Milestones += $cli

[Project] $cliProto = @{
    Name = 'draft up prototypes'
}
$cli.Milestones += $cliProto

[Project] $cliProto2 = @{
    Name = 'decide on favorite prototype'
    DependentOn = @($cliProto)
}
$cli.Milestones += $cliProto2

[Project] $cliProtoTree = @{
    Name = 'decide on how to display the basic tree'
    Status = 'Complete'
}
$cli.Milestones += $cliProtoTree

[Project] $cliProtoBlocked = @{
    Name = 'decide on how to display blocked items'
    Status = 'Complete'
}
$cli.Milestones += $cliProtoBlocked



[SaveFile] $file3 = [Id]::ProjectObjectsSaveFile("Project")
$file3.Contents | Out-File ('.\save\'+$file3.FileName) -Encoding utf8 -Verbose
$file3.Contents


# ------------ 


"All.ps1"

$top.Tree()

Read-ProjectObjectFile ([System.IO.Path]::Combine($PWD, ('.\save\'+$file3.FileName)))
[Id]::CreatedObjects['Project']



# $tree = $top.Tree()
# $r = Select-FromList $tree -ReturnNumber
# $p = $top.GetFromTree($r)

# $p.Tree()
# New-ProjectInteractive $p

# $p.Tree()
# $tree = $p.Tree()
# $r = Select-FromList $tree -ReturnNumber
# Update-ProjectStatusInteractive $top.GetFromTree($r)
