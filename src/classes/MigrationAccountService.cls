/**
 * Created by Vlad Khitrik on 25.02.2017.
 */

public with sharing class MigrationAccountService extends MigrationCSVService {

//    private Map<String, String> existingAccountIdsByNames;
//    private Map<String, String> existingUserIdsByNames;
//    private Map<String, String> existingContactIdsByEmails;
//    private Map<String, String> accountRecordTypeIdsByDeveloperName;
//
//    private Map<String, Account> accountsByNames;
//    private Map<String, String> parentNamesByAccountNames;
//    private SetParentAccountDoWork setParentAccountDoWork;
//
//    private MigrationBinders.BinderQueue accountBinderQueue;
//    private MigrationBinders.BinderQueue contactBinderQueue;
//
//    private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
//            new List<Schema.SObjectType> {
//                    Account.SObjectType,
//                    Contact.SObjectType
//            }
//    );
//
//    public MigrationAccountService() {
//        existingAccountIdsByNames = new Map<String, String>();
//        existingUserIdsByNames = new Map<String, String>();
//        existingContactIdsByEmails = new Map<String, String>();
//
//        accountRecordTypeIdsByDeveloperName = new Map<String, String>();
//        Map<Id, String> recordTypeDeveloperNamesByIds = Helper.getRecordTypesMap(Account.SObjectType);
//        for (Id recTypeId : recordTypeDeveloperNamesByIds.keySet()) {
//            String developerName = recordTypeDeveloperNamesByIds.get(recTypeId);
//            accountRecordTypeIdsByDeveloperName.put(developerName, recTypeId);
//        }
//
//        accountsByNames = new Map<String, Account>();
//        parentNamesByAccountNames = new Map<String, String>();
//        setParentAccountDoWork = new SetParentAccountDoWork();
//
//        accountBinderQueue = getAccountBinderQueue();
//        contactBinderQueue = getContactBinderQueue();
//    }
//
//    private MigrationBinders.BinderQueue getAccountBinderQueue() {
//        List<MigrationBinders.IBinder> binders = new List<MigrationBinders.IBinder>();
//
//        binders.add(new MigrationBinders.StringValueBinder(
//                new Map<String, String> {
//                        'Organisation Name' => 'Name',
//                        'Categories' => 'Categories__c',
//                        'Sub Category' => 'Sub_Category__c',
//                        'Organisation Source' => 'AccountSource',
//                        'Phone' => 'Phone',
//                        'Fax' => 'Fax',
//                        'Website' => 'Website',
//                        'Billing Suburb' => 'BillingCity',
//                        'Billing State' => 'BillingState',
//                        'Billing Postcode' => 'BillingPostalCode',
//                        'Mailing Suburb' => 'ShippingCity',
//                        'Mailing State' => 'ShippingState',
//                        'Mailing Postcode' => 'ShippingPostalCode'
//                }
//        ));
//
//        binders.add(new MigrationBinders.JoinStringBinder(
//                new Map<String, Set<String>> {
//                        'BillingStreet' => new Set<String> {
//                                'Billing Street Line 1',
//                                'Billing Street Line 2'
//                        },
//                        'ShippingStreet' => new Set<String> {
//                                'Mailing Street Line 1',
//                                'Mailing Street Line 2'
//                        }
//                },
//                '\r\n', // separator.
//                new Set<String> { // exclude empty values.
//                        '',
//                        null
//                }
//        ));
//
//        binders.add(new MigrationBinders.CustomMappingIdBinder(
//                new Map<String, String>{
//                        'Owner' => 'OwnerId'
//                },
//                existingUserIdsByNames
//        ));
//
//        binders.add(new MigrationBinders.CustomMappingIdBinder(
//                new Map<String, String>{
//                        'Organisation Name' => 'Id'
//                },
//                existingAccountIdsByNames
//        ));
//
//        binders.add(new MigrationBinders.CustomMappingIdBinder(
//                new Map<String, String>{
//                        'Parent Organisation' => 'ParentId'
//                },
//                existingAccountIdsByNames
//        ));
//
//        binders.add(new MigrationBinders.CustomMappingIdBinder(
//                new Map<String, String>{
//                        'Record Type' => 'RecordTypeId'
//                },
//                accountRecordTypeIdsByDeveloperName
//        ));
//
//        // Default values if field is empty.
//        binders.add(new MigrationBinders.DefaultStringValueBinder(
//                new Map<String, String>{
//                        'Name' => '?',
//                        'BillingCountry' => 'Australia',
//                        'ShippingCountry' => 'Australia',
//                        'Migration_Status__c' => 'Organisations Import'
//                }
//        ));
//
//        binders.add(new MigrationBinders.UpperCaseBinder(
//                new Set<String>{
//                        'BillingCity',
//                        'ShippingCity'
//                }
//        ));
//
//        return new MigrationBinders.BinderQueue(binders);
//    }
//
//    private MigrationBinders.BinderQueue getContactBinderQueue() {
//        List<MigrationBinders.IBinder> binders = new List<MigrationBinders.IBinder>();
//
//        binders.add(new MigrationBinders.StringValueBinder(
//                new Map<String, String> {
//                        'Organisation Name' => 'LastName',
//                        'Email' => 'Email',
//                        'Phone' => 'Phone',
//                        'Billing Suburb' => 'OtherCity',
//                        'Billing State' => 'OtherState',
//                        'Billing Postcode' => 'OtherPostalCode',
//                        'Mailing Suburb' => 'MailingCity',
//                        'Mailing State' => 'MailingState',
//                        'Mailing Postcode' => 'MailingPostalCode'
//                }
//        ));
//
//        binders.add(new MigrationBinders.JoinStringBinder(
//                new Map<String, Set<String>> {
//                        'OtherStreet' => new Set<String> {
//                                'Billing Street Line 1',
//                                'Billing Street Line 2'
//                        },
//                        'MailingStreet' => new Set<String> {
//                                'Mailing Street Line 1',
//                                'Mailing Street Line 2'
//                        }
//                },
//                '\r\n', // separator.
//                new Set<String> { // exclude empty values.
//                        '',
//                        null
//                }
//        ));
//
//        binders.add(new MigrationBinders.CustomMappingIdBinder(
//                new Map<String, String>{
//                        'Organisation Name' => 'Id'
//                },
//                existingContactIdsByEmails
//        ));
//
//        binders.add(new MigrationBinders.CustomMappingIdBinder(
//                new Map<String, String>{
//                        'Owner' => 'OwnerId'
//                },
//                existingUserIdsByNames
//        ));
//
//        // Default values if field is empty.
//        binders.add(new MigrationBinders.DefaultStringValueBinder(
//                new Map<String, String>{
//                        'LastName' => '?',
//                        'MailingCountry' => 'Australia',
//                        'OtherCountry' => 'Australia',
//                        'Migration_Status__c' => 'Organisations Import'
//                }
//        ));
//
//        binders.add(new MigrationBinders.UpperCaseBinder(
//                new Set<String>{
//                        'MailingCity',
//                        'OtherCity'
//                }
//        ));
//
//        return new MigrationBinders.BinderQueue(binders);
//    }
//
//    public override void beforeProcessCSV(MigrationCSVReader.CSVWrapper csvWrapper) {
//        // Search for existing Accounts by Names
//        this.existingAccountIdsByNames = new Map<String, String>();
//        List<Account> existingAccounts = (List<Account>)new DynamicSelector(Account.SObjectType)
//                .selectByNames(this.existingAccountIdsByNames.keySet());
//        for (Account existingAccount : existingAccounts) {
//            this.existingAccountIdsByNames.put(existingAccount.Name, existingAccount.Id);
//        }
//
//        // Search for existing Users by Names
//        this.existingUserIdsByNames = new Map<String, String>();
//        List<User> existingUsers = new UserSelector()
//                .selectByNames(this.existingUserIdsByNames.keySet());
//        for (User existingUser : existingUsers) {
//            this.existingUserIdsByNames.put(existingUser.Name, existingUser.Id);
//        }
//
//        // Search for existing Contacts by Emails
//        this.existingContactIdsByEmails = new Map<String, String>();
//        List<Contact> existingContacts = new ContactSelector()
//                .selectByEmails(this.existingContactIdsByEmails.keySet());
//        for (Contact existingContact : existingContacts) {
//            if (String.isNotBlank(existingContact.Email)) {
//                this.existingContactIdsByEmails.put(existingContact.Email, existingContact.Id);
//            }
//        }
//    }
//
    public override void processCSVRow(Map<String, String> rowData){
//
//        rowData.put('LOG_INFO', getDocumentLogInfo());
//
//        Account newAccount = new Account(Migration_Data__c = JSON.serialize(rowData));
//        accountBinderQueue.process(
//                newAccount,
//                rowData
//        );
//
//        newAccount.BillingStreet = Helper.replaceSeparators(newAccount.BillingStreet);
//        newAccount.ShippingStreet = Helper.replaceSeparators(newAccount.ShippingStreet);
//        if (newAccount.Id != null) {
//            newAccount.Migration_Status__c = 'Updated by Organisations Import';
//            uow.registerDirty(newAccount);
//        } else {
//            uow.registerNew(newAccount);
//        }
//        // If was not populated by Binders
//        if (newAccount.ParentId == null) {
//            String parentAccountName = rowData.get('Parent Organisation');
//            if (String.isNotBlank(parentAccountName)) {
//                parentNamesByAccountNames.put(newAccount.Name.trim().toLowerCase(), parentAccountName.trim().toLowerCase());
//            }
//        }
//        accountsByNames.put(newAccount.Name.trim().toLowerCase(), newAccount);
//
//        Contact newContact = new Contact();
//        contactBinderQueue.process(
//                newContact,
//                rowData
//        );
//
//        if (String.isNotBlank(newContact.Email)) {
//            newContact.MailingStreet = Helper.replaceSeparators(newContact.MailingStreet);
//            newContact.OtherStreet = Helper.replaceSeparators(newContact.OtherStreet);
//            // To avoid "String too long" exception (max length = 80)
//            if (newContact.LastName != null && newContact.LastName.length() > 80) {
//                newContact.LastName = newContact.LastName.substring(0, 79);
//            }
//
//            if (newContact.Id != null) {
//                newContact.Migration_Status__c = 'Updated by Organisations Import';
//                uow.registerDirty(newContact);
//            } else {
//                uow.registerNew(newContact);
//            }
//            uow.registerRelationship(newContact, Contact.AccountId, newAccount);
//        }
    }
//
//    public override void afterProcess(List<Object> objectsVar) {
//        for (String accountName : parentNamesByAccountNames.keySet()) {
//            String parentName = parentNamesByAccountNames.get(accountName);
//            Account accountVar = accountsByNames.get(accountName);
//            if (accountsByNames.containsKey(parentName)) {
//                Account parentAccount = accountsByNames.get(parentName);
//                setParentAccountDoWork.addRelationship(accountVar, parentAccount);
//            }
//        }
//        uow.registerWork(setParentAccountDoWork);
//
//        uow.commitWork();
//
//        super.afterProcess(objectsVar);
//    }
//
//    private class SetParentAccountDoWork implements fflib_SObjectUnitOfWork.IDoWork {
//        private List<ParentAccountRelationship> relationships;
//
//        public SetParentAccountDoWork() {
//            relationships = new List<ParentAccountRelationship>();
//        }
//
//        public void addRelationship(Account accountVar, Account parentAccountVar) {
//            relationships.add(new ParentAccountRelationship(accountVar, parentAccountVar));
//        }
//
//        public void doWork() {
//            List<Account> accountsToUpdate = new List<Account>();
//            for (ParentAccountRelationship relationship : relationships) {
//                if(relationship.parentAccountVar != null){
//                    relationship.accountVar.ParentId = relationship.parentAccountVar.Id;
//                    accountsToUpdate.add(relationship.accountVar);
//                }
//            }
//            update accountsToUpdate;
//        }
//    }
//
//    private class ParentAccountRelationship {
//        public Account accountVar {get; private set;}
//        public Account parentAccountVar {get; private set;}
//
//        public ParentAccountRelationship(Account accountVar, Account parentAccountVar) {
//            this.accountVar = accountVar;
//            this.parentAccountVar = parentAccountVar;
//        }
//    }

}