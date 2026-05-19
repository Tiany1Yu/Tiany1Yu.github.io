param(
  [string]$RepoRoot = "",
  [string]$StagingRoot = ""
)

$ErrorActionPreference = "Stop"
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function ConvertTo-CleanPathText {
  param([string]$Value)

  if ($null -eq $Value) {
    return ""
  }

  $text = $Value.Trim()
  if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) {
    $text = $text.Substring(1)
  }

  $text = $text -replace '[\x00-\x1F]', ''
  $text = $text.Trim().Trim('"', "'").Trim()
  $text = $text.Replace('"', '')
  return $text
}

function ConvertTo-FullPath {
  param(
    [string]$Path,
    [string]$BasePath
  )

  $baseText = ConvertTo-CleanPathText -Value $BasePath
  $pathText = ConvertTo-CleanPathText -Value $Path

  if ([string]::IsNullOrWhiteSpace($pathText)) {
    return [System.IO.Path]::GetFullPath($baseText)
  }

  try {
    if ([System.IO.Path]::IsPathRooted($pathText)) {
      return [System.IO.Path]::GetFullPath($pathText)
    }

    return [System.IO.Path]::GetFullPath((Join-Path -Path $baseText -ChildPath $pathText))
  } catch {
    throw "Invalid path '$pathText'. Original value: '$Path'. $($_.Exception.Message)"
  }
}

function Get-RelativePath {
  param(
    [string]$BasePath,
    [string]$Path
  )

  $baseFull = [System.IO.Path]::GetFullPath((ConvertTo-CleanPathText -Value $BasePath)).TrimEnd('\', '/')
  $pathFull = [System.IO.Path]::GetFullPath((ConvertTo-CleanPathText -Value $Path))
  $baseUri = New-Object System.Uri (($baseFull + [System.IO.Path]::DirectorySeparatorChar))
  $pathUri = New-Object System.Uri $pathFull
  $relative = [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($pathUri).ToString())
  return ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function Test-IsWithinPath {
  param(
    [string]$BasePath,
    [string]$Path
  )

  $baseFull = [System.IO.Path]::GetFullPath((ConvertTo-CleanPathText -Value $BasePath)).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $pathFull = [System.IO.Path]::GetFullPath((ConvertTo-CleanPathText -Value $Path))
  return $pathFull.StartsWith($baseFull, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-ConfigAuthor {
  param([string]$ConfigPath)

  if (-not (Test-Path -LiteralPath $ConfigPath)) {
    return ""
  }

  foreach ($line in Get-Content -LiteralPath $ConfigPath -Encoding UTF8) {
    if ($line -match '^author:\s*(.+?)\s*$') {
      $value = $matches[1].Trim()
      $value = ($value -replace '\s+#.*$', '').Trim()
      return (ConvertFrom-FrontMatterScalar -Value $value)
    }
  }

  return ""
}

function ConvertFrom-FrontMatterScalar {
  param([string]$Value)

  if ($null -eq $Value) {
    return ""
  }

  $trimmed = $Value.Trim()
  if ($trimmed.Length -ge 2) {
    $first = $trimmed.Substring(0, 1)
    $last = $trimmed.Substring($trimmed.Length - 1, 1)
    if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
      return $trimmed.Substring(1, $trimmed.Length - 2)
    }
  }

  return $trimmed
}

function ConvertTo-YamlScalar {
  param([string]$Value)

  if ($null -eq $Value) {
    $Value = ""
  }

  $escaped = $Value.Replace('\', '\\').Replace('"', '\"')
  return '"' + $escaped + '"'
}

function ConvertTo-SafeSlug {
  param(
    [string]$Name,
    [string]$Fallback = "post"
  )

  $invalid = New-Object 'System.Collections.Generic.HashSet[char]'
  foreach ($ch in [System.IO.Path]::GetInvalidFileNameChars()) {
    [void]$invalid.Add($ch)
  }
  [void]$invalid.Add([char]'/')
  [void]$invalid.Add([char]'\')

  $buffer = New-Object System.Text.StringBuilder
  foreach ($ch in $Name.ToCharArray()) {
    if ([char]::IsControl($ch) -or $invalid.Contains($ch)) {
      [void]$buffer.Append('-')
    } else {
      [void]$buffer.Append($ch)
    }
  }

  $clean = $buffer.ToString().Trim()
  $clean = $clean -replace '\s+', '-'
  $clean = $clean -replace '-{2,}', '-'
  $clean = $clean.Trim('-', '.')

  if ([string]::IsNullOrWhiteSpace($clean)) {
    return $Fallback
  }

  return $clean
}

function Get-FrontMatter {
  param([string]$Text)

  if ($Text.Length -gt 0 -and $Text[0] -eq [char]0xFEFF) {
    $Text = $Text.Substring(1)
  }

  $result = @{
    HasFrontMatter = $false
    FrontMatterText = ""
    Body = $Text
  }

  $delimiterRegex = [regex]'(?m)^---\s*$'
  $matches = $delimiterRegex.Matches($Text)
  if ($matches.Count -lt 2 -or $matches[0].Index -ne 0) {
    return $result
  }

  $first = $matches[0]
  $second = $matches[1]
  $fmStart = $first.Index + $first.Length
  $fmLength = $second.Index - $fmStart
  if ($fmLength -lt 0) {
    return $result
  }

  $bodyStart = $second.Index + $second.Length
  $result.HasFrontMatter = $true
  $result.FrontMatterText = $Text.Substring($fmStart, $fmLength).Trim("`r", "`n")
  $result.Body = $Text.Substring($bodyStart).TrimStart("`r", "`n")
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
    $candidate = Join-Path -Path $dir -ChildPath ("{0}-{1}{2}" -f $name, $i, $ext)
    if (-not (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
    $i++
  }
}

function Get-ArticleTarget {
  param([string]$FolderName)

  $isNote = $FolderName -imatch '^note[-_\s]+'
  $slugSource = $FolderName
  if ($isNote) {
    $slugSource = $FolderName -ireplace '^note[-_\s]+', ''
  }

  if ($isNote) {
    return [pscustomobject]@{
      Kind = "note"
      CollectionFolder = "_notes"
      AssetBucket = "notes"
      SlugSource = $slugSource
    }
  }

  return [pscustomobject]@{
    Kind = "post"
    CollectionFolder = "_posts"
    AssetBucket = "posts"
    SlugSource = $slugSource
  }
}

function Test-SkippedAssetReference {
  param([string]$Reference)

  $trimmed = $Reference.Trim()
  return ($trimmed -match '^(https?:)?//' -or
          $trimmed -match '^/' -or
          $trimmed -match '^#' -or
          $trimmed -match '^data:' -or
          $trimmed -match '^\{\{')
}

function Resolve-ArticleRelativeFile {
  param(
    [string]$Reference,
    [string]$ArticleFolder
  )

  if ([string]::IsNullOrWhiteSpace($Reference) -or (Test-SkippedAssetReference -Reference $Reference)) {
    return ""
  }

  $trimmed = ConvertTo-CleanPathText -Value $Reference
  if ([string]::IsNullOrWhiteSpace($trimmed)) {
    return ""
  }

  $pathText = $trimmed -replace '/', [System.IO.Path]::DirectorySeparatorChar
  try {
    if ([System.IO.Path]::IsPathRooted($pathText)) {
      $candidate = [System.IO.Path]::GetFullPath($pathText)
    } else {
      $candidate = [System.IO.Path]::GetFullPath((Join-Path -Path $ArticleFolder -ChildPath $pathText))
    }
  } catch {
    return ""
  }

  if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
    return ""
  }

  if (-not (Test-IsWithinPath -BasePath $ArticleFolder -Path $candidate)) {
    return ""
  }

  return ((Get-RelativePath -BasePath $ArticleFolder -Path $candidate) -replace '\\', '/')
}

function ConvertTo-PublicAssetPath {
  param(
    [string]$Reference,
    [string]$ArticleFolder,
    [string]$PublicImageBase
  )

  $relative = Resolve-ArticleRelativeFile -Reference $Reference -ArticleFolder $ArticleFolder
  if ([string]::IsNullOrWhiteSpace($relative)) {
    return $Reference.Trim()
  }

  return ("/{0}/{1}" -f $PublicImageBase.Trim('/'), $relative)
}

function Rewrite-MarkdownImageTarget {
  param(
    [string]$Target,
    [string]$ArticleFolder,
    [string]$PublicImageBase
  )

  $trimmed = $Target.Trim()
  if ([string]::IsNullOrWhiteSpace($trimmed)) {
    return $Target
  }

  $wholeRelative = Resolve-ArticleRelativeFile -Reference $trimmed -ArticleFolder $ArticleFolder
  if (-not [string]::IsNullOrWhiteSpace($wholeRelative)) {
    return ("/{0}/{1}" -f $PublicImageBase.Trim('/'), $wholeRelative)
  }

  if ($trimmed -match '^<(?<path>[^>]+)>(?<tail>.*)$') {
    $path = $matches['path']
    $tail = $matches['tail']
    $newPath = ConvertTo-PublicAssetPath -Reference $path -ArticleFolder $ArticleFolder -PublicImageBase $PublicImageBase
    return "<{0}>{1}" -f $newPath, $tail
  }

  if ($trimmed -match "^(?<path>.+?)(?<tail>\s+['""][^'""]*['""]\s*)$") {
    $path = $matches['path']
    $tail = $matches['tail']
    $newPath = ConvertTo-PublicAssetPath -Reference $path -ArticleFolder $ArticleFolder -PublicImageBase $PublicImageBase
    return "{0}{1}" -f $newPath, $tail
  }

  return (ConvertTo-PublicAssetPath -Reference $trimmed -ArticleFolder $ArticleFolder -PublicImageBase $PublicImageBase)
}

function Rewrite-LocalImageLinks {
  param(
    [string]$Body,
    [string]$ArticleFolder,
    [string]$PublicImageBase
  )

  $obsidianPattern = [regex]'!\[\[(?<target>[^\]]+)\]\]'
  $body = $obsidianPattern.Replace($Body, {
    param($m)
    $target = $m.Groups['target'].Value.Trim()
    $parts = $target -split '\|', 2
    $path = $parts[0].Trim()
    $alt = if ($parts.Count -gt 1 -and -not [string]::IsNullOrWhiteSpace($parts[1])) {
      $parts[1].Trim()
    } else {
      Split-Path -Leaf $path
    }
    $newTarget = ConvertTo-PublicAssetPath -Reference $path -ArticleFolder $ArticleFolder -PublicImageBase $PublicImageBase
    return "![{0}]({1})" -f $alt, $newTarget
  })

  $markdownPattern = [regex]'!\[(?<alt>[^\]]*)\]\((?<target>[^)]*)\)'
  $body = $markdownPattern.Replace($body, {
    param($m)
    $alt = $m.Groups['alt'].Value
    $target = $m.Groups['target'].Value
    $newTarget = Rewrite-MarkdownImageTarget -Target $target -ArticleFolder $ArticleFolder -PublicImageBase $PublicImageBase
    return "![{0}]({1})" -f $alt, $newTarget
  })

  $htmlPattern = [regex]'(?<prefix><img[^>]*?src\s*=\s*["''])(?<path>[^"'']+)(?<suffix>["''][^>]*>)'
  $body = $htmlPattern.Replace($body, {
    param($m)
    $prefix = $m.Groups['prefix'].Value
    $path = $m.Groups['path'].Value
    $suffix = $m.Groups['suffix'].Value
    $newPath = ConvertTo-PublicAssetPath -Reference $path -ArticleFolder $ArticleFolder -PublicImageBase $PublicImageBase
    return "{0}{1}{2}" -f $prefix, $newPath, $suffix
  })

  return $body
}

function Get-FirstImageRelativePath {
  param([string]$FolderPath)

  $extSet = @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.avif')
  $images = Get-ChildItem -LiteralPath $FolderPath -Recurse -File |
    Where-Object { $extSet -contains $_.Extension.ToLowerInvariant() } |
    Sort-Object @{ Expression = {
        if ($_.BaseName -match '^(cover|thumbnail|thumb|poster|banner)([-_\s.]|$)' -or $_.BaseName -match '封面') {
          0
        } else {
          1
        }
      } }, FullName

  if ($images.Count -eq 0) {
    return ""
  }

  return ((Get-RelativePath -BasePath $FolderPath -Path $images[0].FullName) -replace '\\', '/')
}

function Move-ToProcessed {
  param(
    [string]$ArticleFolder,
    [string]$ProcessedRoot
  )

  if (-not (Test-Path -LiteralPath $ProcessedRoot)) {
    New-Item -Path $ProcessedRoot -ItemType Directory -Force | Out-Null
  }

  $name = Split-Path -Leaf $ArticleFolder
  $target = Join-Path -Path $ProcessedRoot -ChildPath $name
  if (Test-Path -LiteralPath $target) {
    $suffix = Get-Date -Format "yyyyMMdd-HHmmss"
    $target = Join-Path -Path $ProcessedRoot -ChildPath ("{0}-{1}" -f $name, $suffix)
  }

  Move-Item -LiteralPath $ArticleFolder -Destination $target
}

$scriptRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
  $PSScriptRoot
} else {
  Split-Path -Parent $MyInvocation.MyCommand.Path
}

$defaultRepoRoot = Split-Path -Parent $scriptRoot
$repoRootPath = ConvertTo-FullPath -Path $RepoRoot -BasePath $defaultRepoRoot
$stagingRootPath = if ([string]::IsNullOrWhiteSpace($StagingRoot)) {
  ConvertTo-FullPath -Path "to_be_posted" -BasePath $repoRootPath
} else {
  ConvertTo-FullPath -Path $StagingRoot -BasePath $repoRootPath
}

$processedRoot = Join-Path -Path $stagingRootPath -ChildPath "_processed"
$postsRoot = Join-Path -Path $repoRootPath -ChildPath "_posts"
$notesRoot = Join-Path -Path $repoRootPath -ChildPath "_notes"
$assetsImgRoot = Join-Path -Path (Join-Path -Path $repoRootPath -ChildPath "assets") -ChildPath "img"
$configPath = Join-Path -Path $repoRootPath -ChildPath "_config.yml"

if (-not (Test-Path -LiteralPath $stagingRootPath)) {
  Write-Host "[INFO] Staging folder not found: $stagingRootPath"
  exit 0
}

New-Item -Path $postsRoot -ItemType Directory -Force | Out-Null
New-Item -Path $notesRoot -ItemType Directory -Force | Out-Null

$defaultAuthor = Get-ConfigAuthor -ConfigPath $configPath

$articleDirs = Get-ChildItem -LiteralPath $stagingRootPath -Directory |
  Where-Object { $_.Name -ne "_processed" } |
  Sort-Object Name

if ($articleDirs.Count -eq 0) {
  Write-Host "[INFO] No pending article folders under $stagingRootPath."
  exit 0
}

$processedCount = 0

foreach ($dir in $articleDirs) {
  try {
    $targetInfo = Get-ArticleTarget -FolderName $dir.Name
    $contentRoot = if ($targetInfo.Kind -eq "note") { $notesRoot } else { $postsRoot }

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
      $title = ConvertFrom-FrontMatterScalar -Value $fmMap['title']
    }
    if ([string]::IsNullOrWhiteSpace($title)) {
      $title = Get-FirstMarkdownTitle -Body $body
    }
    if ([string]::IsNullOrWhiteSpace($title)) {
      $title = $targetInfo.SlugSource
    }
    if ([string]::IsNullOrWhiteSpace($title)) {
      $title = $md.BaseName
    }

    $now = [datetimeoffset]::Now
    $postDate = $now
    if ($fmMap.ContainsKey('date')) {
      $dateRaw = ConvertFrom-FrontMatterScalar -Value $fmMap['date']
      try {
        $postDate = [datetimeoffset]::Parse($dateRaw)
      } catch {
        $postDate = $now
      }
    }

    $slugSource = $targetInfo.SlugSource
    if ([string]::IsNullOrWhiteSpace($slugSource)) {
      $slugSource = $title
    }
    $safeSlug = ConvertTo-SafeSlug -Name $slugSource -Fallback $targetInfo.Kind

    $dateForFile = $postDate.ToString("yyyy-MM-dd")
    $dateForFrontMatter = Convert-ToDisplayDate -Date $postDate
    $dateForLastModified = Convert-ToDisplayDate -Date $now
    if ($targetInfo.Kind -eq "note") {
      $contentFileBase = "{0}.md" -f $safeSlug
    } else {
      $contentFileBase = "{0}-{1}.md" -f $dateForFile, $safeSlug
    }
    $contentFilePath = Join-Path -Path $contentRoot -ChildPath $contentFileBase
    $contentFilePath = Get-ExistingOrUniquePath -DesiredPath $contentFilePath

    $imgFolderName = "{0}-{1}" -f $postDate.ToString('yyyyMMdd'), $safeSlug
    $assetBucketRoot = Join-Path -Path $assetsImgRoot -ChildPath $targetInfo.AssetBucket
    $imgDestRoot = Join-Path -Path $assetBucketRoot -ChildPath $imgFolderName
    New-Item -Path $imgDestRoot -ItemType Directory -Force | Out-Null

    $allFiles = Get-ChildItem -LiteralPath $dir.FullName -Recurse -File
    foreach ($file in $allFiles) {
      if ($file.Extension.ToLowerInvariant() -eq ".md") {
        continue
      }

      $relative = Get-RelativePath -BasePath $dir.FullName -Path $file.FullName
      $dest = Join-Path -Path $imgDestRoot -ChildPath $relative
      $destParent = Split-Path -Parent $dest
      if (-not (Test-Path -LiteralPath $destParent)) {
        New-Item -Path $destParent -ItemType Directory -Force | Out-Null
      }
      Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
    }

    $imgRelative = ""
    if ($fmMap.ContainsKey('img') -and -not [string]::IsNullOrWhiteSpace($fmMap['img'])) {
      $imgReference = ConvertFrom-FrontMatterScalar -Value $fmMap['img']
      $imgRelative = Resolve-ArticleRelativeFile -Reference $imgReference -ArticleFolder $dir.FullName
      if ([string]::IsNullOrWhiteSpace($imgRelative) -and $imgReference -match '^(posts|notes|stock)/') {
        $imgRelative = "__existing__:$($imgReference -replace '\\', '/')"
      }
    }
    if ([string]::IsNullOrWhiteSpace($imgRelative)) {
      $imgRelative = Get-FirstImageRelativePath -FolderPath $dir.FullName
    }

    $frontImg = ""
    if (-not [string]::IsNullOrWhiteSpace($imgRelative)) {
      if ($imgRelative.StartsWith("__existing__:")) {
        $frontImg = $imgRelative.Substring("__existing__:".Length)
      } else {
        $frontImg = "{0}/{1}/{2}" -f $targetInfo.AssetBucket, $imgFolderName, $imgRelative
      }
    }

    $publicImageBase = "assets/img/{0}/{1}" -f $targetInfo.AssetBucket, $imgFolderName
    $body = Rewrite-LocalImageLinks -Body $body -ArticleFolder $dir.FullName -PublicImageBase $publicImageBase

    $tagsLine = "[]"
    if ($fmMap.ContainsKey('tags') -and -not [string]::IsNullOrWhiteSpace($fmMap['tags'])) {
      $tagsLine = $fmMap['tags']
    }

    $authorLine = $defaultAuthor
    if ($fmMap.ContainsKey('author') -and -not [string]::IsNullOrWhiteSpace($fmMap['author'])) {
      $authorLine = ConvertFrom-FrontMatterScalar -Value $fmMap['author']
    }

    $frontMatter = @(
      "---",
      "layout: post",
      "read_time: true",
      "show_date: true",
      "title: $(ConvertTo-YamlScalar -Value $title)",
      "date: $dateForFrontMatter",
      "last_modified_at: $dateForLastModified",
      "img: $(ConvertTo-YamlScalar -Value $frontImg)",
      "tags: $tagsLine",
      "author: $(ConvertTo-YamlScalar -Value $authorLine)",
      "---"
    ) -join "`r`n"

    $finalContent = $frontMatter + "`r`n" + $body.TrimStart("`r", "`n") + "`r`n"
    [System.IO.File]::WriteAllText($contentFilePath, $finalContent, $Utf8NoBom)

    Move-ToProcessed -ArticleFolder $dir.FullName -ProcessedRoot $processedRoot

    $processedCount++
    Write-Host "[OK] Published $($targetInfo.Kind): $(Split-Path -Leaf $contentFilePath)"
  } catch {
    Write-Host "[ERROR] $($dir.Name): $($_.Exception.Message)"
  }
}

Write-Host "[DONE] Finished. Published $processedCount item(s)."
