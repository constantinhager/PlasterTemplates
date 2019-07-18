$ConfigurationFile = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "dbconfig.json") | ConvertFrom-Json

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ConfigurationFile.dashboard.rootmodule) -ErrorAction Stop -Force

$PageFolder = Get-ChildItem (Join-Path -Path $PSScriptRoot -ChildPath pages)
<%
if ($PLASTER_PARAM_DashboardTheme -eq 'Yes')
{
    ". (Join-Path -Path `$PSScriptRoot -ChildPath 'themes\*.ps1')"
}
%>
<%
if ($PLASTER_PARAM_EndPointSupport -eq 'Yes')
{
    "`$EndpointFolder = Get-ChildItem (Join-Path -Path `$PSScriptRoot -ChildPath 'endpoints') -File `n"

    "`$EndPoints = foreach (`$endpoint in `$EndpointFolder) {
    . `$endpoint.FullName
}"
}
%>
$Pages = Foreach ($Page in $PageFolder)
{
    . $Page.FullName
}
<%
if ($PLASTER_PARAM_NavBarSupport -eq 'Yes')
{
    @"
`$Navigation = New-UDSideNav -Content {
    New-UDSideNavItem -Text 'Home' -PageName '<%=$PLASTER_PARAM_DashboardTitle%>' -Icon home
}
"@
}
%>
$Initialization = New-UDEndpointInitialization -Module @(Join-Path $PSScriptRoot $ConfigurationFile.dashboard.rootmodule)

<%
if ($PLASTER_PARAM_NavBarSupport -eq 'Yes')
{
    @"
`$DashboardParams = @{
    Title                  = `$ConfigurationFile.dashboard.title
    Theme                  = `$SampleTheme
    Pages                  = `$Pages
    EndpointInitialization = `$Initialization
    Navigation             = `$Navigation
}
"@
}
else
{
    @"
`$DashboardParams = @{
    Title                  = `$ConfigurationFile.dashboard.title
    Theme                  = `$SampleTheme
    Pages                  = `$Pages
    EndpointInitialization = `$Initialization
}
"@
}
%>

Get-UDDashboard | Stop-UDDashboard

$MyDashboard = New-UDDashboard @DashboardParams

<%
if ($PLASTER_PARAM_EndPointSupport -eq 'Yes')
{
    "Start-UDDashboard -Port `$ConfigurationFile.dashboard.port -Dashboard `$MyDashboard -Name `$ConfigurationFile.dashboard.title -Wait -Endpoint `$EndPoints"
}
else
{
    "Start-UDDashboard -Port `$ConfigurationFile.dashboard.port -Dashboard `$MyDashboard -Name `$ConfigurationFile.dashboard.title -Wait"
}
%>