global class MigrationBatch implements Database.Batchable<Object>, Database.Stateful {
    
    private MigrationTask migrationTask;
    private Iterable<Object> iterableData;
    private String soqlQuery;
    
    private MigrationBatch(MigrationTask migrationTask){
        this.migrationTask = migrationTask;
        this.iterableData = migrationTask.getIterableData();
        this.soqlQuery = migrationTask.getSoqlQuery();
    }
    
    public static void run(MigrationTask migrationTask){
        Database.executeBatch(new MigrationBatch(migrationTask), migrationTask.getBatchSize());
    }

    global Iterable<Object> start(Database.BatchableContext bc) {
        
        MigrationLog.warn(
            String.format(
                'Migration batch runned. Task name: [{0}]. Batch size: [{1}]',
                new List<String>{
                    this.migrationTask.getTaskName(),
                    String.valueOf(migrationTask.getBatchSize())
                }
            ),
            migrationTask.getTaskName()
        );
        
        MigrationLog.commitAndFlush();
        
        try{
            
            if (String.isNotBlank(this.soqlQuery)){
                return (Iterable<Object>)Database.query(this.soqlQuery);
            } else if (this.iterableData != null){
                return this.iterableData;
            } 
            
            throw new MigrationBatchException('Iterable data has not initialized!');
            
        }catch(Exception ex){
            MigrationLog.error(ex, this.migrationTask.getTaskName());
            MigrationLog.commitAndFlush();
            throw ex;    
        }
        
    }

    global void execute(Database.BatchableContext bc, List<Object> scope){
        
        MigrationAbstractService migrationService = (MigrationAbstractService)this.migrationTask.getMigrationServiceType().newInstance();
        
        try{
         
            migrationService.beforeProcess(scope);
        
            for (Object scopeValue : scope) {
                migrationService.process(scopeValue);
            }
            
            migrationService.afterProcess(scope);
            
        }catch(Exception ex){
            MigrationLog.error(ex, migrationService.getServiceTypeName());
        }
        
        MigrationLog.commitAndFlush();
        
    }    

    global void finish(Database.BatchableContext bc){
        
        AsyncApexJob job = 
        [SELECT Id, 
            Status, 
            NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, 
            CreatedBy.Email
        FROM AsyncApexJob
        WHERE Id = :bc.getJobId()];
        
        try{
            
            MigrationLog.warn(
                'Job status: ' + job.Status + '. Number of errors: ' + job.NumberOfErrors + '. Job items processed: ' + job.JobItemsProcessed + '. Total job items: ' + job.TotalJobItems, 
                this.migrationTask.getTaskName()
            );
            
            MigrationLog.commitAndFlush();
            
            if (this.migrationTask.getNextMigrationTask() != null){
                this.migrationTask.getNextMigrationTask().run();
            }
            
        }catch(Exception ex){
            MigrationLog.error(ex, this.migrationTask.getTaskName());
            MigrationLog.commitAndFlush();
        }
        
    }   
    
    public class MigrationBatchException extends Exception {}

}