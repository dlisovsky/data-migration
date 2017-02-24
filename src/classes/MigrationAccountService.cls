/**
 * Created by Vlad Khitrik on 25.02.2017.
 */

public with sharing class MigrationAccountService extends MigrationCSVService {

    private Map<String, String> existingAccountIdsByNames;
    private Map<String, String> existingUserIdsByNames;
    private Map<String, String> existingContactIdsByEmails;
    private Map<String, String> accountRecordTypeIdsByDeveloperName;

    private MigrationBinders.BinderQueue accountBinderQueue;
    private MigrationBinders.BinderQueue contactBinderQueue;

    private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<Schema.SObjectType> {
                    Account.SObjectType,
                    Contact.SObjectType
            }
    );

    public MigrationAccountService() {
        existingAccountIdsByNames = new Map<String, String>();
        existingUserIdsByNames = new Map<String, String>();
        existingContactIdsByEmails = new Map<String, String>();

        accountBinderQueue = getAccountBinderQueue();
        contactBinderQueue = getContactBinderQueue();

        accountRecordTypeIdsByDeveloperName = new Map<String, String>();
        Map<Id, String> recordTypeDeveloperNamesByIds = Helper.getRecordTypesMap(Account.SObjectType);
        for (Id recTypeId : recordTypeDeveloperNamesByIds.keySet()) {
            String developerName = recordTypeDeveloperNamesByIds.get(recTypeId);
            accountRecordTypeIdsByDeveloperName.put(developerName, recTypeId);
        }
    }

    private MigrationBinders.BinderQueue getAccountBinderQueue() {
        List<MigrationBinders.IBinder> binders = new List<MigrationBinders.IBinder>();

        binders.add(new MigrationBinders.StringValueBinder(
                new Map<String, String> {
                        'Organisation Name' => 'Name',
                        'Categories' => 'Categories__c',
                        'Sub Category' => 'Sub_Category__c',
                        'Parent Organisation' => '',
                        'Organisation Source' => 'AccountSource',
                        'Phone' => 'Phone',
                        'Fax' => 'Fax',
                        'Website' => 'Website',
                        'Billing Suburb' => 'BillingCity',
                        'Billing State' => 'BillingState',
                        'Billing Postcode' => 'BillingPostalCode',
                        'Mailing Suburb' => 'OtherCity',
                        'Mailing State' => 'OtherState',
                        'Mailing Postcode' => 'OtherPostalCode'
                }
        ));

        binders.add(new MigrationBinders.JoinStringBinder(
                new Map<String, Set<String>> {
                        'BillingStreet' => new Set<String> {
                                'Billing Street Line 1',
                                'Billing Street Line 2'
                        },
                        'OtherStreet' => new Set<String> {
                                'Mailing Street Line 1',
                                'Mailing Street Line 2'
                        }
                },
                '\r\n', // separator.
                new Set<String> { // exclude empty values.
                        '',
                        null
                }
        ));

        binders.add(new MigrationBinders.CustomMappingStringBinder(
                new Map<String, String>{
                        'Owner' => 'OwnerId'
                },
                existingUserIdsByNames
        ));

        binders.add(new MigrationBinders.CustomMappingStringBinder(
                new Map<String, String>{
                        'Organisation Name' => 'Id'
                },
                existingAccountIdsByNames
        ));

        binders.add(new MigrationBinders.CustomMappingStringBinder(
                new Map<String, String>{
                        'Record Type' => 'RecordTypeId'
                },
                accountRecordTypeIdsByDeveloperName
        ));

        // Default values if field is empty.
        binders.add(new MigrationBinders.DefaultStringValueBinder(
                new Map<String, String>{
                        'Name' => '?',
                        'BillingCountry' => 'Australia',
                        'OtherCountry' => 'Australia',
                        'Migration_Status__c' => 'Organisation Import'
                }
        ));

        binders.add(new MigrationBinders.UpperCaseBinder(
                new Set<String>{
                        'BillingCity',
                        'OtherCity'
                }
        ));

        return new MigrationBinders.BinderQueue(binders);
    }

    private MigrationBinders.BinderQueue getContactBinderQueue() {
        List<MigrationBinders.IBinder> binders = new List<MigrationBinders.IBinder>();

        binders.add(new MigrationBinders.StringValueBinder(
                new Map<String, String> {
                        'Organisation Name' => 'LastName',
                        'Email' => 'Email',
                        'Phone' => 'Phone',
                        'Billing Suburb' => 'OtherCity',
                        'Billing State' => 'OtherState',
                        'Billing Postcode' => 'OtherPostalCode',
                        'Mailing Suburb' => 'MailingCity',
                        'Mailing State' => 'MailingState',
                        'Mailing Postcode' => 'MailingPostalCode'
                }
        ));

        binders.add(new MigrationBinders.JoinStringBinder(
                new Map<String, Set<String>> {
                        'OtherStreet' => new Set<String> {
                                'Billing Street Line 1',
                                'Billing Street Line 2'
                        },
                        'MailingStreet' => new Set<String> {
                                'Mailing Street Line 1',
                                'Mailing Street Line 2'
                        }
                },
                '\r\n', // separator.
                new Set<String> { // exclude empty values.
                        '',
                        null
                }
        ));

        binders.add(new MigrationBinders.CustomMappingStringBinder(
                new Map<String, String>{
                        'Owner' => 'OwnerId'
                },
                existingUserIdsByNames
        ));

        // Default values if field is empty.
        binders.add(new MigrationBinders.DefaultStringValueBinder(
                new Map<String, String>{
                        'LastName' => '?',
                        'MailingCountry' => 'Australia',
                        'OtherCountry' => 'Australia',
                        'Migration_Status__c' => 'Organisation Import'
                }
        ));

        binders.add(new MigrationBinders.UpperCaseBinder(
                new Set<String>{
                        'MailingCity',
                        'OtherCity'
                }
        ));

        return new MigrationBinders.BinderQueue(binders);
    }

    public override void beforeProcessCSV(MigrationCSVReader.CSVWrapper csvWrapper) {
        // Search for existing Accounts by Names
        this.existingAccountIdsByNames = new Map<String, String>();
        List<Account> existingAccounts = (List<Account>)new DynamicSelector(Account.SObjectType)
                .selectByNames(csvWrapper.getColumnUniqueValues('Organisation Name'));
        for (Account existingAccount : existingAccounts) {
            String existingAccountName = existingAccount.Name.trim().toLowerCase();
            this.existingAccountIdsByNames.put(existingAccountName, existingAccount.Id);
        }

        // Search for existing Users by Names
        this.existingUserIdsByNames = new Map<String, String>();
        List<User> existingUsers = (List<User>)new DynamicSelector(User.SObjectType)
                .selectByNames(csvWrapper.getColumnUniqueValues('Owner'));
        for (User existingUser : existingUsers) {
            String existingUserName = existingUser.Name.trim().toLowerCase();
            this.existingUserIdsByNames.put(existingUserName, existingUser.Id);
        }

        // Search for existing Contacts by Emails
        this.existingContactIdsByEmails = new Map<String, String>();
        List<Contact> existingContacts = new ContactSelector()
                .selectByEmails(csvWrapper.getColumnUniqueValues('Email'));
        for (Contact existingContact : existingContacts) {
            String existingContactEmail = existingContact.Email.trim().toLowerCase();
            this.existingContactIdsByEmails.put(existingContactEmail, existingContact.Id);
        }
    }

    public override void processCSVRow(Map<String, String> rowData){

        rowData.put('LOG_INFO', getDocumentLogInfo());

        Account newAccount = new Account(Migration_Data__c = JSON.serialize(rowData));
        accountBinderQueue.process(
                newAccount,
                rowData
        );

        if (newAccount.Id != null) {
            newAccount.Migration_Status__c = 'Updated by Organisation Import';
            uow.registerDirty(newAccount);
        } else {
            uow.registerNew(newAccount);
        }

        Contact newContact = new Contact();
        contactBinderQueue.process(
                newContact,
                rowData
        );

        if (String.isNotBlank(newContact.Email)) {
            if (newContact.Id != null) {
                newContact.Migration_Status__c = 'Updated by Organisation Import';
                uow.registerDirty(newContact);
            } else {
                uow.registerNew(newContact);
            }
            uow.registerRelationship(newContact, Contact.AccountId, newAccount);
        }
    }

    public override void afterProcess(List<Object> objectsVar) {
        uow.commitWork();

        super.afterProcess(objectsVar);
    }

}