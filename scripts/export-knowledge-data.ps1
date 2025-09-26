# Knowledge Base Data Export Script (PowerShell)
# 
# This script processes Knowledge Base article data exported from Salesforce
# and saves it in multiple formats (JSON, CSV) to the data folder.
# 
# Usage:
# 1. Run the Apex script KnowledgeBaseExporter.apex in Salesforce
# 2. Copy the JSON output from the debug logs
# 3. Save it as articles.json in the data/knowledge_base folder
# 4. Run this script: .\scripts\export-knowledge-data.ps1

param(
    [string]$DataDir = "..\data\knowledge_base",
    [string]$ArticlesJson = "articles.json",
    [string]$ArticlesCsv = "articles.csv",
    [string]$SummaryJson = "articles_summary.json",
    [string]$LogFile = "export_log.txt"
)

# Set full paths
$FullDataDir = Join-Path $PSScriptRoot $DataDir
$FullArticlesJson = Join-Path $FullDataDir $ArticlesJson
$FullArticlesCsv = Join-Path $FullDataDir $ArticlesCsv
$FullSummaryJson = Join-Path $FullDataDir $SummaryJson
$FullLogFile = Join-Path $FullDataDir $LogFile

function Write-Log {
    param(
        [string]$Operation,
        [string]$Status,
        [string]$Details = ""
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    $logEntry = "[$timestamp] $Operation`: $Status"
    if ($Details) {
        $logEntry += " - $Details"
    }
    $logEntry += "`n"
    
    try {
        Add-Content -Path $FullLogFile -Value $logEntry
    }
    catch {
        Write-Error "Failed to write to log file: $($_.Exception.Message)"
    }
}

function ConvertTo-Csv {
    param([array]$Articles)
    
    if (-not $Articles -or $Articles.Count -eq 0) {
        return ""
    }
    
    # Get headers from the first article
    $headers = $Articles[0].PSObject.Properties.Name
    
    # Create CSV header row
    $csvHeader = $headers -join ","
    
    # Create CSV data rows
    $csvRows = @()
    foreach ($article in $Articles) {
        $row = @()
        foreach ($header in $headers) {
            $value = $article.$header
            if ($null -eq $value) {
                $row += ""
            } else {
                $stringValue = $value.ToString().Replace('"', '""')
                if ($stringValue.Contains(',') -or $stringValue.Contains('"') -or $stringValue.Contains("`n")) {
                    $row += "`"$stringValue`""
                } else {
                    $row += $stringValue
                }
            }
        }
        $csvRows += $row -join ","
    }
    
    return ($csvHeader, $csvRows) -join "`n"
}

function Get-Summary {
    param([array]$Articles)
    
    $summary = @{
        exportDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        totalArticles = $Articles.Count
        articleTypes = @{}
        languages = @{}
        publishStatuses = @{}
        visibilityStats = @{
            visibleInPkb = 0
            visibleInCsp = 0
            visibleInPrm = 0
        }
        dateRange = @{
            earliest = $null
            latest = $null
        }
    }
    
    foreach ($article in $Articles) {
        # Count article types
        $type = $article.articleType
        if ($summary.articleTypes.ContainsKey($type)) {
            $summary.articleTypes[$type]++
        } else {
            $summary.articleTypes[$type] = 1
        }
        
        # Count languages
        $lang = $article.language
        if ($summary.languages.ContainsKey($lang)) {
            $summary.languages[$lang]++
        } else {
            $summary.languages[$lang] = 1
        }
        
        # Count publish statuses
        $status = $article.publishStatus
        if ($summary.publishStatuses.ContainsKey($status)) {
            $summary.publishStatuses[$status]++
        } else {
            $summary.publishStatuses[$status] = 1
        }
        
        # Count visibility
        if ($article.isVisibleInPkb) { $summary.visibilityStats.visibleInPkb++ }
        if ($article.isVisibleInCsp) { $summary.visibilityStats.visibleInCsp++ }
        if ($article.isVisibleInPrm) { $summary.visibilityStats.visibleInPrm++ }
        
        # Track date range
        if ($article.createdDate) {
            $createdDate = [DateTime]$article.createdDate
            if (-not $summary.dateRange.earliest -or $createdDate -lt [DateTime]$summary.dateRange.earliest) {
                $summary.dateRange.earliest = $article.createdDate
            }
            if (-not $summary.dateRange.latest -or $createdDate -gt [DateTime]$summary.dateRange.latest) {
                $summary.dateRange.latest = $article.createdDate
            }
        }
    }
    
    return $summary
}

# Main export function
function Export-KnowledgeData {
    Write-Host "Starting Knowledge Base data export..." -ForegroundColor Green
    
    try {
        # Check if articles.json exists
        if (-not (Test-Path $FullArticlesJson)) {
            Write-Error "Error: articles.json not found in data/knowledge_base folder"
            Write-Host "Please run the Apex script KnowledgeBaseExporter.apex first and save the output as articles.json" -ForegroundColor Yellow
            exit 1
        }
        
        # Read the articles data
        Write-Host "Reading articles data..." -ForegroundColor Cyan
        $articlesData = Get-Content -Path $FullArticlesJson -Raw
        $articles = $articlesData | ConvertFrom-Json
        
        Write-Log "READ_ARTICLES" "SUCCESS" "$($articles.Count) articles loaded"
        
        # Generate CSV
        Write-Host "Generating CSV format..." -ForegroundColor Cyan
        $csvData = ConvertTo-Csv -Articles $articles
        $csvData | Out-File -FilePath $FullArticlesCsv -Encoding UTF8
        Write-Host "CSV saved to: $FullArticlesCsv" -ForegroundColor Green
        
        Write-Log "GENERATE_CSV" "SUCCESS" "$($articles.Count) articles converted"
        
        # Generate summary
        Write-Host "Generating summary statistics..." -ForegroundColor Cyan
        $summary = Get-Summary -Articles $articles
        $summary | ConvertTo-Json -Depth 10 | Out-File -FilePath $FullSummaryJson -Encoding UTF8
        Write-Host "Summary saved to: $FullSummaryJson" -ForegroundColor Green
        
        Write-Log "GENERATE_SUMMARY" "SUCCESS" "$($summary.totalArticles) articles analyzed"
        
        # Display summary
        Write-Host "`n=== EXPORT SUMMARY ===" -ForegroundColor Yellow
        Write-Host "Total Articles: $($summary.totalArticles)" -ForegroundColor White
        Write-Host "Article Types: $($summary.articleTypes.Count)" -ForegroundColor White
        Write-Host "Languages: $($summary.languages.Count)" -ForegroundColor White
        Write-Host "Date Range: $($summary.dateRange.earliest) to $($summary.dateRange.latest)" -ForegroundColor White
        Write-Host "=====================`n" -ForegroundColor Yellow
        
        Write-Host "Knowledge Base data export completed successfully!" -ForegroundColor Green
        Write-Log "EXPORT_COMPLETE" "SUCCESS" "All formats generated"
        
    }
    catch {
        Write-Error "Error during export: $($_.Exception.Message)"
        Write-Log "EXPORT_ERROR" "FAILED" $_.Exception.Message
        exit 1
    }
}

# Run the export
Export-KnowledgeData
