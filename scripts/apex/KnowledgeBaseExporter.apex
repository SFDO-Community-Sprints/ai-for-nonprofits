// Knowledge Base Exporter
// This script queries Knowledge Base articles and exports them to JSON format
// Execute this in Salesforce Developer Console or VS Code

public class KnowledgeBaseExporter {
    
    public static void exportKnowledgeBaseArticles() {
        try {
            // Query Knowledge Base articles
            List<KnowledgeArticleVersion> articles = [
                SELECT 
                    Id,
                    Title,
                    Summary,
                    UrlName,
                    ArticleType,
                    Language,
                    PublishStatus,
                    IsVisibleInPkb,
                    IsVisibleInCsp,
                    IsVisibleInPrm,
                    CreatedDate,
                    CreatedBy.Name,
                    LastModifiedDate,
                    LastModifiedBy.Name,
                    KnowledgeArticleId,
                    VersionNumber,
                    IsLatestVersion,
                    IsMasterLanguage,
                    MasterLanguage,
                    ArticleNumber
                FROM KnowledgeArticleVersion 
                WHERE PublishStatus = 'Online'
                ORDER BY CreatedDate DESC
            ];
            
            // Create wrapper objects for JSON serialization
            List<ArticleWrapper> articleWrappers = new List<ArticleWrapper>();
            
            for (KnowledgeArticleVersion article : articles) {
                ArticleWrapper wrapper = new ArticleWrapper();
                wrapper.id = article.Id;
                wrapper.title = article.Title;
                wrapper.summary = article.Summary;
                wrapper.urlName = article.UrlName;
                wrapper.articleType = article.ArticleType;
                wrapper.language = article.Language;
                wrapper.publishStatus = article.PublishStatus;
                wrapper.isVisibleInPkb = article.IsVisibleInPkb;
                wrapper.isVisibleInCsp = article.IsVisibleInCsp;
                wrapper.isVisibleInPrm = article.IsVisibleInPrm;
                wrapper.createdDate = article.CreatedDate;
                wrapper.createdBy = article.CreatedBy?.Name;
                wrapper.lastModifiedDate = article.LastModifiedDate;
                wrapper.lastModifiedBy = article.LastModifiedBy?.Name;
                wrapper.knowledgeArticleId = article.KnowledgeArticleId;
                wrapper.versionNumber = article.VersionNumber;
                wrapper.isLatestVersion = article.IsLatestVersion;
                wrapper.isMasterLanguage = article.IsMasterLanguage;
                wrapper.masterLanguage = article.MasterLanguage;
                wrapper.articleNumber = article.ArticleNumber;
                
                articleWrappers.add(wrapper);
            }
            
            // Serialize to JSON
            String jsonOutput = JSON.serializePretty(articleWrappers);
            
            // Print the JSON (you can copy this to a file)
            System.debug('=== KNOWLEDGE BASE ARTICLES JSON ===');
            System.debug(jsonOutput);
            System.debug('=== END JSON ===');
            
            // Print summary statistics
            System.debug('=== EXPORT SUMMARY ===');
            System.debug('Total Articles Found: ' + articles.size());
            System.debug('Export Date: ' + System.now());
            System.debug('=== END SUMMARY ===');
            
        } catch (Exception e) {
            System.debug('Error exporting Knowledge Base articles: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
    
    // Wrapper class for JSON serialization
    public class ArticleWrapper {
        public String id;
        public String title;
        public String summary;
        public String urlName;
        public String articleType;
        public String language;
        public String publishStatus;
        public Boolean isVisibleInPkb;
        public Boolean isVisibleInCsp;
        public Boolean isVisibleInPrm;
        public DateTime createdDate;
        public String createdBy;
        public DateTime lastModifiedDate;
        public String lastModifiedBy;
        public String knowledgeArticleId;
        public Integer versionNumber;
        public Boolean isLatestVersion;
        public Boolean isMasterLanguage;
        public String masterLanguage;
        public String articleNumber;
    }
}

// Execute the export
KnowledgeBaseExporter.exportKnowledgeBaseArticles();
