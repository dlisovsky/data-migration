public abstract class MigrationCSVService extends MigrationAbstractService {

    private final MigrationCSVReader csvReader;
    
    private String currentDocumentName;
    private Id currentDocumentId;
    private Integer currentProcessingRow;
    
    public MigrationCSVService(){
        this(new MigrationCSVReader ());
    }
    
    public MigrationCSVService(MigrationCSVReader csvReader){
        this.csvReader = csvReader;
    }
    
    public override virtual void process(Object objectVar){
        
        Document documentVar = (Document)objectVar;
        
        if (documentVar == null){
            this.currentDocumentName = null;
            this.currentDocumentId = null;
            throw new MigrationException('Document is NULL');
        }
        
        if (documentVar.Body == null){
            throw new MigrationException('Document body is NULL. ' + documentVar);
        }
        
        this.currentDocumentName = documentVar.Name;
        this.currentDocumentId = documentVar.Id;
        
        MigrationCSVReader.CSVWrapper csvWrapper = csvReader.parseCSV(documentVar.Body.toString());
        
        processCSV(csvWrapper);    
        
    }
    
    public virtual void processCSV(MigrationCSVReader.CSVWrapper csvWrapper){
        
        Integer totalRows = csvWrapper.getTotalRows();
        for(Integer rowIndex = 0; rowIndex < totalRows; rowIndex++){
            this.currentProcessingRow = rowIndex;
            
            try{
                processCSVRow(csvWrapper.getRowData(rowIndex));    
            }catch(Exception ex){
                MigrationLog.debug(
                    String.format(
                        'Document Name: [{0}]. Document Id: [{1}]. Processing row: [{2}]',
                        new List<String>{
                            this.currentDocumentName,
                            this.currentDocumentId,
                            String.valueOf(this.currentProcessingRow)
                        }
                    ), 
                    this.getServiceTypeName()
                );
                MigrationLog.error(ex, this.getServiceTypeName());
            }
            
        }
        
    }
    
    public String getDocumentLogInfo(){
        return String.format(
            'Document: \'\'{0}\'\' Row#: {1}', 
            new List<String>{
                this.currentDocumentName == null ? 'NO DOCUMENT' : this.currentDocumentName,
                this.currentProcessingRow == null ? 'NO ROW' : String.valueOf(this.currentProcessingRow + 2) // +1 for header and +1 to shift array index.
            }
        );
    }
    
    public void logError(String info){
        MigrationLog.error(
            String.format(
                '{0} -> {1}', 
                new List<String>{
                    getDocumentLogInfo(),
                    info
                }
            ), 
            getServiceTypeName()
        );
    }
    
    public void logWarning(String info){
        MigrationLog.warn(
            String.format(
                '{0} -> {1}', 
                new List<String>{
                    getDocumentLogInfo(),
                    info
                }
            ), 
            getServiceTypeName()
        );
    }
    
    public void logInfo(String info){
        MigrationLog.info(
            String.format(
                '{0} -> {1}', 
                new List<String>{
                    getDocumentLogInfo(),
                    info
                }
            ), 
            getServiceTypeName()
        );
    }
    
    public void logDebug(String info){
        MigrationLog.debug(
            String.format(
                '{0} -> {1}', 
                new List<String>{
                    getDocumentLogInfo(),
                    info
                }
            ), 
            getServiceTypeName()
        );
    }
    
    
    public abstract void processCSVRow(Map<String, String> rowData);

}