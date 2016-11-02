public class MigrationLogController {

    public static final List<String> LOG_LEVELS = new List<String>{
        MigrationLog.ERROR_LOG_LEVEL,
        MigrationLog.WARNING_LOG_LEVEL,
        MigrationLog.INFO_LOG_LEVEL,
        MigrationLog.DEBUG_LOG_LEVEL
    };
    
    public List<String> selectedLogLevels {get; set;}
    public List<SelectOption> logLevels {get {
        if (logLevels == null){
            logLevels = new List<SelectOption>();
            for(String logLevel : LOG_LEVELS){
                logLevels.add(new SelectOption(logLevel, logLevel));
            }
        }
        
        return logLevels;
    } private  set;}

    public List<MIGRATION_Log__c> logs {get; private set;}
    
    public Boolean isPDF {get; private set;}
    
    public MigrationLogController(){
        isPDF = ApexPages.currentPage().getParameters().containsKey('pdf');
        selectedLogLevels = new List<String>(LOG_LEVELS);
        logs = retrieveLogs(selectedLogLevels);
    }
    
    public void filter(){
        logs = retrieveLogs(selectedLogLevels);
    }
    
    private static List<MIGRATION_Log__c> retrieveLogs(List<String> logLevels){
        
        List<String> conditions = new List<String>();
        for(String logLevel : logLevels){
            conditions.add(String.format(
                'Log_Level__c = \'\'{0}\'\'',
                new List<String>{
                    logLevel
                }
            ));
        }
        
        String whereCause = conditions.isEmpty() ? '' : 'WHERE ' + String.join(conditions, ' OR ');
        
        String query = 'SELECT Id, Created_On__c, Log_Level__c, Details__c, Migration_Service__c FROM MIGRATION_Log__c ' + whereCause + ' ORDER BY MS__c LIMIT 3000';
        
        return Database.query(query);
    }

}