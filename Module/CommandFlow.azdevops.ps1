Param(
    [Parameter()]
    [string]
    $DestinationPath,

    [Parameter()]
    [string]
    $srcPath,

    [Parameter()]
    [switch]
    $HideGraph
)

$exportParams = @{
    ShowGraph = $true
}

if ($HideGraph)
{
    $exportParams.ShowGraph = $false
}

if ($DestinationPath)
{
    $exportParams.DestinationPath = $DestinationPath
}

$moduleRoot = $srcPath

$folders = @()
if (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath "Public"))
{
    $folders += Get-ChildItem (Join-Path -Path $moduleRoot -ChildPath "Public\*.ps1")
}

if (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath "Private"))
{
    $folders += Get-ChildItem (Join-Path -Path $moduleRoot -ChildPath "Private\*.ps1")
}

graph CommandFlow {
    $scripts = @{ }

    Get-ChildItem -Path $folders |
    ForEach-Object -Process {
        $scripts[$PSItem.BaseName] = $PSItem.FullName
    }

    $scriptNames = $scripts.Keys | Sort-Object
    ForEach ($script in $scriptNames)
    {
        node $script
        $contents = Get-Content -Path $scripts[$script] -ErrorAction Stop
        $errors = $null
        $commands = ([System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors) |
            Where-Object -FilterScript { $PSItem.Type -eq 'Command' }).Content
        ForEach ($command in $commands)
        {
            If ($scripts[$command])
            {
                Edge  $script -To $command
            }
        }
    }
} | Export-PSGraph @exportParams
