public class MigrationTask {

    private String taskName;
    private Iterable<Object> iterableData;
    private String soqlQuery;
    private System.Type migrationServiceType; 
    private MigrationTask nextMigrationTask;
    private Integer batchSize = 1;
    
    
    public MigrationTask(String taskName, String soqlQuery, System.Type migrationServiceType){
        this(taskName, soqlQuery, null, migrationServiceType, null);
    }
    
    public MigrationTask(String taskName, String soqlQuery, System.Type migrationServiceType, MigrationTask nextMigrationTask){
        this(taskName, soqlQuery, null, migrationServiceType, nextMigrationTask);
    }
    
    
    
    public MigrationTask(String taskName, Iterable<Object> iterableData, System.Type migrationServiceType){
        this(taskName, null, iterableData, migrationServiceType, null);
    }
    
    public MigrationTask(String taskName, Iterable<Object> iterableData, System.Type migrationServiceType, MigrationTask nextMigrationTask){
        this(taskName, null, iterableData, migrationServiceType, nextMigrationTask);
    }
    
    
    private MigrationTask(String taskName, String soqlQuery, Iterable<Object> iterableData, System.Type migrationServiceType, MigrationTask nextMigrationTask){
        this.taskName = taskName;
        this.soqlQuery = soqlQuery; 
        this.iterableData = iterableData;
        this.migrationServiceType = migrationServiceType;
        this.nextMigrationTask = nextMigrationTask;
    }
    
    
    
    
    
    public String getSoqlQuery(){
        return this.soqlQuery;    
    }
    
    public Iterable<Object> getIterableData(){
        return this.iterableData;    
    }
    
    public System.Type getMigrationServiceType(){
        return this.migrationServiceType;
    }
    
    public MigrationTask getNextMigrationTask(){
        return this.nextMigrationTask;
    }
    
    // Allows to setup miration tasks: task1.setNextMigrationTask(tast2).setNextMigrationTask(task3) and so on. Then call task1.run();
    public MigrationTask setNextMigrationTask(MigrationTask nextMigrationTask, Integer batchSize){
        this.nextMigrationTask = nextMigrationTask;
        this.nextMigrationTask.setBatchSize(batchSize);
        return this.nextMigrationTask; 
        //return this;
    }
    
    public MigrationTask setNextMigrationTask(MigrationTask nextMigrationTask){
        if (nextMigrationTask == null){
            this.nextMigrationTask = null;
            return null;
        }
        return setNextMigrationTask(nextMigrationTask, nextMigrationTask.getBatchSize());
    }
    
    public Integer getBatchSize(){
        return this.batchSize;
    }
    
    public MigrationTask setBatchSize(Integer batchSize){
        this.batchSize = batchSize;
        return this;
    }
    
    public String getTaskName(){
        return this.taskName;
    }



    public void run(){
        MigrationBatch.run(this);
    }
    
}