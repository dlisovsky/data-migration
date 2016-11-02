public class MigrationLog {

    public static final String ERROR_LOG_LEVEL = 'Error';
    public static final String WARNING_LOG_LEVEL = 'Warning';
    public static final String INFO_LOG_LEVEL = 'Info';
    public static final String DEBUG_LOG_LEVEL = 'Debug';
    
    private static List<MIGRATION_Log__c> logs = new List<MIGRATION_Log__c>();
    
    private static void pushLog(String logLevel, String details, String migrationService){
        logs.add(new MIGRATION_Log__c(
            Log_Level__c = logLevel,
            Details__c = details == null ? null : details.left(49000), // trunc.
            Migration_Service__c = migrationService,
            Created_On__c = DateTime.now(),
            MS__c = DateTime.now().getTime()
        ));
    }
    
    public static void error(Exception ex, String migrationService){
        pushLog(
            ERROR_LOG_LEVEL, 
            String.format(
                '{0}\r\n\r\n{1}', 
                new List<String>{
                    ex.getMessage(),
                    ex.GetStackTraceString()
                }
            ),
            migrationService
        );
    }
    
    public static void error(Exception ex){
        pushLog(
            ERROR_LOG_LEVEL, 
            String.format(
                '{0} {1}', 
                new List<String>{
                    ex.getMessage(),
                    ex.GetStackTraceString()
                }
            ),
            null
        );
    }
    
    public static void error(String details, String migrationService){
        pushLog(ERROR_LOG_LEVEL, details, migrationService);
    }
    
    public static void error(String details){
        pushLog(ERROR_LOG_LEVEL, details, null);
    }
    
    public static void warn(String details, String migrationService){
        pushLog(WARNING_LOG_LEVEL, details, migrationService);
    }
    
    public static void warn(String details){
        pushLog(WARNING_LOG_LEVEL, details, null);
    }
    
    public static void info(String details, String migrationService){
        pushLog(INFO_LOG_LEVEL, details, migrationService);
    }
    
    public static void info(String details){
        pushLog(INFO_LOG_LEVEL, details, null);
    }
    
    public static void debug(String details, String migrationService){
        pushLog(DEBUG_LOG_LEVEL, details, migrationService);
    }
    
    public static void debug(String details){
        pushLog(DEBUG_LOG_LEVEL, details, null);
    }
    
    public static void logDMLErrors(Database.SaveResult[] saveResults, List<sObject> sObjects){
        
        Integer i = 0;
        Integer numberOfSuccessful = 0;
        Integer numberOfFails = 0;
        
        for (Database.SaveResult saveResultVar : saveResults) {
            if (!saveResultVar.isSuccess()) {
                for(Database.Error err : saveResultVar.getErrors()) {
                    MigrationLog.error(
                        String.format(
                            'Database error: [{0}]. Fields that affected this error: [{1}]; Related to record: [{2}]', 
                            new List<String>{
                                err.getMessage(),
                                String.join(err.getFields(), ', '),
                                JSON.serializePretty(sObjects.get(i))
                            }
                        )
                    );
                }
                numberOfFails++;
            } else {
                numberOfSuccessful++; 
            }
            i++;
        }
        
        MigrationLog.warn(
            String.format(
                'Database RESULT. Total processed [{0}]. Total successfully processed [{1}]. Total failed [{2}]', 
                new List<String>{
                    String.valueOf(i),
                    String.valueOf(numberOfSuccessful),
                    String.valueOf(numberOfFails)
                }
            )
        );
    }
    
    
    public static void logDMLErrors(Database.DeleteResult[] saveResults, List<sObject> sObjects){
        
        Integer i = 0;
        Integer numberOfSuccessful = 0;
        Integer numberOfFails = 0;
        
        for (Database.DeleteResult saveResultVar : saveResults) {
            if (!saveResultVar.isSuccess()) {
                for(Database.Error err : saveResultVar.getErrors()) {
                    MigrationLog.error(
                        String.format(
                            'Database error: [{0}]. Fields that affected this error: [{1}]; Related to record: [{2}]', 
                            new List<String>{
                                err.getMessage(),
                                String.join(err.getFields(), ', '),
                                JSON.serializePretty(sObjects.get(i))
                            }
                        )
                    );
                }
                numberOfFails++;
            } else {
                numberOfSuccessful++; 
            }
            i++;
        }
        
        MigrationLog.warn(
            String.format(
                'Database RESULT. Total processed [{0}]. Total successfully processed [{1}]. Total failed [{2}]', 
                new List<String>{
                    String.valueOf(i),
                    String.valueOf(numberOfSuccessful),
                    String.valueOf(numberOfFails)
                }
            )
        );
    }
    
    
    
    public static void commitAndFlush(){
        //Database.DMLOptions dmlOptionsVar = new Database.DMLOptions();
        //dmlOptionsVar.allowFieldTruncation = true;
        //Database.upsert(logs, dmlOptionsVar);
        
        List<sObject> logsCopy = logs.clone();
        logs.clear();
        System.debug('logs: ' + logsCopy);
        upsert logsCopy;
    }

}