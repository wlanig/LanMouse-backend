# LanMouse Auto Debug Script

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("backend", "mobile", "pc-server", "all")]
    [string]$Component = "all",
    
    [Parameter(Mandatory=$false)]
    [string]$Action = "build",
    
    [Parameter(Mandatory=$false)]
    [switch]$Deploy,
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoFix
)

$ErrorActionPreference = "Continue"
$projectRoot = "D:\CodeBuddy_Project\LanMouse"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LanMouse Auto Debug" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
$logFile = "$env:TEMP\lanmouse_debug_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
$errors = @()

function Write-Step {
    param($msg)
    Write-Host "[STEP] $msg" -ForegroundColor Yellow
}

function Write-Success {
    param($msg)
    Write-Host "[OK] $msg" -ForegroundColor Green
}

function Write-Err {
    param($msg)
    Write-Host "[ERROR] $msg" -ForegroundColor Red
}

Write-Step "Starting auto debug..."
Write-Step "Component: $Component"
Write-Step "Log file: $logFile"
Write-Host ""

# Backend Debug
function Debug-Backend {
    Write-Host ""
    Write-Step "Debugging Backend (Spring Boot)..."
    Write-Host ""
    
    Set-Location "$projectRoot\backend"
    
    # Check Maven
    Write-Step "Checking Maven..."
    try {
        $mvnVersion = & mvn -v 2>&1 | Select-Object -First 1
        if ($mvnVersion -match "Apache Maven") {
            Write-Success "Maven OK"
        }
    } catch {
        Write-Err "Maven not installed"
        $errors += "Maven not installed"
        return $false
    }
    
    # Build
    Write-Step "Running Maven build..."
    $output = & mvn clean package -DskipTests 2>&1
    $exitCode = $LASTEXITCODE
    
    $output | Out-File -FilePath "$env:TEMP\maven_output.txt" -Encoding UTF8
    
    if ($exitCode -ne 0) {
        Write-Err "Maven build failed"
        $errors += "Maven build failed"
        
        if ($AutoFix) {
            Write-Step "Attempting auto fix..."
            
            $errorLines = $output | Select-String -Pattern "error:|ERROR|Exception" | Select-Object -First 10
            
            foreach ($line in $errorLines) {
                Write-Host "  > $line" -ForegroundColor Red
            }
            
            if ($output -match "Could not find") {
                Write-Step "Resolving dependencies..."
                & mvn dependency:resolve 2>&1 | Out-Null
            }
            
            if ($output -match "cannot find symbol") {
                Write-Step "Clean and recompile..."
                & mvn clean 2>&1 | Out-Null
                & mvn compile 2>&1 | Out-File -FilePath "$env:TEMP\maven_compile.txt"
            }
        }
        
        return $false
    }
    
    Write-Success "Backend build successful"
    return $true
}

# Mobile Debug
function Debug-Mobile {
    Write-Host ""
    Write-Step "Debugging Mobile (Flutter)..."
    Write-Host ""
    
    Set-Location "$projectRoot\mobile"
    
    Write-Step "Checking Flutter..."
    try {
        $flutterVersion = & flutter --version 2>&1 | Select-Object -First 1
        Write-Success "Flutter OK"
    } catch {
        Write-Err "Flutter not installed"
        $errors += "Flutter not installed"
        return $false
    }
    
    Write-Step "Getting dependencies..."
    $output = & flutter pub get 2>&1
    $exitCode = $LASTEXITCODE
    
    $output | Out-File -FilePath "$env:TEMP\flutter_deps.txt" -Encoding UTF8
    
    if ($exitCode -ne 0) {
        Write-Err "Flutter dependencies failed"
        $errors += "Flutter dependencies failed"
        return $false
    }
    
    Write-Success "Mobile ready"
    return $true
}

# PC Server Debug
function Debug-PCServer {
    Write-Host ""
    Write-Step "Debugging PC Server (Node.js)..."
    Write-Host ""
    
    Set-Location "$projectRoot\pc-server"
    
    Write-Step "Checking Node.js..."
    try {
        $nodeVersion = & node --version 2>&1
        Write-Success "Node.js OK: $nodeVersion"
    } catch {
        Write-Err "Node.js not installed"
        $errors += "Node.js not installed"
        return $false
    }
    
    if (-not (Test-Path "node_modules")) {
        Write-Step "Installing npm dependencies..."
        $output = & npm install 2>&1
        $exitCode = $LASTEXITCODE
        
        $output | Out-File -FilePath "$env:TEMP\npm_install.txt" -Encoding UTF8
        
        if ($exitCode -ne 0) {
            Write-Err "npm install failed"
            $errors += "npm install failed"
            return $false
        }
    }
    
    Write-Success "PC Server ready"
    return $true
}

# Execute Debug
$results = @{}

switch ($Component) {
    "backend" { $results["backend"] = Debug-Backend }
    "mobile" { $results["mobile"] = Debug-Mobile }
    "pc-server" { $results["pc-server"] = Debug-PCServer }
    "all" {
        $results["backend"] = Debug-Backend
        $results["mobile"] = Debug-Mobile
        $results["pc-server"] = Debug-PCServer
    }
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# Report
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Debug Report" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor White
Write-Host ""

$hasErrors = $false
foreach ($component in $results.Keys) {
    $status = if ($results[$component]) { "SUCCESS" } else { "FAILED" }
    $color = if ($results[$component]) { "Green" } else { "Red" }
    
    Write-Host "  $component : " -NoNewline
    Write-Host $status -ForegroundColor $color
    
    if (-not $results[$component]) {
        $hasErrors = $true
    }
}

Write-Host ""

if ($hasErrors) {
    Write-Host "Status: " -NoNewline
    Write-Host "Errors found" -ForegroundColor Red
} else {
    Write-Host "Status: " -NoNewline
    Write-Host "All passed" -ForegroundColor Green
}

Write-Host ""
Write-Host "Log file: $logFile" -ForegroundColor Cyan
Write-Host ""

# Copy to clipboard
$clipboardContent = @"
LanMouse Auto Debug Report
============================
Component: $Component
Duration: $([math]::Round($duration, 2))s
Errors: $($errors.Count)
============================
"@

if ($errors.Count -gt 0) {
    $clipboardContent += "`n`nErrors:`n"
    foreach ($e in $errors) {
        $clipboardContent += "- $e`n"
    }
}

$clipboardContent | Set-Clipboard
Write-Host "Report copied to clipboard" -ForegroundColor Green
Write-Host ""
Write-Host 'In CodeBuddy: "analyze these errors and fix the issues"' -ForegroundColor Yellow
Write-Host ""

return @{
    Results = $results
    Errors = $errors
    Duration = $duration
    LogFile = $logFile
}
