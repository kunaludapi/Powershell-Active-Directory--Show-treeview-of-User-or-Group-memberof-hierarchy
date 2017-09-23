https://www.reddit.com/r/usefulscripts/comments/71d745/powershell_active_directory_show_treeview_of_user/
#requires -version 4
<#
.SYNOPSIS
Show UpStream tree view hierarchy of memberof groups recursively of a Active Directory user and Group.
.DESCRIPTION
The Show-ADGroupTreeViewMemberOf list all nested group list of a AD user. It requires only valid parameter AD username, 
.PARAMETER UserName
Prompts you valid active directory User name. You can use first character as an alias, If information is not provided it provides 'Administrator' user information. 
.PARAMETER GroupName
Prompts you valid active directory Group name. You can use first character as an alias, If information is not provided it provides 'Domain Admins' group[ information.
.INPUTS
Microsoft.ActiveDirectory.Management.ADUser
.OUTPUTS
Microsoft.ActiveDirectory.Management.ADGroup
.NOTES
Version:        1.0
Author:         Kunal Udapi
Creation Date:  10 September 2017
Purpose/Change: Get the exact nested group info of user
Useful URLs: http://vcloud-lab.com
.EXAMPLE
PS C:\>.\Get-ADGroupTreeViewMemberOf -UserName Administrator

This list all the upstream memberof group of an user.
.EXAMPLE
PS C:\>.\Get-ADGroupTreeViewMemberOf -GroupName DomainAdmins

This list all the upstream memberof group of a Group.
#>

[CmdletBinding(SupportsShouldProcess=$True,
ConfirmImpact='Medium',
HelpURI='http://vcloud-lab.com',
DefaultParameterSetName='User')]
Param
(
[parameter(ParameterSetName = 'User',Position=0, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, HelpMessage='Type valid AD username')]
[alias('User')]
[String]$UserName = 'Administrator',
[parameter(ParameterSetName = 'Group',Position=0, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, HelpMessage='Type valid AD Group')]
[alias('Group')]
[String]$GroupName = 'Domain Admins',
[parameter(ParameterSetName = 'Group', DontShow=$True)]
[parameter(ParameterSetName = 'User', DontShow=$True)]
[alias('U')]
$UpperValue = [System.Int32]::MaxValue,
[parameter(ParameterSetName = 'Group', DontShow=$True)]
[parameter(ParameterSetName = 'User', DontShow=$True)]
[alias('L')]
$LowerValue = 2
)

if (!(Get-Module Activedirectory)) {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop 
    }
    catch {
        Write-Host -Object "ActiveDirectory Module didn't find, Please install it and try again" -BackgroundColor DarkRed
        Break
    }
}

function Get-ADGroupTreeViewMemberOf {
    [CmdletBinding(SupportsShouldProcess=$True,
    ConfirmImpact='Medium',
    HelpURI='http://vcloud-lab.com',
    DefaultParameterSetName='User')]
    Param
    (
    [parameter(ParameterSetName = 'User',Position=0, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, HelpMessage='Type valid AD username')]
    [alias('User')]
    [String]$UserName = 'Administrator',
    [parameter(ParameterSetName = 'Group',Position=0, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, HelpMessage='Type valid AD Group')]
    [alias('Group')]
    [String]$GroupName = 'Domain Admins',
    [parameter(ParameterSetName = 'Group', DontShow=$True)]
    [parameter(ParameterSetName = 'User', DontShow=$True)]
    [alias('U')]
    $UpperValue = [System.Int32]::MaxValue,
    [parameter(ParameterSetName = 'Group', DontShow=$True)]
    [parameter(ParameterSetName = 'User', DontShow=$True)]
    [alias('L')]
    $LowerValue = 2
    )
    begin {
        switch ($PsCmdlet.ParameterSetName) {
            'Group' {
                try {
                    $Group =  Get-ADGroup $GroupName -Properties Memberof -ErrorAction Stop 
                    $MemberOf = $Group | Select-Object -ExpandProperty Memberof 
                    $rootname = $Group.Name
                }
                catch {
                    Write-Host -Object "`'$GroupName`' groupname doesn't exist in Active Directory, Please try again." -BackgroundColor DarkRed
                    $result = 'Break'
                    Break
                }
                break            
            }
            'User' {
                try {
                    $User = Get-ADUser $UserName -Properties Memberof -ErrorAction Stop
                    $MemberOf = $User | Select-Object -ExpandProperty Memberof -ErrorAction Stop
                    $rootname = $User.Name

                }
                catch {
                    Write-Host -Object "`'$($User.Name)`' username doesn't exist in Active Directory, Please try again." -BackgroundColor DarkRed
                    $result = 'Break'
                    Break
                }
                Break
            }
        }
    }
    Process {
        $Minus = $LowerValue - 2
        $Spaces = " " * $Minus
        $Lines = "__"
        "{0}{1}{2}{3}" -f $Spaces, '|', $Lines, $rootname        
        $LowerValue++
        $LowerValue++
        if ($LowerValue -le $UpperValue) {
            foreach ($member in $MemberOf) {
                $UpperGroup = Get-ADGroup $member -Properties Memberof
                $LowerGroup = $UpperGroup | Get-ADGroupMember -ErrorAction SilentlyContinue
                $LoopCheck = $UpperGroup.MemberOf | ForEach-Object {$lowerGroup.distinguishedName -contains $_}

                if ($LoopCheck -Contains $True) {
                    $rootname = $UpperGroup.Name
                    Write-Host "Loop found on $($UpperGroup.Name), Skipping..." -BackgroundColor DarkRed
                    Continue
                }
                Get-ADGroupTreeViewMemberOf -GroupName $member -LowerValue $LowerValue -UpperValue $UpperValue
            } 
        }
    }
 }

 switch ($PsCmdlet.ParameterSetName) {
    'Group' {
        Get-ADGroupTreeViewMemberOf -GroupName $GroupName
        break            
    }
    'User' {
        Get-ADGroupTreeViewMemberOf -UserName $UserName
        Break
    }
}
