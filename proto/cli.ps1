[CmdletBinding()]
param()

# --- Git style
# > pspm project new
# > pspm project list
# > pspm project select 1
# > pspm project edit DueDate 2020/12/31
# > pspm project add ProjectManager 1
# > pspm project add ProjectMembers 1

# > pspm time start
# > pspm time end
# > pspm time now

# > pspm worker new
# > pspm worker list
# > pspm worker edit Name Steve Mayers


# --- enter cli
# > pspm
# Projects:
# 1. Powershell based project management tool
#  L 1. Objects
#  L 2. Saving Mechanism
#  L 3. CLI

# [S]elect  [U]p  [N]ew  [E]dit  [M]ore
# > _


# --- powershell as CLI
# | Good points: 
# | Easy to program
# | No need to write interface

# [Object[]] $Objs
# [Project[]] $Projs
# [Worker[]] $Workers
# [TimeEntry[]] $TimeEntries
# [Stakeholder[]] $Stakeholders

# function Add-Object
# function Add-Project : Add-Object
# function Add-Worker : Add-Object
# function Add-TimeEntry : Add-Object
# function Add-Stakeholder : Add-Object

# function Save-AllObjects
# function Load-AllObjects

# function View-ProjectTree
# function View-Schedule

