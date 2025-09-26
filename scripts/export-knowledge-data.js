#!/usr/bin/env node

/**
 * Knowledge Base Data Export Script
 * 
 * This script processes Knowledge Base article data exported from Salesforce
 * and saves it in multiple formats (JSON, CSV) to the data folder.
 * 
 * Usage:
 * 1. Run the Apex script KnowledgeBaseExporter.apex in Salesforce
 * 2. Copy the JSON output from the debug logs
 * 3. Save it as articles.json in the data/knowledge_base folder
 * 4. Run this script: node scripts/export-knowledge-data.js
 */

const fs = require('fs');
const path = require('path');

// Paths
const DATA_DIR = path.join(__dirname, '..', 'data', 'knowledge_base');
const ARTICLES_JSON = path.join(DATA_DIR, 'articles.json');
const ARTICLES_CSV = path.join(DATA_DIR, 'articles.csv');
const SUMMARY_JSON = path.join(DATA_DIR, 'articles_summary.json');
const LOG_FILE = path.join(DATA_DIR, 'export_log.txt');

/**
 * Convert JSON data to CSV format
 */
function jsonToCsv(articles) {
    if (!articles || articles.length === 0) {
        return '';
    }

    // Get headers from the first article
    const headers = Object.keys(articles[0]);
    
    // Create CSV header row
    const csvHeader = headers.join(',');
    
    // Create CSV data rows
    const csvRows = articles.map(article => {
        return headers.map(header => {
            const value = article[header];
            // Handle null/undefined values and escape commas
            if (value === null || value === undefined) {
                return '';
            }
            // Convert to string and escape quotes
            const stringValue = String(value).replace(/"/g, '""');
            // Wrap in quotes if contains comma, quote, or newline
            if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
                return `"${stringValue}"`;
            }
            return stringValue;
        }).join(',');
    });
    
    return [csvHeader, ...csvRows].join('\n');
}

/**
 * Generate summary statistics
 */
function generateSummary(articles) {
    const summary = {
        exportDate: new Date().toISOString(),
        totalArticles: articles.length,
        articleTypes: {},
        languages: {},
        publishStatuses: {},
        visibilityStats: {
            visibleInPkb: 0,
            visibleInCsp: 0,
            visibleInPrm: 0
        },
        dateRange: {
            earliest: null,
            latest: null
        }
    };

    articles.forEach(article => {
        // Count article types
        summary.articleTypes[article.articleType] = (summary.articleTypes[article.articleType] || 0) + 1;
        
        // Count languages
        summary.languages[article.language] = (summary.languages[article.language] || 0) + 1;
        
        // Count publish statuses
        summary.publishStatuses[article.publishStatus] = (summary.publishStatuses[article.publishStatus] || 0) + 1;
        
        // Count visibility
        if (article.isVisibleInPkb) summary.visibilityStats.visibleInPkb++;
        if (article.isVisibleInCsp) summary.visibilityStats.visibleInCsp++;
        if (article.isVisibleInPrm) summary.visibilityStats.visibleInPrm++;
        
        // Track date range
        if (article.createdDate) {
            const createdDate = new Date(article.createdDate);
            if (!summary.dateRange.earliest || createdDate < new Date(summary.dateRange.earliest)) {
                summary.dateRange.earliest = article.createdDate;
            }
            if (!summary.dateRange.latest || createdDate > new Date(summary.dateRange.latest)) {
                summary.dateRange.latest = article.createdDate;
            }
        }
    });

    return summary;
}

/**
 * Log export operation
 */
function logExport(operation, status, details = '') {
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] ${operation}: ${status}${details ? ' - ' + details : ''}\n`;
    
    try {
        fs.appendFileSync(LOG_FILE, logEntry);
    } catch (error) {
        console.error('Failed to write to log file:', error.message);
    }
}

/**
 * Main export function
 */
function exportKnowledgeData() {
    console.log('Starting Knowledge Base data export...');
    
    try {
        // Check if articles.json exists
        if (!fs.existsSync(ARTICLES_JSON)) {
            console.error('Error: articles.json not found in data/knowledge_base folder');
            console.log('Please run the Apex script KnowledgeBaseExporter.apex first and save the output as articles.json');
            process.exit(1);
        }

        // Read the articles data
        console.log('Reading articles data...');
        const articlesData = fs.readFileSync(ARTICLES_JSON, 'utf8');
        const articles = JSON.parse(articlesData);
        
        logExport('READ_ARTICLES', 'SUCCESS', `${articles.length} articles loaded`);

        // Generate CSV
        console.log('Generating CSV format...');
        const csvData = jsonToCsv(articles);
        fs.writeFileSync(ARTICLES_CSV, csvData);
        console.log(`CSV saved to: ${ARTICLES_CSV}`);
        logExport('GENERATE_CSV', 'SUCCESS', `${articles.length} articles converted`);

        // Generate summary
        console.log('Generating summary statistics...');
        const summary = generateSummary(articles);
        fs.writeFileSync(SUMMARY_JSON, JSON.stringify(summary, null, 2));
        console.log(`Summary saved to: ${SUMMARY_JSON}`);
        logExport('GENERATE_SUMMARY', 'SUCCESS', `${summary.totalArticles} articles analyzed`);

        // Display summary
        console.log('\n=== EXPORT SUMMARY ===');
        console.log(`Total Articles: ${summary.totalArticles}`);
        console.log(`Article Types: ${Object.keys(summary.articleTypes).length}`);
        console.log(`Languages: ${Object.keys(summary.languages).length}`);
        console.log(`Date Range: ${summary.dateRange.earliest} to ${summary.dateRange.latest}`);
        console.log('=====================\n');

        console.log('Knowledge Base data export completed successfully!');
        logExport('EXPORT_COMPLETE', 'SUCCESS', 'All formats generated');

    } catch (error) {
        console.error('Error during export:', error.message);
        logExport('EXPORT_ERROR', 'FAILED', error.message);
        process.exit(1);
    }
}

// Run the export if this script is executed directly
if (require.main === module) {
    exportKnowledgeData();
}

module.exports = { exportKnowledgeData, jsonToCsv, generateSummary };
