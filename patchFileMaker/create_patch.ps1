# UEBA Patch Creator - Enhanced with Commit Selection
param(
    [string]$PatchName = "",
    [string]$Description = "",
    [switch]$UseCommits = $false
)

# ============================================
# Fix Korean (UTF-8) encoding in PowerShell
# ============================================
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Set Git output encoding to UTF-8
$env:LC_ALL = 'C.UTF-8'
git config --global core.quotepath false

# ============================================
# Exclude Files List
# Add file names or patterns to exclude from patch
# ============================================
$excludeFiles = @(
    ".classpath",
    ".project",
    "AppConfig.xml",
    "jdbc-mysql.properties",
    "web.xml",
    "commons-util-2.5.jar"
    # Add more files to exclude here
    # Example: "test.properties", "debug.log"
)

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "  CloudESM Patch Creator (Enhanced)" -ForegroundColor Green
Write-Host "===============================================`n" -ForegroundColor Cyan

# Ask user for patch creation mode
if (-not $UseCommits) {
    Write-Host "Select patch creation mode:" -ForegroundColor Yellow
    Write-Host "  1. Current modified files (default)" -ForegroundColor White
    Write-Host "  2. Select from recent commits" -ForegroundColor White
    $modeChoice = Read-Host "`nMode (1/2)"
    
    if ($modeChoice -eq "2") {
        $UseCommits = $true
    }
}

$modifiedFiles = @()

if ($UseCommits) {
    # ============================================
    # Commit Selection Mode with Pagination & Search
    # ============================================
    
    $pageSize = 10
    $currentPage = 0
    $allCommits = @()
    $commits = @()
    $continueViewing = $true
    $searchMode = $false
    $searchKeyword = ""
    
    while ($continueViewing) {
        $skip = $currentPage * $pageSize
        
        # Build git log command based on search mode
        $gitLogCmd = if ($searchMode) {
            "git log --oneline --grep=`"$searchKeyword`" --skip=$skip -n $pageSize"
        } else {
            "git log --oneline --skip=$skip -n $pageSize"
        }
        
        # Get commits for current page
        $commits = Invoke-Expression $gitLogCmd | ForEach-Object {
            # Convert from UTF-8 if needed
            $line = if ($_ -is [byte[]]) {
                [System.Text.Encoding]::UTF8.GetString($_)
            } else {
                $_
            }
            $parts = $line -split ' ', 2
            @{
                Hash = $parts[0]
                Message = if ($parts.Count -gt 1) { $parts[1] } else { "" }
                GlobalIndex = $skip + $allCommits.Count
            }
        }
        
        # Add to all commits list
        $allCommits += $commits
        
        # Check if there are more commits
        $checkMoreCmd = if ($searchMode) {
            "git log --oneline --grep=`"$searchKeyword`" --skip=$($skip + $pageSize) -n 1"
        } else {
            "git log --oneline --skip=$($skip + $pageSize) -n 1"
        }
        $hasMore = (Invoke-Expression $checkMoreCmd).Count -gt 0
        
        # Display header
        $startNum = $skip + 1
        $endNum = $skip + $commits.Count
        Write-Host "`n===============================================" -ForegroundColor Cyan
        if ($searchMode) {
            Write-Host "  Search Results: '$searchKeyword' (Commits $startNum-$endNum)" -ForegroundColor Green
        } else {
            Write-Host "  Commits $startNum-$endNum" -ForegroundColor Green
        }
        Write-Host "===============================================`n" -ForegroundColor Cyan
        
        # Display commits with numbers
        for ($i = 0; $i -lt $commits.Count; $i++) {
            $num = $skip + $i + 1
            $commit = $commits[$i]
            Write-Host "  [$num] $($commit.Hash) - $($commit.Message)" -ForegroundColor White
        }
        
        # Display navigation options
        Write-Host "`n===============================================" -ForegroundColor Cyan
        Write-Host "Options:" -ForegroundColor Yellow
        Write-Host "  - Enter numbers to select (e.g., 1,3,5 or 1-3)" -ForegroundColor Gray
        if ($currentPage -gt 0) {
            Write-Host "  - Type 'prev' or 'p' to see previous commits" -ForegroundColor Gray
        }
        if ($hasMore) {
            Write-Host "  - Type 'next' or 'n' to see next commits" -ForegroundColor Gray
        }
        Write-Host "  - Type 'search' or 's' to search commits" -ForegroundColor Gray
        if ($searchMode) {
            Write-Host "  - Type 'clear' or 'c' to clear search" -ForegroundColor Gray
        }
        Write-Host "  - Press Enter to cancel" -ForegroundColor Gray
        Write-Host "===============================================`n" -ForegroundColor Cyan
        
        $selection = Read-Host "Selection"
        
        # Handle navigation and search
        if ($selection -eq "next" -or $selection -eq "n") {
            if ($hasMore) {
                $currentPage++
                continue
            } else {
                Write-Host "No more commits available." -ForegroundColor Yellow
                continue
            }
        } elseif ($selection -eq "prev" -or $selection -eq "p") {
            if ($currentPage -gt 0) {
                $currentPage--
                # Remove last page from allCommits
                $allCommits = $allCommits[0..($skip - 1)]
                continue
            } else {
                Write-Host "Already at first page." -ForegroundColor Yellow
                continue
            }
        } elseif ($selection -eq "search" -or $selection -eq "s") {
            # Search mode
            $keyword = Read-Host "Enter search keyword (commit message)"
            if (-not [string]::IsNullOrWhiteSpace($keyword)) {
                $searchMode = $true
                $searchKeyword = $keyword
                $currentPage = 0
                $allCommits = @()
                Write-Host "Searching for: '$searchKeyword'..." -ForegroundColor Yellow
                continue
            } else {
                Write-Host "Search cancelled." -ForegroundColor Yellow
                continue
            }
        } elseif ($selection -eq "clear" -or $selection -eq "c") {
            # Clear search mode
            if ($searchMode) {
                $searchMode = $false
                $searchKeyword = ""
                $currentPage = 0
                $allCommits = @()
                Write-Host "Search cleared. Showing all commits." -ForegroundColor Yellow
                continue
            } else {
                Write-Host "Not in search mode." -ForegroundColor Yellow
                continue
            }
        } else {
            # Selection made or cancelled
            $continueViewing = $false
        }
    }
    
    if ([string]::IsNullOrWhiteSpace($selection)) {
        Write-Host "Cancelled." -ForegroundColor Red
        exit 0
    }
    
    # Parse selection from all viewed commits
    $selectedIndices = @()
    $parts = $selection -split ','
    
    foreach ($part in $parts) {
        $part = $part.Trim()
        if ($part -match '^(\d+)-(\d+)$') {
            # Range (e.g., 1-3)
            $start = [int]$Matches[1]
            $end = [int]$Matches[2]
            for ($i = $start; $i -le $end; $i++) {
                if ($i -ge 1 -and $i -le $allCommits.Count) {
                    $selectedIndices += ($i - 1)
                }
            }
        } elseif ($part -match '^\d+$') {
            # Single number
            $num = [int]$part
            if ($num -ge 1 -and $num -le $allCommits.Count) {
                $selectedIndices += ($num - 1)
            }
        }
    }
    
    if ($selectedIndices.Count -eq 0) {
        Write-Host "No valid commits selected." -ForegroundColor Red
        exit 1
    }
    
    # Get unique indices and sort
    $selectedIndices = $selectedIndices | Select-Object -Unique | Sort-Object
    
    Write-Host "`nSelected commits:" -ForegroundColor Green
    $selectedHashes = @()
    foreach ($idx in $selectedIndices) {
        $commit = $allCommits[$idx]
        $selectedHashes += $commit.Hash
        Write-Host "  - $($commit.Hash) - $($commit.Message)" -ForegroundColor White
    }
    
    # Get all changed files from selected commits
    $allChangedFiles = @{}
    foreach ($hash in $selectedHashes) {
        # Check if it's a merge commit
        $parentCount = (git rev-list --parents -n 1 $hash | ForEach-Object { ($_ -split ' ').Count - 1 })
        
        if ($parentCount -gt 1) {
            # Merge commit: get files from the merge
            Write-Host "  Processing merge commit: $hash" -ForegroundColor Cyan
            $commitFiles = git diff-tree --no-commit-id --name-only -r -m --first-parent $hash
        } else {
            # Regular commit
            $commitFiles = git diff-tree --no-commit-id --name-only -r $hash
        }
        
        foreach ($file in $commitFiles) {
            if (-not [string]::IsNullOrWhiteSpace($file)) {
                $allChangedFiles[$file] = $true
            }
        }
    }
    
    $modifiedFiles = $allChangedFiles.Keys | ForEach-Object { $_ }
    
    Write-Host "`nTotal files from selected commits: $($modifiedFiles.Count)" -ForegroundColor Cyan
    
} else {
    # ============================================
    # Current Modified Files Mode
    # ============================================
    $modifiedFiles = git status --porcelain | Where-Object { $_ -match "^\s*M\s+" -or $_ -match "^\s*A\s+" } | ForEach-Object { $_.Substring(3).Trim() }
    
    if ($modifiedFiles.Count -eq 0) {
        Write-Host "No modified files found." -ForegroundColor Red
        exit 1
    }
}

# Get patch info (with UTF-8 encoding)
$branch = & git rev-parse --abbrev-ref HEAD 2>$null
if ($branch -is [byte[]]) {
    $branch = [System.Text.Encoding]::UTF8.GetString($branch)
}

if ([string]::IsNullOrWhiteSpace($PatchName)) {
    $PatchName = Read-Host "`nPatch Name (e.g. ISSUE-11)"
}

if ([string]::IsNullOrWhiteSpace($Description)) {
    $Description = Read-Host "Description"
}

Write-Host "`nCurrent Branch: $branch" -ForegroundColor Yellow
Write-Host "Patch Name: $PatchName`n" -ForegroundColor Yellow

# Filter out excluded files
$originalCount = $modifiedFiles.Count
$modifiedFiles = $modifiedFiles | Where-Object {
    $fileName = Split-Path $_ -Leaf
    $isExcluded = $false
    foreach ($excludePattern in $excludeFiles) {
        if ($fileName -like $excludePattern) {
            $isExcluded = $true
            Write-Host "  [EXCLUDED] $_" -ForegroundColor DarkGray
            break
        }
    }
    -not $isExcluded
}

$excludedCount = $originalCount - $modifiedFiles.Count
Write-Host "Found $originalCount modified files ($excludedCount excluded)`n" -ForegroundColor Green

$patchRoot = "www\ROOT"
if (Test-Path "www") { Remove-Item -Recurse -Force "www" }
New-Item -Path $patchRoot -ItemType Directory -Force | Out-Null

$copied = 0
$classAdded = 0
$jsAdded = 0

foreach ($file in $modifiedFiles) {
    $patchPath = $null
    $isJavaFile = $false
    $isJsFile = $false
    $actualFilePath = $file
    
    # Path mapping
    if ($file -match "^src/main/frontend/src/(.+)$") {
        # JavaScript files - use Grunt build output from target
        $isJsFile = $true
        $relativePath = $Matches[1] -replace "/", "\"
        $patchPath = "resources/$($Matches[1])"
        $actualFilePath = "target\CloudESM_WEB\resources\$relativePath"
    } elseif ($file -match "^src/main/java/(.+)\.java$") {
        # Java source file - skip copying source, only copy .class
        $isJavaFile = $true
        $relativePath = $Matches[1] -replace "/", "\"
        $patchPath = "WEB-INF/classes/$($Matches[1]).class"
        $actualFilePath = "target\classes\$relativePath.class"
    } elseif ($file -match "^src/main/java/(.+)$" -and $file -notmatch "\.java$") {
        # Other files in java folder (e.g. .xml) - but NOT .java files
        $patchPath = "WEB-INF/classes/$($Matches[1])"
    } elseif ($file -match "^src/main/webapp/WEB-INF/(.+)$") {
        $patchPath = "WEB-INF/$($Matches[1])"
    } elseif ($file -match "^src/main/webapp/resources/(.+)$") {
        $patchPath = "resources/$($Matches[1])"
    }
    
    if ($patchPath) {
        $destPath = Join-Path $patchRoot $patchPath
        $destDir = Split-Path -Parent $destPath
        if (-not (Test-Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }
        
        if (Test-Path $actualFilePath) {
            Copy-Item -Path $actualFilePath -Destination $destPath -Force
            
            if ($isJavaFile) {
                Write-Host "  [CLASS] $actualFilePath" -ForegroundColor Blue
                $classAdded++
            } elseif ($isJsFile) {
                Write-Host "  [JS] $actualFilePath (Grunt build)" -ForegroundColor Cyan
                $jsAdded++
            } else {
                Write-Host "  [OK] $file" -ForegroundColor Green
            }
            $copied++
        } else {
            if ($isJavaFile) {
                Write-Host "  [SKIP] $actualFilePath (not found, run 'mvn compile')" -ForegroundColor Yellow
            } elseif ($isJsFile) {
                Write-Host "  [SKIP] $actualFilePath (not found, run 'grunt build')" -ForegroundColor Yellow
            } else {
                Write-Host "  [SKIP] $file (not found)" -ForegroundColor Yellow
            }
        }
    }
}

# Create README (same level as ROOT folder, not inside www)
$readmePath = "PATCH_README.txt"
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$mode = if ($UseCommits) { "Commit Selection" } else { "Modified Files" }

@"
===============================================
  UEBA Partial Patch Guide
===============================================

Patch Name: $PatchName
Date: $date
Branch: $branch
Mode: $mode
Description: $Description

Files: $copied files ($classAdded .class files, $jsAdded .js files from Grunt build)

===============================================
  How to Apply
===============================================

1. Stop Tomcat Server

2. Copy files to Tomcat webapps/ROOT/
   
   Windows:
   xcopy /E /Y [PATCH_PATH]\* [TOMCAT_HOME]\webapps\ROOT\
   
   Linux:
   cp -r [PATCH_PATH]/* [TOMCAT_HOME]/webapps/ROOT/

3. Restart Tomcat Server

4. Clear browser cache (Ctrl+Shift+Del)

===============================================
  Cautions
===============================================

- Backup original files before applying patch
- Test in development environment first
- Verify Tomcat logs after restart

===============================================
"@ | Out-File -FilePath $readmePath -Encoding UTF8

Write-Host "`n[README] PATCH_README.txt created" -ForegroundColor Cyan

# Copy to Downloads folder (www folder with ROOT inside, and README at same level)
$downloadsPath = [Environment]::GetFolderPath('UserProfile') + "\Downloads\UEBA_Patch_$PatchName"
if (Test-Path $downloadsPath) {
    Remove-Item -Recurse -Force $downloadsPath
}
New-Item -Path $downloadsPath -ItemType Directory -Force | Out-Null
Copy-Item -Path "www" -Destination "$downloadsPath\www" -Recurse -Force
Copy-Item -Path "PATCH_README.txt" -Destination $downloadsPath -Force
Write-Host "[COPY] $downloadsPath" -ForegroundColor Yellow

# Create ZIP with proper directory entries
$zipPath = [Environment]::GetFolderPath('UserProfile') + "\Downloads\patch_$PatchName.zip"
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, 'Create')

try {
    # Add README file at root level (use full path)
    $readmeFullPath = Join-Path (Get-Location) "PATCH_README.txt"
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $readmeFullPath, "PATCH_README.txt") | Out-Null
    
    # Add www folder with ROOT inside
    Get-ChildItem -Path "www" -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring((Get-Location).Path.Length + 1) -replace "\\", "/"
        
        if ($_.PSIsContainer) {
            # Add directory entry (must end with /)
            if (-not $relativePath.EndsWith("/")) {
                $relativePath += "/"
            }
            [void]$zip.CreateEntry($relativePath)
        } else {
            # Add file entry
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $relativePath) | Out-Null
        }
    }
} finally {
    $zip.Dispose()
}

$zipSize = [math]::Round((Get-Item $zipPath).Length / 1KB, 2)
Write-Host "[ZIP] $zipPath ($zipSize KB)`n" -ForegroundColor Yellow

# Summary
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Patch Created Successfully!" -ForegroundColor Green
Write-Host "===============================================`n" -ForegroundColor Cyan
Write-Host "Mode: $mode" -ForegroundColor White
Write-Host "Total files: $copied" -ForegroundColor White
Write-Host ".class files: $classAdded" -ForegroundColor Blue
Write-Host ".js files (Grunt): $jsAdded" -ForegroundColor Cyan
Write-Host "`nLocation: $downloadsPath`n" -ForegroundColor White

$open = Read-Host "Open downloads folder? (Y/N)"
if ($open -eq "Y" -or $open -eq "y") {
    explorer ([Environment]::GetFolderPath('UserProfile') + "\Downloads")
}
