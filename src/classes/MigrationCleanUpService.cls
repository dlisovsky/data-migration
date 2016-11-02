public class MigrationCleanUpService extends MigrationAbstractService {

    public override void afterProcess(List<Object> objectsVar){
    
        this.deleteRecords((List<sObject>)objectsVar, 'Records');
        
    }

}