$ConfigurationFile = Get-Content (Join-Path $PSScriptRoot dbconfig.json) | ConvertFrom-Json


Import-Module (Join-Path $PSScriptRoot $ConfigurationFile.dashboard.rootmodule) -ErrorAction Stop -Force

. (Join-Path $PSScriptRoot "themes\*.ps1")

$PageFolder = Get-ChildItem (Join-Path $PSScriptRoot pages)

$Pages = Foreach ($Page in $PageFolder)
{
    . $Page.FullName
}

$Initialization = New-UDEndpointInitialization -Module @(Join-Path $PSScriptRoot $ConfigurationFile.dashboard.rootmodule)

$DashboardParams = @{
    Title                  = $ConfigurationFile.dashboard.title
    Theme                  = $SampleTheme
    Pages                  = $Pages
    EndpointInitialization = $Initialization
}

Get-UDDashboard | Stop-UDDashboard

$MyDashboard = New-UDDashboard @DashboardParams

Start-UDDashboard -Port $ConfigurationFile.dashboard.port -Dashboard $MyDashboard -Name $ConfigurationFile.dashboard.title