# data-migration
Salesforce Data Migration utilities.

<h2>Installation</h2>
<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

<a href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t28000000lPjr">Unmanaged package</a>


<h2>Overview</h2>

<p>Services provide an ability to upload data from CSV files to SF. Custom binders alllow to format inport data and create the relationships.</p>


* Prepare CSV file (make sure that file doesn't have non ASCII symbols)
* Split CSV file using FileSplit (each file must have less then 10k rows to avoid from SF DML limits, suggested count of rows is 5k)
```
run java Command-Line FileSplit.class app. Set total count or rows per file and file name
```
* Upload CSV parts as SF documents with FileUpload page
* Create migration service using data binders [Example MigrationContactService](../master/src/classes/MigrationContactService.cls)
* Run migration process
```java
// Clean LOG.
MigrationTask deleteLogsMigrationTask = new MigrationTask(
    'deleteLogsMigrationTask',
    'SELECT Id FROM MIGRATION_Log__c',
    CleanUpMigrationService.class
);

// Clean imported Contacts. In case when you need to reimport the Contacts.
MigrationTask deleteContactsMigrationTask = new MigrationTask(
    'deleteContactsMigrationTask',
    'SELECT Id FROM Contact WHERE Migration_Status__c = \'Imported\'',
    CleanUpMigrationService.class
);

// Upload contacts from the Documents.
MigrationTask contactsMigrationTask = new MigrationTask(
    'contactsMigrationTask',
    MigrationUtility.getSoqlQueryForDocumentName('%contacts%'), // select * from Document where Name LIKE %contacts%
    MigrationContactsService.class
);


deleteLogsMigrationTask
    .setBatchSize(2000)
    .setNextMigrationTask(deleteContactsMigrationTask, 1000)    
    .setNextMigrationTask(contactsMigrationTask, 1);

deleteLogsMigrationTask.run();
```
* Open MigrationLog page to see the log.
