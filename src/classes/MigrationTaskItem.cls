public class MigrationTaskItem {

    private Set<Id> documentIds; 
    private System.Type migrationServiceType; 
    
    public MigrationTaskItem(Set<Id> documentIds, System.Type migrationServiceType){
        this.documentIds = documentIds;
        this.migrationServiceType = migrationServiceType;
    }

}