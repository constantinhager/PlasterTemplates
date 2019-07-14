task . Clean, Build, Tests, BuildMarkdown, ExportHelp, GenerateGraph, Stats
task Tests ImportCompipledModule, Pester
task CreateManifest CopyPSD, UpdatPublicFunctionsToExport
task Build Compile, CreateManifest
task Stats RemoveStats, WriteStats
task Help BuildMarkdown, ExportHelp

$ModuleName = Split-Path -Path $PSScriptRoot -Leaf
$srcPath = Join-Path -Path $PSScriptRoot -ChildPath "src"
$srcModulePath = Join-Path -Path $srcPath -ChildPath "$($ModuleName).psd1"
$srcModuleVersion = (Import-PowerShellDataFile -Path $srcModulePath).ModuleVersion
$graphsPath = Join-Path -Path $srcPath -ChildPath "Graphs"
$docsPath = [System.IO.Path]::Combine($PSScriptRoot, "docs", "en-US")
$OutPutFolder = "$PSScriptRoot\Release"
$statsjsonPath = [System.IO.Path]::Combine($OutPutFolder, $ModuleName, $srcModuleVersion, "stats.json")
$ImportFolders = @('Public', 'Private')
$PsmPath = Join-Path -Path $PSScriptRoot -ChildPath "Release\$($ModuleName)\$($srcModuleVersion)\$($ModuleName).psm1"
$PsdPath = Join-Path -Path $PSScriptRoot -ChildPath "Release\$($ModuleName)\$($srcModuleVersion)\$($ModuleName).psd1"
$HelpPath = Join-Path -Path $PSScriptRoot -ChildPath "Release\$($ModuleName)\$($srcModuleVersion)\en-US"
$PublicFolder = Join-Path -Path $srcPath -ChildPath 'Public'

task "Clean" {
    if (-not(Test-Path $OutPutFolder))
    {
        New-Item -ItemType Directory -Path $OutPutFolder > $null
    }

    Remove-Item -Path "$($OutPutFolder)\*" -Force -Recurse
}

task Compile {
    if (Test-Path -Path $PsmPath)
    {
        Remove-Item -Path $PsmPath -Recurse -Force
    }
    New-Item -Path $PsmPath -Force > $null

    foreach ($folder in $ImportFolders)
    {
        $currentFolder = Join-Path -Path $srcPath -ChildPath $folder
        Write-Verbose -Message "Checking folder [$currentFolder]"

        if (Test-Path -Path $currentFolder)
        {
            $files = Get-ChildItem -Path $currentFolder -File -Filter '*.ps1'
            foreach ($file in $files)
            {
                Write-Verbose -Message "Adding $($file.FullName)"
                Get-Content -Path $file.FullName >> $PsmPath
            }
        }
    }
}

task CopyPSD {
    New-Item -Path (Split-Path $PsdPath) -ItemType Directory -ErrorAction 0
    $copy = @{
        Path        = Join-Path -Path $srcPath -ChildPath "$($ModuleName).psd1"
        Destination = $PsdPath
        Force       = $true
        Verbose     = $true
    }
    Copy-Item @copy
}

task UpdatPublicFunctionsToExport -if (Test-Path -Path $PublicFolder) {
    $publicFunctions = (Get-ChildItem -Path $PublicFolder |
        Select-Object -ExpandProperty BaseName) -join "', '"

    $publicFunctions = "FunctionsToExport = @('{0}')" -f $publicFunctions

    (Get-Content -Path $PsdPath) -replace "FunctionsToExport = '\*'", $publicFunctions | Set-Content -Path $PsdPath
}

task ImportCompipledModule -if (Test-Path -Path $PsmPath) {
    Get-Module -Name $ModuleName |
    Remove-Module -Force
    Import-Module -Name $PsdPath -Force
}

task Pester {
    $resultFile = "{0}\testResults{1}.xml" -f $OutPutFolder, (Get-date -Format 'yyyyMMdd_hhmmss')
    $testFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Tests\*'
    Invoke-Pester -Path $testFolder -OutputFile $resultFile -OutputFormat NUnitxml
}

task GenerateGraph -if (Test-Path -Path $graphsPath) {
    $Graphs = Get-ChildItem -Path $graphsPath

    Foreach ($graph in $Graphs)
    {
        $graphLocation = [IO.Path]::Combine($OutPutFolder, $ModuleName, $srcModuleVersion, "$($graph.BaseName).png")
        . $graph.FullName -DestinationPath $graphLocation -Hide
    }
}

task RemoveStats {
    if (Test-Path -Path $statsjsonPath)
    {
        Remove-Item -Force -Verbose -Path $statsjsonPath
    }
}

task WriteStats {
    $folders = Get-ChildItem -Directory |
    Where-Object { $PSItem.Name -ne 'Release' }

    $stats = foreach ($folder in $folders)
    {
        $files = Get-ChildItem "$($folder.FullName)\*" -File
        if ($files)
        {
            Get-Content -Path $files |
            Measure-Object -Word -Line -Character |
            Select-Object -Property @{N = "FolderName"; E = { $folder.Name } }, Words, Lines, Characters
        }
    }
    $stats | ConvertTo-Json > $statsjsonPath
}

task ExportHelp -if (Test-Path -Path $docsPath) {
    New-ExternalHelp -Path $docsPath -OutputPath $HelpPath -Force
}

task BuildMarkdown {
    $moduleInfo = Import-Module $PsdPath -Global -Force -PassThru

    if ($moduleInfo.ExportedCommands.Count -eq 0)
    {
        Write-Output "No commands have been exported. Skipping Step BuildMarkdown."
        return
    }

    if (Get-ChildItem -Path $docsPath)
    {
        Get-ChildItem -Path $docsPath | Remove-Item -Exclude about* -Force
    }

    # ErrorAction set to SilentlyContinue so this command will not overwrite an existing MD file.
    $splat = @{
        Module       = $ModuleName
        Locale       = "en-US"
        OutputFolder = $docsPath
        ErrorAction  = "SilentlyContinue"
    }

    New-MarkdownHelp @splat
}