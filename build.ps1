param(
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path -LiteralPath $vswhere)) {
    throw "Visual Studio Installer's vswhere.exe was not found."
}

$installation = & $vswhere -latest -products * `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath
if (-not $installation) {
    throw "Visual Studio with the C++ x64 toolchain was not found."
}

$vcvars = Join-Path $installation "VC\Auxiliary\Build\vcvars64.bat"
$buildDirectory = Join-Path $PSScriptRoot "build"
New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null

$optimization = if ($Configuration -eq "Release") { "/O2" } else { "/Od /Zi" }
$compileCommand = @(
    "cl.exe /nologo /std:c++20 /J /EHsc $optimization"
    "main.cpp ast\ast.cpp bytecode\bytecode.cpp bytecode\prototype.cpp lua\lua.cpp"
    "/Fo:build\ /Fe:luajit-decompiler-v2.exe"
    "/link shlwapi.lib user32.lib comdlg32.lib"
) -join " "
$command = "call `"$vcvars`" && $compileCommand"

Push-Location $PSScriptRoot
try {
    & $env:ComSpec /d /s /c $command
    if ($LASTEXITCODE -ne 0) {
        throw "C++ build failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}

Write-Host "Built $PSScriptRoot\luajit-decompiler-v2.exe"
