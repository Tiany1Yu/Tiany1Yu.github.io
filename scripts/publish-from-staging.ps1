$ErrorActionPreference = "Stop"

function Get-ConfigAuthor {
  param([string]$ConfigPath)

  if (-not (Test-Path -LiteralPath $ConfigPath)) {
    return ""
  }

  foreach ($line in Get-Content -LiteralPath $ConfigPath -Encoding UTF8) {
    if ($line -match '^author:\s*(.+?)\s*$') {
      $value = $matches[1].Trim()
      $value = ($value -replace '\s+#.*$', '').Trim()
      return $value
    }
  }

  return ""
}

function Remove-InvalidFileNameChars {
  param([string]$Name)

  $invalid = [System.IO.Path]::GetInvalidFileNameChars()
  $buffer = New-Object System.Text.StringBuilder

  foreach ($ch in $Name.ToCharArray()) {
    if ($invalid -contains $ch) {
      [void]$buffer.Append('-')
    } else {
      [void]$buffer.Append($ch)
    }
  }

  $clean = $buffer.ToString().Trim()
  $clean = $clean -replace '\s+', '-'
  $clean = $clean -replace '-{2,}', '-'
  $clean = $clean.Trim('-','.')

  if ([string]::IsNullOrWhiteSpace($clean)) {
    return "post"
  }

  return $clean
}

function Get-FrontMatter {
  param([string]$Text)

  $result = @{
    HasFrontMatter = $false
    FrontMatterText = ""
    Body = $Text
  }

  if (-not $Text.StartsWith("---`n") -and -not $Text.StartsWith("---`r`n")) {
    return $result
  }

  $delimiterRegex = [regex]'(?m)^---\s*$'
  $matches = $delimiterRegex.Matches($Text)
  if ($matches.Count -lt 2) {
    return $result
  }

  $first = $matches[0]
  $second = $matches[1]
  if ($first.Index -ne 0) {
    return $result
  }

  $fmStart = $first.Index + $first.Length
  $fmLength = $second.Index - $fmStart
  if ($fmLength -lt 0) {
    return $result
  }

  $frontMatterText = $Text.Substring($fmStart, $fmLength).Trim("`r", "`n")
  $bodyStart = $second.Index + $second.Length
  $body = $Text.Substring($bodyStart).TrimStart("`r", "`n")

  $result.HasFrontMatter = $true
  $result.FrontMatterText = $frontMatterText
  $result.Body = $body
  return $result
}

function Parse-SimpleFrontMatter {
  param([string]$FrontMatterText)

  $map = @{}
  if ([string]::IsNullOrWhiteSpace($FrontMatterText)) {
    return $map
  }

  foreach ($line in ($FrontMatterText -split "`r?`n")) {
    if ($line -match '^\s*([A-Za-z0-9_\-]+)\s*:\s*(.*)$') {
      $key = $matches[1].Trim().ToLowerInvariant()
      $value = $matches[2].Trim()
      $map[$key] = $value
    }
  }

  return $map
}

function Get-FirstMarkdownTitle {
  param([string]$Body)

  foreach ($line in ($Body -split "`r?`n")) {
    if ($line -match '^#\s+(.+?)\s*$') {
      return $matches[1].Trim()
    }
  }

  return ""
}

function Convert-ToDisplayDate {
  param([datetimeoffset]$Date)

  $formatted = $Date.ToString("yyyy-MM-dd HH:mm:ss zzz")
  return ($formatted -replace '([+-]\d{2}):(\d{2})$', '$1$2')
}

function Get-ExistingOrUniquePath {
  param([string]$DesiredPath)

  if (-not (Test-Path -LiteralPath $DesiredPath)) {
    return $DesiredPath
  }

  $dir = [System.IO.Path]::GetDirectoryName($DesiredPath)
  $name = [System.IO.Path]::GetFileNameWithoutExtension($DesiredPath)
  $ext = [System.IO.Path]::GetExtension($DesiredPath)

  $i = 1
  while ($true) {
    $candidate = Join-Path $dir ("{0}-{1}{2}" -f $name, $i, $ext)
    if (-not (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
    $i++
  }
}

function Get-FirstImageRelativePath {
  param([string]$FolderPath)

  $extSet = @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.avif')
  $images = Get-ChildItem -LiteralPath $FolderPath -Recurse -File |
    Where-Object { $extSet -contains $_.Extension.ToLowerInvariant() } |
    Sort-Object FullName

  if ($images.Count -eq 0) {
    return ""
  }

  $relative = $images[0].FullName.Substring($FolderPath.Length).TrimStart('\','/')
  return ($relative -replace '\\', '/')
}

function Rewrite-LocalImageLinks {
  param(
    [string]$Body,
    [string]$ArticleFolder,
    [string]$PublicImageBase
  )

  $resolver = {
    param($pathText)

    $trimmed = $pathText.Trim()
    if ($trimmed -match '^(https?:)?//|^/|^#|^data:|^\{\{') {
      return $trimmed
    }

    $candidate = Join-Path $ArticleFolder $trimmed
    if (-not (Test-Path -LiteralPath $candidate)) {
      return $trimmed
    }

    return ("/{0}/{1}" -f $PublicImageBase.Trim('/'), ($trimmed -replace '\\', '/'))
  }

  $markdownPattern = [regex]'!\[(?<alt>[^\]]*)\]\((?<path>[^)\s]+)(?<tail>[^)]*)\)'
  $body = $markdownPattern.Replace($Body, {
    param($m)
    $alt = $m.Groups['alt'].Value
    $path = $m.Groups['path'].Value
    $tail = $m.Groups['tail'].Value
    $newPath = & $resolver $path
    return "![${alt}](${newPath}${tail})"
  })

  $htmlPattern = [regex]'(<img[^>]*?src\s*=\s*["''])(?<path>[^"'']+)(["''][^>]*>)'
  $body = $htmlPattern.Replace($body, {
    param($m)
    $prefix = $m.Groups[1].Value
    $path = $m.Groups['path'].Value
    $suffix = $m.Groups[3].Value
    $newPath = & $resolver $path
    return "${prefix}${newPath}${suffix}"
  })

  return $body
}

function Move-ToProcessed {
  param([string]$ArticleFolder, [string]$ProcessedRoot)

  if (-not (Test-Path -LiteralPath $ProcessedRoot)) {
    New-Item -Path $ProcessedRoot -ItemType Directory | Out-Null
  }

  $name = Split-Path -Leaf $ArticleFolder
  $target = Join-Path $ProcessedRoot $name
  if (Test-Path -LiteralPath $target) {
    $suffix = Get-Date -Format "yyyyMMdd-HHmmss"
    $target = Join-Path $ProcessedRoot ("{0}-{1}" -f $name, $suffix)
  }

  Move-Item -LiteralPath $ArticleFolder -Destination $target
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$stagingRoot = Join-Path $repoRoot "to_be_posted"
$processedRoot = Join-Path $stagingRoot "_processed"
$postsRoot = Join-Path $repoRoot "_posts"
$assetsImgRoot = Join-Path $repoRoot "assets\img"
$configPath = Join-Path $repoRoot "_config.yml"

if (-not (Test-Path -LiteralPath $stagingRoot)) {
  Write-Host "[INFO] to_be_posted folder not found. Exit."
  exit 0
}

$defaultAuthor = Get-ConfigAuthor -ConfigPath $configPath
if ([string]::IsNullOrWhiteSpace($defaultAuthor)) {
  $defaultAuthor = ""
}

$articleDirs = Get-ChildItem -LiteralPath $stagingRoot -Directory |
  Where-Object { $_.Name -ne "_processed" } |
  Sort-Object Name

if ($articleDirs.Count -eq 0) {
  Write-Host "[INFO] No pending article folders under to_be_posted."
  exit 0
}

$processedCount = 0

foreach ($dir in $articleDirs) {
  try {
    $mdFiles = Get-ChildItem -LiteralPath $dir.FullName -File -Filter *.md | Sort-Object Name
    if ($mdFiles.Count -eq 0) {
      Write-Host "[SKIP] $($dir.Name): no markdown file found."
      continue
    }

    $md = $mdFiles[0]
    if ($mdFiles.Count -gt 1) {
      Write-Host "[WARN] $($dir.Name): multiple markdown files found, using $($md.Name)."
    }

    $raw = [System.IO.File]::ReadAllText($md.FullName, [System.Text.Encoding]::UTF8)
    $fmResult = Get-FrontMatter -Text $raw
    $fmMap = Parse-SimpleFrontMatter -FrontMatterText $fmResult.FrontMatterText
    $body = $fmResult.Body

    $title = ""
    if ($fmMap.ContainsKey('title') -and -not [string]::IsNullOrWhiteSpace($fmMap['title'])) {
      $title = $fmMap['title']
    }
    if ([string]::IsNullOrWhiteSpace($title)) {
      $title = Get-FirstMarkdownTitle -Body $body
    }
    if ([string]::IsNullOrWhiteSpace($title)) {
      $title = $dir.Name
    }

    $now = [datetimeoffset]::Now
    $postDate = $now
    if ($fmMap.ContainsKey('date')) {
      $dateRaw = $fmMap['date']
      try {
        $postDate = [datetimeoffset]::Parse($dateRaw)
      } catch {
        $postDate = $now
      }
    }

    $dateForFile = $postDate.ToString("yyyy-MM-dd")
    $dateForFrontMatter = Convert-ToDisplayDate -Date $postDate

    $safeSlug = Remove-InvalidFileNameChars -Name $dir.Name
    $postFileBase = "{0}-{1}.md" -f $dateForFile, $safeSlug
    $postFilePath = Join-Path $postsRoot $postFileBase
    $postFilePath = Get-ExistingOrUniquePath -DesiredPath $postFilePath

    $imgFolderName = "{0}-{1}" -f $postDate.ToString('yyyyMMdd'), $safeSlug
    $imgDestRoot = Join-Path $assetsImgRoot (Join-Path "posts" $imgFolderName)
    if (-not (Test-Path -LiteralPath $imgDestRoot)) {
      New-Item -Path $imgDestRoot -ItemType Directory -Force | Out-Null
    }

    $allFiles = Get-ChildItem -LiteralPath $dir.FullName -Recurse -File
    foreach ($file in $allFiles) {
      if ($file.Extension.ToLowerInvariant() -eq ".md") {
        continue
      }

      $relative = $file.FullName.Substring($dir.FullName.Length).TrimStart('\','/')
      $dest = Join-Path $imgDestRoot $relative
      $destParent = Split-Path -Parent $dest
      if (-not (Test-Path -LiteralPath $destParent)) {
        New-Item -Path $destParent -ItemType Directory -Force | Out-Null
      }
      Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
    }

    $imgRelative = ""
    if ($fmMap.ContainsKey('img') -and -not [string]::IsNullOrWhiteSpace($fmMap['img'])) {
      $imgRelative = $fmMap['img'].Trim("'", '"')
    }
    if ([string]::IsNullOrWhiteSpace($imgRelative)) {
      $imgRelative = Get-FirstImageRelativePath -FolderPath $dir.FullName
    }

    $frontImg = ""
    if (-not [string]::IsNullOrWhiteSpace($imgRelative)) {
      $frontImg = "posts/{0}/{1}" -f $imgFolderName, ($imgRelative -replace '\\', '/')
    }

    $publicImageBase = "assets/img/posts/{0}" -f $imgFolderName
    $body = Rewrite-LocalImageLinks -Body $body -ArticleFolder $dir.FullName -PublicImageBase $publicImageBase

    $tagsLine = "[]"
    if ($fmMap.ContainsKey('tags') -and -not [string]::IsNullOrWhiteSpace($fmMap['tags'])) {
      $tagsLine = $fmMap['tags']
    }

    $authorLine = $defaultAuthor
    if ($fmMap.ContainsKey('author') -and -not [string]::IsNullOrWhiteSpace($fmMap['author'])) {
      $authorLine = $fmMap['author']
    }

    $frontMatter = @(
      "---",
      "layout: post",
      "read_time: true",
      "show_date: true",
      "title: $title",
      "date: $dateForFrontMatter",
      "img: $frontImg",
      "tags: $tagsLine",
      "author: $authorLine",
      "---"
    ) -join "`r`n"

    $finalContent = $frontMatter + "`r`n" + $body.TrimStart("`r", "`n") + "`r`n"
    [System.IO.File]::WriteAllText($postFilePath, $finalContent, [System.Text.Encoding]::UTF8)

    Move-ToProcessed -ArticleFolder $dir.FullName -ProcessedRoot $processedRoot

    $processedCount++
    Write-Host "[OK] Published: $(Split-Path -Leaf $postFilePath)"
  } catch {
    Write-Host "[ERROR] $($dir.Name): $($_.Exception.Message)"
  }
}

Write-Host "[DONE] Finished. Published $processedCount post(s)."
