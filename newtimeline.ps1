param(
    [Parameter(Mandatory=$true, HelpMessage="中文描述")]
    [string]$Zh,
    [Parameter(Mandatory=$true, HelpMessage="English description")]
    [string]$En,
    [Parameter(Mandatory=$false, HelpMessage="日期 (yyyy-MM-dd)，默认今天")]
    [string]$Date = (Get-Date -Format "yyyy-MM-dd")
)

$timelineFile = "_data\timeline.yml"

# 检查文件是否存在
if (-not (Test-Path $timelineFile)) {
    Write-Host "错误: 找不到 $timelineFile" -ForegroundColor Red
    exit 1
}

# 构建新条目（注意 YAML 缩进：2空格列表缩进 + 4空格字段缩进）
$newEntry = "`r`n" +
            "  - time: `"$Date`"`r`n" +
            "    zh: `"${Zh}`"`r`n" +
            "    en: `"${En}`""

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::AppendAllText($timelineFile, $newEntry, $utf8NoBom)

Write-Host "========================================" -ForegroundColor Green
Write-Host "已添加时间轴事件: $Date" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "  [zh] $Zh" -ForegroundColor Cyan
Write-Host "  [en] $En" -ForegroundColor Cyan
Write-Host "文件: $timelineFile" -ForegroundColor Gray
