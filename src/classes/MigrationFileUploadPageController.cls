global with sharing class MigrationFileUploadPageController {
    
    @RemoteAction
    global static String attachBlob(String documentId, String fileName, String contentType, String base64BlobValue){
        /*
        documentId: The record of the current document file being processed
        fileName: Name of the document
        contentTye: Content Type of the file being attached
        base64BlobValue: Base64 encoded string of the file piece currently processing
        */
        
        String splitString = Pattern.quote('.');
        String[] fileNameArray = fileName.split(splitString, 2);
               
        //If recordId is blank this is the first part of a multi piece upload
        if(documentId == '' || documentId == null){
            Document doc = new Document(
                Body = EncodingUtil.Base64Decode(base64BlobValue),
                Name = String.isNotBlank(fileNameArray[0]) ? fileNameArray[0] : Date.today().format(),
                Type = fileNameArray.size() > 1 ? fileNameArray[1] : '',
                FolderId = UserInfo.getUserId(),
                ContentType = contentType
            );
            insert doc;
            
            //Return the new document Id
            return doc.Id;
            
        }else{
            for(Document doc : [SELECT Id, Body FROM Document WHERE Id = :documentId]){
                //Take the body of the current document, convert to base64 string, append base64 value sent from page, then convert back to binary for the body
                update new Document(Id = documentId, Body = EncodingUtil.Base64Decode(EncodingUtil.Base64Encode(doc.Body) + base64BlobValue));
            }
            
            //Return the Id of the document we are currently processing
            return documentId;
        }
    }
}