public class MigrationUtility {
    
    public static final String SOQL_TEMPLATE = 'SELECT Id, Name, Body FROM Document WHERE Name LIKE \'\'{0}\'\' ORDER BY Name';
    
    public static Id getRecordTypeId(Schema.SObjectType SobjectType, String developerName){
        List<RecordType> recordTypes = [
            SELECT
                Id
            FROM
                RecordType
            WHERE
                DeveloperName = :developerName 
                AND
                IsActive = true
                AND
                SobjectType = :SobjectType.getDescribe().getName()
        ];
        
        return recordTypes.isEmpty() ? null : recordTypes[0].Id;
    }
    
    public static List<RecordType> getSobjectRecordTypes(Schema.SobjectType sobjectType){
        return [SELECT Id, Name FROM RecordType WHERE SobjectType = :sobjectType.getDescribe().getName() AND IsActive = true];
    }
    
    public static Map<String, Id> recordTypesToMapByName(List<RecordType> recordTypes){
        Map<String, Id> recordTypeMapping = new Map<String, Id>();
        for(RecordType recordTypeVar : recordTypes){
            recordTypeMapping.put(recordTypeVar.Name, recordTypeVar.Id);
        }
        return recordTypeMapping;
    }
    
    
    public static String getSoqlQueryForDocumentName(String documentName){
        return String.format(
            SOQL_TEMPLATE, 
            new List<String>{
                String.escapeSingleQuotes(documentName)
            }
        );
    }
    
    public static Set<String> getPicklistValues(Schema.sObjectField sobjectField){
        Set<String> values = new Set<String>();
        List<Schema.PicklistEntry> pickListEntries = sobjectField.getDescribe().getPicklistValues();
        for(Schema.PicklistEntry pickListEntry : pickListEntries){
            values.add(pickListEntry.getValue());
        }       
        return values;
    }
    
}