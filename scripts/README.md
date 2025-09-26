# Knowledge Base Export Scripts

This directory contains scripts to query and export Knowledge Base articles from Salesforce.

## Files

- `soql/knowledge_articles.soql` - SOQL query to retrieve Knowledge Base articles
- `apex/KnowledgeBaseExporter.apex` - Apex script to execute the query and export data
- `export-knowledge-data.js` - Node.js script to process and format exported data
- `export-knowledge-data.ps1` - PowerShell script to process and format exported data

## Usage Instructions

### Step 1: Execute the SOQL Query

You can run the SOQL query directly in VS Code:

1. Open `soql/knowledge_articles.soql`
2. Select the query text (lines 6-25)
3. Run the command: `SFDX: Execute SOQL Query with Currently Selected Text`

### Step 2: Export Data Using Apex

1. Open `apex/KnowledgeBaseExporter.apex` in Salesforce Developer Console or VS Code
2. Execute the script
3. Copy the JSON output from the debug logs
4. Save the JSON output as `data/knowledge_base/articles.json`

### Step 3: Process and Format Data

Choose one of the following methods:

#### Option A: Using Node.js (Recommended)
```bash
node scripts/export-knowledge-data.js
```

#### Option B: Using PowerShell (Windows)
```powershell
.\scripts\export-knowledge-data.ps1
```

## Output Files

After running the export scripts, you'll find these files in `data/knowledge_base/`:

- `articles.json` - Raw Knowledge Base articles data
- `articles.csv` - Articles in CSV format for analysis
- `articles_summary.json` - Summary statistics
- `export_log.txt` - Log of export operations
- `README.md` - Documentation

## Query Details

The SOQL query retrieves the following fields from Knowledge Base articles:

- Basic Information: ID, Title, Summary, URL Name
- Metadata: Article Type, Language, Publish Status
- Visibility: PKB, CSP, PRM visibility flags
- Audit: Created/Modified dates and users
- Version: Version number, latest version flag, master language

## Troubleshooting

### Common Issues

1. **No articles found**: Check if Knowledge Base is enabled in your org
2. **Permission errors**: Ensure you have access to Knowledge Base objects
3. **JSON parsing errors**: Verify the copied JSON is valid

### Getting Help

- Check the export log file for detailed error messages
- Verify your Salesforce org has Knowledge Base enabled
- Ensure you have the necessary permissions to query Knowledge Base objects

## Customization

You can modify the SOQL query in `soql/knowledge_articles.soql` to:

- Add additional fields
- Change filtering criteria
- Modify sorting order
- Include related objects

The Apex script and processing scripts will automatically handle the new fields.
