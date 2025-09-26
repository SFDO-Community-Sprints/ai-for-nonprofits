# Knowledge Base Data

This folder contains exported Knowledge Base articles from Salesforce.

## File Structure

- `articles.json` - Complete Knowledge Base articles in JSON format
- `articles.csv` - Knowledge Base articles in CSV format for easy analysis
- `articles_summary.json` - Summary statistics of Knowledge Base articles
- `export_log.txt` - Log of export operations

## Usage

The data is exported using the Apex script `KnowledgeBaseExporter.apex` which can be found in the `scripts/apex/` directory.

## Query Used

The data is retrieved using the SOQL query in `scripts/soql/knowledge_articles.soql` which includes:
- Article metadata (ID, Title, Summary, etc.)
- Publishing information
- Creation and modification dates
- Author information
- Language and version details
