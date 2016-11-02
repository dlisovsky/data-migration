// Example migration service.
public class MigrationContactService extends MigrationCSVService {
        
    private List<Contact> contactsToInsert = new List<Contact>();    
    private List<Event> eventsToInsert = new List<Event>();       
    
    private MigrationBinders.BinderQueue contactBinderQueue;    
	private MigrationBinders.BinderQueue eventBinderQueue;    
    
	private List<MigrationBinders.Relation> relations = new List<MigrationBinders.Relation>();  
	
	public MigrationContactService(){               
        this.contactBinderQueue = getContactBinderQueue();
        this.eventBinderQueue = getEventBinderQueue();
    }
	
    private MigrationBinders.BinderQueue getContactBinderQueue(){
        
        List<MigrationBinders.IBinder> binders = new List<MigrationBinders.IBinder>();
        
		
        binders.add(new MigrationBinders.StringValueBinder(
            new Map<String, String>{
                'First Name' => 'FirstName',
                'Last Name' => 'LastName',                
                'Country' => 'MailingCountry',
                'Department' => 'Department',
                'Description' => 'Description',
                'Gender' => 'Gender__c',
                'Mailing Country' => 'OtherCountry',
                'Mailing Postcode' => 'OtherPostalCode',
                'Mailing State' => 'OtherState',
                'Mailing Suburb' => 'OtherCity',
                'Job Title' => 'Title',
                'Title' => 'Salutation',
                'Personal Assistant' => 'AssistantName',
                'Postal Code' => 'MailingPostalCode',
                'State' => 'MailingState',
                'Suburb' => 'MailingCity',                                
                'Fax' => 'Fax'                
            }
        ));
        
        // Mobile phones.
        binders.add(new MigrationBinders.PhoneNumberBinder(
            new Map<String, String>{
                'Mobile Business' => 'MobilePhone'                
            },
            new MigrationBinders.MobilePhoneNumberFormatter()
        ));
        
        // Home and other phones.
        binders.add(new MigrationBinders.PhoneNumberBinder(
            new Map<String, String>{
                'Business Phone' => 'Phone',
                'Assistant Phone' => 'AssistantPhone',
                'Home Phone' => 'HomePhone'
            },
            new MigrationBinders.CustomHomePhoneNumberFormatter()
        ));
        
        
        binders.add(new MigrationBinders.BooleanValueBinder(
            new Map<String, String>{                
                'Health Alerts' => 'Health_Alerts__c'
            },
            new Set<String>{ // True values
                'Yes',
                'yes'
            }
        ));
        
        binders.add(new MigrationBinders.BooleanValueBinder(
            new Map<String, String>{
                'Do not allow Bulk E-mails' => 'Bulk_Emails__c'
            },
            new Set<String>{ // True values.
                'Allow',
                'allow'
            }
        ));
        
        
        binders.add(new MigrationBinders.CustomMappingStringBinder(
            new Map<String, String>{
                'Mailing Address Preferred' => 'Preferred_Mailing_Address__c'
            },
            new Map<String, String>{
                'Organisation Mailing Address' => 'Organisation',
                'Contact Mailing Address' => 'Contact'
            }
        ));
        
        binders.add(new MigrationBinders.CustomMappingStringBinder(
            new Map<String, String>{
                'Preferred Method of Contact' => 'Preferred_Method_of_Contact__c'
            },
            new Map<String, String>{
                'E-mail' => 'Email'
            }
        ));
        
        
        binders.add(new MigrationBinders.JoinStringBinder(
            new Map<String, Set<String>>{
                'OtherStreet' => new Set<String>{
                    'Mailing Street 1',
                    'Mailing Street 2'
                },
                'MailingStreet' => new Set<String>{
                    'Street 1',
                    'Street 2'
                }
            },
            '\r\n', // separator.
            new Set<String>{ // exclude empty values.
                '',
                null
            }
        ));
        
        
        binders.add(new MigrationBinders.EmailBinder(
            new Map<String, String>{
                'Email Business' => 'Email'
            }
        ));
        
        
        // Parse date format 1/17/2015 or 1.17.2015
        binders.add(new MigrationBinders.DateBinder(
            new Map<String, String>{
                'DOB' => 'Birthdate'
            }
        ));
        
        
        binders.add(new MigrationBinders.LookupBinder(
            'Primary Organisation',
            Account.sObjectType,
            Account.Name.getDescribe().getName(),
            Contact.AccountId.getDescribe().getName()
        ));        
        
        binders.add(new MigrationBinders.LookupBinder(
            'Owner',
            User.sObjectType,
            User.Name.getDescribe().getName(),
            Contact.OwnerId.getDescribe().getName(),
            new MigrationBinders.OverrideValueBinderOptionProvider(true) // allows override the default value which set ups in the DefaultStringValueBinder below.
        ));
        
		
		binders.add(new MigrationBinders.MutipicklistBinder(
            'Interests__c',
            new Set<String>{
                'ADHD',
                'Adjustment Disorders',
                'Adjustment to Chronic Disease/Health Issues',
                'Adolescents/Youth',
                'Adults'                
            },
            new Set<String>{
                'Yes',
                'yes'
            }
        ));
		
        
        // Default values if field is empty.
        binders.add(new MigrationBinders.DefaultStringValueBinder(
            new Map<String, String>{
                'LastName' => '?',
                'MailingCountry' => 'Australia',
                'OtherCountry' => 'Australia',
                'Migration_Status__c' => 'Inserted'
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
    
    private MigrationBinders.BinderQueue getEventBinderQueue(){
        
        List<MigrationBinders.IBinder> binders = new List<MigrationBinders.IBinder>();
        
        
        binders.add(new MigrationBinders.LookupBinder(
            'Owner',
            User.sObjectType,
            User.Name.getDescribe().getName(),
            Event.OwnerId.getDescribe().getName(),
            new MigrationBinders.OverrideValueBinderOptionProvider(true)
        ));
        
        
        // Default values if field is empty.
        binders.add(new MigrationBinders.DefaultStringValueBinder(
            new Map<String, String>{
                'OwnerId' => UserInfo.getUserId(),                
                'Subject' => 'Health Pathways'
            }
        ));
        
        
        binders.add(new MigrationBinders.DefaultValueBinder(
            new Map<String, Object>{
                'DurationInMinutes' => 1
            }
        ));
        
        // Default values if field is empty.
        binders.add(new MigrationBinders.DefaultStringValueBinder(
            new Map<String, String>{
                'Migration_Status__c' => 'Inserted'                
            }
        ));
        
        return new MigrationBinders.BinderQueue(binders);
    } 
    
       
    
    public override void processCSVRow(Map<String, String> rowData){
        
        rowData.put('LOG_INFO', getDocumentLogInfo());
        
        Contact newContact = new Contact();
        this.contactBinderQueue.process(
            newContact, 
            rowData
        );
        this.contactsToInsert.add(newContact);

        
        List<sObject> eventsForAccount = new List<sObject>();
        
        
		Event newEvent = new Event();
		this.eventBinderQueue.process(
			newEvent, 
			rowData
		);
		this.eventsToInsert.add(newEvent);  
		eventsForAccount.add(newEvent);
        relations.add(new MigrationBinders.Relation(
			newContact,
			'Id',
			'WhoId',
			eventsForAccount
		));
		
               
    }
    
    public override void afterProcess(List<Object> objectsVar){
        
        this.contactBinderQueue.bindLookups();
        
        this.insertRecords(this.contactsToInsert, 'Contacts');
        
        
        // Binds Contact Lookup for Contact_Profile__c, Contact_Membership__c and Events records.
        MigrationBinders.initializeRelations(this.relations);
        
        
        this.insertRecords(this.eventsToInsert, 'Events');
        
        super.afterProcess(objectsVar);
    }

}