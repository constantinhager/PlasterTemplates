$Source = Get-ChildItem $PSScriptRoot\src\*.ps1 -Recurse -ErrorAction SilentlyContinue

Foreach ($import in $Source)
{
    . $import.fullname
}