public abstract class MigrationAbstractService {

    private final static Database.DMLOptions dmlOptionsVar;
    static{
        dmlOptionsVar = new Database.DMLOptions();
        dmlOptionsVar.allowFieldTruncation = true;
        dmlOptionsVar.optAllOrNone = false;
    }
    
    protected final String currentServiceTypeName;

    public MigrationAbstractService(){
        currentServiceTypeName = String.valueOf(this).split(':')[0];
    }

    // Runs on batch start.
    public virtual void start(){
        MigrationLog.warn('START', currentServiceTypeName);
        MigrationLog.commitAndFlush();
    }
    
    // Runs on start batch execute.
    public virtual void beforeProcess(List<Object> objectsVar){}
    
    // Runs on each object in the batch scope of execute method.
    public virtual void process(Object objectVar){}
    
    // Runs on end batch execute.
    public virtual void afterProcess(List<Object> objectsVar){}
    
    // Runs batch finish.
    public virtual void finish(){
        MigrationLog.warn('FINISH', currentServiceTypeName);
    }
    
    public String getServiceTypeName(){
        return this.currentServiceTypeName;
    }
    
    
    
    public void insertRecords(List<sObject> records, String info){
        MigrationLog.warn(
            String.format(
                'Total count of {0} to insert: [{1}]', 
                new List<String>{
                    info,
                    String.valueOf(records.size())
                }
            ), 
            currentServiceTypeName
        );
        
        Database.SaveResult[] saveResults = Database.insert(records, dmlOptionsVar);
        MigrationLog.logDMLErrors(saveResults, records);
    }
    
    public void updateRecords(List<sObject> records, String info){
        MigrationLog.warn(
            String.format(
                'Total count of {0} to update: [{1}]', 
                new List<String>{
                    info,
                    String.valueOf(records.size())
                }
            ), 
            currentServiceTypeName
        );
        
        Database.SaveResult[] saveResults = Database.update(records, dmlOptionsVar);
        MigrationLog.logDMLErrors(saveResults, records); 
    }
    
    public void deleteRecords(List<sObject> records, String info){
        MigrationLog.warn(
            String.format(
                'Total count of {0} to delete: [{1}]', 
                new List<String>{
                    info,
                    String.valueOf(records.size())
                }
            ), 
            currentServiceTypeName
        );
        
        Database.DeleteResult[] saveResults = Database.delete(records, false);
        MigrationLog.logDMLErrors(saveResults, records); 
    }
    
    public class MigrationException extends Exception {}
}