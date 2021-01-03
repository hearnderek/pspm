[CmdletBinding()]
param()

# --- How veriables work between scopes

($x++)
($Local:j++)
($Script:k++)

function Invoke-This () {
    "$(($Global:i++)), $(($Script:k++)), $(($Local:j++)), $(($x++))"
}

Invoke-This
Invoke-This
Invoke-This

"${Global:i}, ${Script:k}, ${Local:j}, $x"


# --- Powershell Inheratiance

class MyClass {
    [int] $p
    [int] $id
    static [int] $staticId = 1

    [int] inner() {
        $this.p = 10
        return $this.p
    }

    MyClass(){
        
        $this.p = 5;
        $this.id = [MyClass]::newId()
    }

    static [int] newId(){
        return ([MyClass]::staticId++)
    }

}

class Other {

    static [int] Get(){
        return 5
    }

}

class A : MyClass {
}


[MyClass]::new().inner()

[MyClass]::new()

[A]::new()


# --- making classes

class Anything {
    [int] $id
    [string] $name
}


[Anything] $x = @{
    id=5
    name='Hello world'
}
'$x'
$x.id
$x.name
return

# --- pspm with inheritance


# Used as a return structure within [Identified]
class SaveFile {
    [String] $FileName
    [String] $Contents
}

# Everything should have a name
# Everything gets an ID
# Everything with an ID can be stored in a TSV file
class Identified {
    
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
    Identified() {
        $this.Id = $this.NewId()

        $this.AddThis()
    }


    # --- Members

    # Use class name of Child Class $this to build ID
    [Int] NewId() {
        
        $className = $this.GetType().Name
        
        return [Identified]::NewId($className)
    }

    AddThis() {
        $className = $this.GetType().Name

        if(![Identified]::CreatedObjects[$className]){
            [Identified]::CreatedObjects[$className] = @()
        }
        [Identified]::CreatedObjects[$className] += $this
    }



    # --- Static Functions

    # If this object is reused between runs, previous objects will persist.
    # Run this if you do not want that default functionality 
    static Reset() {
        [Identified]::Ids = @{}
        [Identified]::CreatedObjects = @{}
    }

    # A short method of giving each class their own seperate IDs using static variables
    static [Int] NewId($className) {
        return ([Identified]::Ids[$className]++)
    }

    # Prepare save file for all of the registered $className
    static [SaveFile] ProjectObjectsSaveFile ($className){
    
        $objs = [Identified]::CreatedObjects[$className]
        $FileName = $className + '.dat'
        $Header = [Identified]::ProjectObjectHeader( ($objs | select -First 1) )
        $Contents = $objs |% {
            [Identified]::ProjectObjectSaveLine($_)
        }

        [SaveFile] $file = New-Object SaveFile
        $file.FileName = $FileName
        $file.Contents = $Header + "`n" + [String]::Join("`n", $Contents)

        return $file
    }

    # Prepare TSV header for save file of generic object
    static [String] ProjectObjectHeader ($obj){
    
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
        return [Identified]::CreatedObjects.Keys | %{
            [Identified]::ProjectObjectsSaveFile($_)
        }
    }
}

class Employee : Identified {
}

class Boss : Employee{
}

[Employee] $e = [Employee]::new()
$e
[Employee] $e = [Employee]::new()
$e

[Boss] $b = [Boss]::new()
$b

"hello"

[Identified]::CreatedObjects.Keys | %{
    $_
    [Identified]::CreatedObjects[$_]
}

"file"
$f = [Identified]::ProjectObjectsSaveFile("Employee")

$f.Contents

"Files"
[SaveFile[]] $fs = [Identified]::ProjectSaveFiles()

$fs |% {
    ""
    $_.FileName
    $_.Contents
}