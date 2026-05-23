param(
    [Parameter(Mandatory=$true)]
    [string]$Title,
    [Parameter(Mandatory=$false)]
    [string]$Tags = "",
    [Parameter(Mandatory=$false)]
    [string]$Author = "farmer3-c",
    [Parameter(Mandatory=$false)]
    [string]$HeaderImg = "img/post-bg.jpg",
    [Parameter(Mandatory=$false)]
    [switch]$Mathjax
)

$date = Get-Date -Format "yyyy-MM-dd"
$time = Get-Date -Format "HH:mm:ss"
$slug = $Title.ToLower().Replace(" ", "-") -replace '[^a-z0-9\u4e00-\u9fa5-]', ''
$filename = "_posts\$date-$slug.md"

$tagArray = ""
if ($Tags) {
    $tagList = $Tags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if ($tagList.Count -gt 0) {
        $tagArray = "[" + ($tagList -join ", ") + "]"
    }
}

$mathjaxLine = ""
if ($Mathjax) {
    $mathjaxLine = "mathjax: true`n"
}

$content = @"
---
layout: post
title: "$Title"
date: $date $time
author: "$Author"
header-img: "$HeaderImg"
$($mathjaxLine)tags: $tagArray
---

"@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($filename, $content, $utf8NoBom)
Write-Host "========================================" -ForegroundColor Green
Write-Host "Created new post: $filename" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
