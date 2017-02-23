public class MigrationBinders {

    public interface IBinder{
        void bind(sObject record, Map<String, String> data);
    }
    
    public interface ILookupBinder extends IBinder{
        void bindLookups();
    }
    
    public interface IBinderOptionProvider{
        Boolean isSkeepBinding(sObject record, Map<String, String> data);
        Boolean isTrimValue(sObject record, Map<String, String> data);
        Boolean isOverrideValue(sObject record, Map<String, String> data);
    }
    
    public abstract class AbstractBinder implements IBinder{
        
        protected String LOG_INFO_KEY = 'LOG_INFO';
        
        protected String getLogInfo(Map<String, String> data){
            return data.containsKey(LOG_INFO_KEY) ? data.get(LOG_INFO_KEY) : '';
        }
        
        protected IBinderOptionProvider binderOptionProvider;
        
        public AbstractBinder(){
            this(new DefaultBinderOptionProvider());
        }
        
        public AbstractBinder(IBinderOptionProvider binderOptionProvider){
            this.binderOptionProvider = binderOptionProvider;
        }
        
    }
    
    public virtual class DefaultBinderOptionProvider implements IBinderOptionProvider{
        public virtual Boolean isSkeepBinding(sObject record, Map<String, String> data){
            return false;
        }
        
        public virtual Boolean isTrimValue(sObject record, Map<String, String> data){
            return false;
        }
        
        public virtual Boolean isOverrideValue(sObject record, Map<String, String> data){
            return false;
        }
    }
    
    // Allows to process multiple binders.
    public class BinderQueue{
        private List<IBinder> binders;
        
        public BinderQueue(List<IBinder> binders){
            this.binders = binders;
        }
        
        public BinderQueue addBinder(IBinder binder){
            this.binders.add(binder);
            return this;
        }
        
        public void process(sObject record, Map<String, String> data){
            for(IBinder initializer : this.binders){
                initializer.bind(record, data);
            }
        }
        
        public void bindLookups(){
            for(IBinder binder : this.binders){
                if (binder instanceof ILookupBinder){
                    ((ILookupBinder)binder).bindLookups();
                }
            }
        }
    }
    
    
    // Bind the file colums to sObject fields directly.
    /*
        mapping - file column name => sObject API name
    */
    public class StringValueBinder extends AbstractBinder {
        
        private Map<String, String> mapping;
        
        public StringValueBinder(Map<String, String> mapping){
            this.mapping = mapping;
        }
        
        public StringValueBinder(Map<String, String> mapping, IBinderOptionProvider binderOptionProvider){
            super(binderOptionProvider);
            this.mapping = mapping;
        }
        
        public void bind(sObject record, Map<String, String> data){
            
            if (this.binderOptionProvider.isSkeepBinding(record, data)) return;
            
            for(String columnName : mapping.keySet()){
                String fieldName = mapping.get(columnName);
                String value = data.get(columnName);
                record.put(fieldName, value);   
            }
            
        }
    }
    
    public class IfRecordEmptyStringValueBinder extends AbstractBinder {
        
        private Map<String, String> mapping;
        
        public IfRecordEmptyStringValueBinder(Map<String, String> mapping){
            this.mapping = mapping;
        }
        
        public IfRecordEmptyStringValueBinder(Map<String, String> mapping, IBinderOptionProvider binderOptionProvider){
            super(binderOptionProvider);
            this.mapping = mapping;
        }
        
        public void bind(sObject record, Map<String, String> data){
            
            if (this.binderOptionProvider.isSkeepBinding(record, data)) return;
            
            for(String columnName : mapping.keySet()){
                String fieldName = mapping.get(columnName);
                String value = data.get(columnName);
                if (String.isBlank((String)record.get(fieldName))){
                    record.put(fieldName, value);   
                }
            }
            
        }
    }
    
    public class DecimalValueBinder extends AbstractBinder {
        
        private Map<String, String> mapping;
        
        public DecimalValueBinder(Map<String, String> mapping){
            this.mapping = mapping;
        }
        
        public DecimalValueBinder(Map<String, String> mapping, IBinderOptionProvider binderOptionProvider){
            super(binderOptionProvider);
            this.mapping = mapping;
        }
        
        public void bind(sObject record, Map<String, String> data){
            
            if (this.binderOptionProvider.isSkeepBinding(record, data)) return;
            
            for(String columnName : mapping.keySet()){
                String fieldName = mapping.get(columnName);
                
                String stringValue = (String)data.get(columnName);
                
                if (String.isBlank(stringValue)){
                    continue;
                }
                
                try{
                    String columnValue = data.get(columnName).replaceAll('[^0-9.]*', '');
                    Decimal value = Decimal.valueOf(columnValue);
                    record.put(fieldName, value);   
                }catch(Exception ex){
                    MigrationLog.error(
                        String.format(
                            '{0} Unable to parse Dcimal value from string: [{1}]', 
                            new List<String>{
                                this.getLogInfo(data),
                                stringValue
                            }
                        )
                    );
                }
            }
            
        }
    }
    
    // Init defailt values if file column is empty.
    // mapping and data should be null;
    // bind(sObject record, null, null)
    public class DefaultStringValueBinder implements IBinder{
        
        private Map<String, String> defaultValues;
        
        public DefaultStringValueBinder(Map<String, String> defaultValues){
            this.defaultValues = defaultValues;
        }
        
        public void bind(sObject record, Map<String, String> data){
            
            for(String fieldName : defaultValues.keySet()){
                String currentValue = (String)record.get(fieldName);
                
                if (String.isBlank(currentValue) && defaultValues.containsKey(fieldName)){
                    String defaultValue = defaultValues.get(fieldName);
                    record.put(fieldName, defaultValue);
                }
            }
            
        }
    }
    
    
    public class DefaultValueBinder implements IBinder{
        
        private Map<String, Object> defaultValues;
        
        public DefaultValueBinder(Map<String, Object> defaultValues){
            this.defaultValues = defaultValues;
        }
        
        public void bind(sObject record, Map<String, String> data){
            
            for(String fieldName : defaultValues.keySet()){
                Object currentValue = record.get(fieldName);
                
                if (currentValue == null && defaultValues.containsKey(fieldName)){
                    Object defaultValue = defaultValues.get(fieldName);
                    record.put(fieldName, defaultValue);
                }
            }
            
        }
    }
    
    public class PhoneNumberBinder extends AbstractBinder {
        
        private Map<String, String> mapping;
        private IPhoneNumberFormatter phoneNumberFormatter;
        
        public PhoneNumberBinder(Map<String, String> mapping, IPhoneNumberFormatter phoneNumberFormatter){
            this.mapping = mapping;
            this.phoneNumberFormatter = phoneNumberFormatter;
        }
        
        public PhoneNumberBinder(Map<String, String> mapping, IPhoneNumberFormatter phoneNumberFormatter, IBinderOptionProvider binderOptionProvider){
            super(binderOptionProvider);
            this.mapping = mapping;
            this.phoneNumberFormatter = phoneNumberFormatter;
        }
        
        public void bind(sObject record, Map<String, String> data){
            for(String columnName : mapping.keySet()){
                String fieldName = mapping.get(columnName);
                String value = data.get(columnName);
                String formattedValue = this.phoneNumberFormatter.format(value);
                record.put(fieldName, formattedValue);
            }
        }
        
    }
    
    public class BooleanValueBinder extends AbstractBinder {
        
        private Map<String, String> mapping;
        private Set<String> trueValues; 
        
        public BooleanValueBinder(Map<String, String> mapping, Set<String> trueValues){
            this.mapping = mapping;
            this.trueValues = trueValues;
        }
        
        public BooleanValueBinder(Map<String, String> mapping, Set<String> trueValues, IBinderOptionProvider binderOptionProvider){
            super(binderOptionProvider);
            this.mapping = mapping;
            this.trueValues = trueValues;
        }
        
        public void bind(sObject record, Map<String, String> data){
            for(String columnName : mapping.keySet()){
                String fieldName = mapping.get(columnName);
                String value = data.get(columnName);
                if (value !=null ){
                    value = value.trim();
                }
                record.put(fieldName, this.trueValues.contains(value));
            }
        }
        
    }
    
    public class CustomMappingStringBinder implements IBinder{
        
        private Map<String, String> mapping;
        private Map<String, String> valuesMapping;
        
        public CustomMappingStringBinder(Map<String, String> mapping, Map<String, String> valuesMapping){
            this.mapping = mapping;
            this.valuesMapping = valuesMapping;
        }
        
        public void bind(sObject record, Map<String, String> data){
            for(String columnName : mapping.keySet()){
                String fieldName = mapping.get(columnName);
                String value = data.get(columnName);
                if (value !=null ){
                    value = value.trim();
                }
                
                if (this.valuesMapping.containsKey(value)){
                    value = this.valuesMapping.get(value);
                }
                
                record.put(fieldName, value);
            }
        }
        
    }
    
    
    public class JoinStringBinder implements IBinder{
        
        // sObject API key => file columns.    
        private Map<String, Set<String>> mapping;
        private String separator;
        private Set<String> excludeValues;
        
        public JoinStringBinder(Map<String, Set<String>> mapping, String separator, Set<String> excludeValues){
            this.mapping = mapping;
            this.separator = separator;
            this.excludeValues = excludeValues;
        }
        
        public void bind(sObject record, Map<String, String> data){
            for(String fieldName : mapping.keySet()){
                
                List<String> values = new List<String>();
                
                for(String columnName : mapping.get(fieldName)){
                    
                    if (data.containsKey(columnName)){
                        String columnValue = data.get(columnName);
                        
                        if (!excludeValues.contains(columnValue)){
                            values.add(columnValue);       
                        }
                    }
                }
                
                String value = String.join(values, this.separator);
                record.put(fieldName, value);
            }
        }
        
    }
    
    //private static final String REGEX_EMAIL = '([a-zA-Z0-9_\\-\\.\\`\\\']+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
    private static final String REGEX_EMAIL = '[a-zA-Z0-9\\.\\!\\#\\$\\%\\&\\*\\/\\=\\?\\^\\_\\+\\-\\`\\{\\|\\}\\~\'._%+-]+@[a-zA-Z0-9\\-.-]+\\.[a-zA-Z]+';
    
    public class EmailBinder extends AbstractBinder {
        
        private Map<String, String> mapping;
        private Boolean skeepWrongEmails; //TODO - implement.
        
        public EmailBinder(Map<String, String> mapping){
            this(mapping, false);
        }
        
        public EmailBinder(Map<String, String> mapping, Boolean skeepWrongEmails){
            this.mapping = mapping;
            this.skeepWrongEmails = skeepWrongEmails;
        }
        
        public void bind(sObject record, Map<String, String> data){
            for(String columnName : mapping.keySet()){
                String fieldName = mapping.get(columnName);
                
                if (record.get(fieldName) != null){ // TODO. add binder options to configure override binding settings.
                    return;
                }
                
                String email = data.get(columnName);
                
                if (String.isBlank(email)){
                    return;
                }
                
                email = email.removeEnd('`');
                
                if (!Pattern.matches(REGEX_EMAIL, email)){
                    
                    MigrationLog.error(
                        String.format(
                            '{0} Wrong email: [{1}]', 
                            new List<String>{
                                this.getLogInfo(data),
                                email
                            }
                        )
                    );
                    
                    // Skip wrong emails.
                    return;
                }
                
                
                record.put(fieldName, email);
            }
        }
    }
    
    
    // Parse date format 1/17/2015 or 1.17.2015
    public virtual class DateBinder extends AbstractBinder {
        
        private Map<String, String> mapping;
        
        public DateBinder(Map<String, String> mapping){
            this.mapping = mapping;
        }
        
        public DateBinder(Map<String, String> mapping, IBinderOptionProvider binderOptionProvider){
            super(binderOptionProvider);
            this.mapping = mapping;
        }
        
        public Date parseDate(String value, Map<String, String> data){
            String delimiter = value.contains('/') ? '/' : value.contains('.') ? '\\.' : null;
                
            if (delimiter == null){
                
                MigrationLog.error(
                    String.format(
                        '{0} Unable to parse the date: [{1}]', 
                        new List<String>{
                            this.getLogInfo(data),
                            value
                        }
                    )
                );
                
                return null;
            }
            
            List<String> dateParts = value.split(delimiter);
            
            if (dateParts.size() == 1){ // only year.
                dateParts.add(0, '1');
                dateParts.add(0, '1');
                
                MigrationLog.warn(
                    String.format(
                        '{0} The date value has only year. Set January 1 by default for year: [{1}]', 
                        new List<String>{
                            this.getLogInfo(data),
                            value
                        }
                    )
                );
                
            } 
            
            if (dateParts.size() == 3){
                return Date.newInstance(
                    Integer.valueOf(dateParts.get(2)), 
                    Integer.valueOf(dateParts.get(0)), 
                    Integer.valueOf(dateParts.get(1))
                );
            } else{
                
                MigrationLog.error(
                    String.format(
                        '{0} Unable to parse the date: [{1}]', 
                        new List<String>{
                            this.getLogInfo(data),
                            value
                        }
                    )
                );
                
                return null;
            }
        }
        
        public virtual void bind(sObject record, Map<String, String> data){
            for(String columnName : mapping.keySet()){
                String fieldName = mapping.get(columnName);
                String value = data.get(columnName);
                
                if (String.isBlank(value)){
                    return;
                }
                
                record.put(fieldName, parseDate(value, data));
            }
        }
    }
    
    // Parse date format 1/17/2015 or 1.17.2015 to DateTime
    public class DateToDateTimeBinder extends DateBinder {
        
        
        public DateToDateTimeBinder(Map<String, String> mapping){
            super(mapping);
        }
        
        public DateToDateTimeBinder(Map<String, String> mapping, IBinderOptionProvider binderOptionProvider){
            super(mapping, binderOptionProvider);
        }
        
        public override void bind(sObject record, Map<String, String> data){
            for(String columnName : mapping.keySet()){
                String fieldName = mapping.get(columnName);
                String value = data.get(columnName);
                
                if (String.isBlank(value)){
                    return;
                }
                
                Date parsedDate = this.parseDate(value, data);
                
                if (parsedDate != null){
                    Datetime dateTimeVar = Datetime.newInstance(parsedDate.year(), parsedDate.month(), parsedDate.day());
                    record.put(fieldName, dateTimeVar);       
                }
                
            }
        }
    }
    
    
    public class RecordTypeBinder extends  AbstractBinder{
        
        private String fileColumnName;
        private Map<String, String> mapping;
        private Map<String, Id> recordTypeMapping;
        
        
        public RecordTypeBinder(String fileColumnName, Map<String, String> mapping, Map<String, Id> recordTypeMapping){
            this.fileColumnName = fileColumnName;
            this.mapping = mapping;
            this.recordTypeMapping = recordTypeMapping;
        }
        
        public void bind(sObject record, Map<String, String> data){
            
            record.put('RecordTypeId', null);
            
            String value = data.get(fileColumnName);
            
            if (String.isBlank(value)){
                
                MigrationLog.error(
                    String.format(
                        '{0} RecordTypeBinder - no value in the file for column: [{1}]', 
                        new List<String>{
                            this.getLogInfo(data),
                            value
                        }
                    )
                );
                
                return;
                //throw new BindingException('RecordTypeBinder - no value in the file for column: ' + fileColumnName);
            }
            
            String recordTypeDeveloperName = mapping.get(value);
            
            if (String.isBlank(recordTypeDeveloperName)){
                
                MigrationLog.error(
                    String.format(
                        '{0} RecordTypeBinder - no record type for value: [{1}]', 
                        new List<String>{
                            this.getLogInfo(data),
                            value
                        }
                    )
                );
                
                return;
                //throw new BindingException('RecordTypeBinder - no record type for value: ' + value);
            }
            
            Id recordTypeId = this.recordTypeMapping.get(recordTypeDeveloperName);
            
            if (String.isBlank(recordTypeId)){
                
                MigrationLog.error(
                    String.format(
                        '{0} RecordTypeBinder - no record type for name: [{1}]', 
                        new List<String>{
                            this.getLogInfo(data),
                            recordTypeDeveloperName
                        }
                    )
                );
                
                return;
                
                //throw new BindingException('RecordTypeBinder - no record type for name: ' + recordTypeDeveloperName);
            }
            
            record.put('RecordTypeId', recordTypeId);
        }
    }
    
    
    public class LookupBinder extends AbstractBinder implements ILookupBinder {
        
        private String fileColumnName;
        private String masterTypeName;
        
        private String masterFieldName;
        private String detailFieldName; 
        
        private Map<String, List<sObject>> mapping;
        
        
        public LookupBinder(
            String fileColumnName,
            Schema.SobjectType masterType,
            String masterFieldName,
            String detailFieldName     
        )
        {
            this.fileColumnName = fileColumnName;
            this.masterTypeName = masterType.getDescribe().getName();
            
            this.masterFieldName = masterFieldName;
            this.detailFieldName = detailFieldName;
            
            this.mapping = new Map<String, List<sObject>>();
        } 
        
        public LookupBinder(
            String fileColumnName,
            Schema.SobjectType masterType,
            String masterFieldName,
            String detailFieldName,
            IBinderOptionProvider binderOptionProvider
        )
        {
            super(binderOptionProvider);
            this.fileColumnName = fileColumnName;
            this.masterTypeName = masterType.getDescribe().getName();
            
            this.masterFieldName = masterFieldName;
            this.detailFieldName = detailFieldName;
            
            this.mapping = new Map<String, List<sObject>>();
        } 
        
        public void bind(sObject record, Map<String, String> data){
            
            String value = data.get(fileColumnName);
            
            if (String.isBlank(value)){
                return;
            }
            
            List<sObject> records = mapping.get(value);
            if (records == null){
                records = new List<sObject>();
                mapping.put(value, records);
            }
            
            records.add(record);
        }
        
        public void bindLookups(){
            
            // Prepare values to bind.
            Set<String> mappingValues = this.mapping.keySet();
            
            String soql = String.format(
                'SELECT Id, {0} FROM {1} WHERE {0} IN :mappingValues', 
                new List<String>{
                    this.masterFieldName,
                    this.masterTypeName
                }
            );
            
            List<sObject> masterRecords = Database.query(soql);
            
            Map<String, sObject> masterRecordsMap = new Map<String, SObject>();
            for(SObject masterRecord : masterRecords){
                String mappingValue = (String)masterRecord.get(this.masterFieldName);
                masterRecordsMap.put(mappingValue, masterRecord);
            }
            
            
            // Bind values.
            for(String mappingValue : this.mapping.keySet()){
                
                sObject masterRecord = masterRecordsMap.get(mappingValue);
                
                if(masterRecord == null){
                    /*
                    MigrationLog.debug(
                        String.format(
                            'LookupBinder - No master record found. [{0}].[{1}] -> [{2}].    Value: [{3}]', 
                            new List<String>{
                                this.masterTypeName,
                                this.masterFieldName,
                                this.detailFieldName,
                                mappingValue
                            }
                        )
                    );
                    */
                    continue;
                }
                
                for(sObject record : mapping.get(mappingValue)){
                    
                    if (record.get(this.detailFieldName) == null || binderOptionProvider.isOverrideValue(record, null)){
                        record.put(this.detailFieldName, masterRecord.Id);   
                    }
                    
                }
            }
        }
        
    }
        
   
    
    public class UpperCaseBinder extends AbstractBinder {
        
        private Set<String> fields;
        
        public UpperCaseBinder(Set<String> fields){
            this.fields = fields;
        }
        
        public void bind(sObject record, Map<String, String> data){
            
            for(String fieldName : this.fields){
                String value = (String)record.get(fieldName);
                if (String.isNotBlank(value)){
                    value = value.toUpperCase();
                    record.put(fieldName, value);
                }
            }
        }
    }
    
    
    public class MutipicklistBinder extends AbstractBinder {
        
        private String recordFieldName;
        private Set<String> fileColumns;
        private Set<String> availableValues;
        
        public MutipicklistBinder(String recordFieldName, Set<String> fileColumns, Set<String> availableValues){
            this.recordFieldName = recordFieldName;
            this.fileColumns = fileColumns;
            this.availableValues = availableValues;
        }
        
        
        public MutipicklistBinder(String recordFieldName, Set<String> fileColumns, Set<String> availableValues, IBinderOptionProvider binderOptionProvider){
            super(binderOptionProvider);
            this.recordFieldName = recordFieldName;
            this.fileColumns = fileColumns;
            this.availableValues = availableValues;
        }
        
        
        public void bind(sObject record, Map<String, String> data){
            
            if (this.binderOptionProvider.isSkeepBinding(record, data)) return;
            
            for(String columnName : fileColumns){
                String fileValue = data.get(columnName);
                
                if (availableValues.contains(fileValue)){
                    String recordValue = (String)record.get(recordFieldName);   
                    
                    Set<String> fieldValues = recordValue == null ? new Set<String>() : new Set<String>(recordValue.split(';'));
                    
                    fieldValues.add(columnName);
                    
                    recordValue = String.join(new List<String>(fieldValues), ';');
                    
                    record.put(recordFieldName, recordValue);   
                }
            }
            
        }
        
    }
    
    public class OverrideValueBinderOptionProvider extends DefaultBinderOptionProvider{
        
        private Boolean allowOverride;
        
        public OverrideValueBinderOptionProvider(Boolean allowOverride){
            this.allowOverride = allowOverride;
        }
        
        public override Boolean isOverrideValue(sObject record, Map<String, String> data){
            return this.allowOverride;
        }
        
    }
    
    
    public class SkeepIfEqualValuesBinderOptionProvider extends DefaultBinderOptionProvider{
        
        private String recordFieldName;
        private String value;
        
        public SkeepIfEqualValuesBinderOptionProvider(String recordFieldName, String value){
            this.recordFieldName = recordFieldName;
            this.value = value;
        }
        
        public override Boolean isSkeepBinding(sObject record, Map<String, String> data){
            return record.get(recordFieldName) == value;
        }
        
    }
    
    public class SkeepIfNotEqualValuesBinderOptionProvider extends DefaultBinderOptionProvider{
        
        private String recordFieldName;
        private String value;
        
        public SkeepIfNotEqualValuesBinderOptionProvider(String recordFieldName, String value){
            this.recordFieldName = recordFieldName;
            this.value = value;
        }
        
        public override Boolean isSkeepBinding(sObject record, Map<String, String> data){
            return record.get(recordFieldName) != value;
        }
        
    }
    
    
    /*
        PHONE FORMAT LOGIC.
    */
    private static String removeNonNumeric(String str) {
        return String.isEmpty(str) ? str : str.replaceAll('[^0-9]*', '');
    }
    
    public interface IPhoneNumberFormatter {
        String format(String phone);
    }
    
    // Formats Phone number to '0411 222 333'
    public class MobilePhoneNumberFormatter implements IPhoneNumberFormatter {
        
        public String format(String phone){
            if (String.isNotEmpty(phone)) {
                String phoneFormatted = removeNonNumeric(phone);
                
                if (phoneFormatted.length() == 9 && phoneFormatted.startsWith('4')){
                    phoneFormatted = '0' + phoneFormatted;
                }
                    
                    
                if (phoneFormatted.length() == 10){
                    
                    if (phoneFormatted.length() == 10 && phoneFormatted.startsWith('64')){
                        phoneFormatted = phoneFormatted.replaceFirst('^[64]', '04');
                    }
                    
                    phoneFormatted = String.format('{0} {1} {2}', new List<String> {
                        phoneFormatted.substring(0, 4),
                        phoneFormatted.substring(4, 7),
                        phoneFormatted.substring(7, 10)
                    });
                    
                    return phoneFormatted;
                }
            }
            
            return phone; 
        }
        
    }
    
    // Formats phone to '+64 9 308 6200'
    public class DefaultHomePhoneNumberFormatter implements IPhoneNumberFormatter {
        
        public String format(String phone){
            final String countryCode = '64';
        
            if (String.isNotEmpty(phone)) {
                String phoneFormatted = removeNonNumeric(phone);
                if (phoneFormatted.length() == 8) {
                    phoneFormatted = countryCode + phoneFormatted;
                } else if (phoneFormatted.length() == 10 && phoneFormatted.startsWith('04')){
                    phoneFormatted = phoneFormatted.replaceFirst('^[0]', '6');
                }
                    
                if (phoneFormatted.length() == 10){
                    phoneFormatted = String.format('+{0} {1} {2} {3}', new List<String> {
                        phoneFormatted.substring(0, 2),
                        phoneFormatted.substring(2, 3),
                        phoneFormatted.substring(3, 6),
                        phoneFormatted.substring(6, 10)
                    });
                    
                    return phoneFormatted;
                }
            }
            
            return phone;
        }
        
    }
    
    // Formats phone to '03 9347 1188'
    //                   03 9367 4648
    public class CustomHomePhoneNumberFormatter implements IPhoneNumberFormatter {
        
        public String format(String phone){
            final String countryCode = '03';
        
            if (String.isNotEmpty(phone)) {
                String phoneFormatted = removeNonNumeric(phone);
                if (phoneFormatted.length() == 8) {
                    phoneFormatted = countryCode + phoneFormatted;
                } else if (phoneFormatted.length() == 9 && phoneFormatted.startsWith('3')) {
                    phoneFormatted = '0' + phoneFormatted;
                }
                    
                if (phoneFormatted.length() == 10){
                    phoneFormatted = String.format('{0} {1} {2}', new List<String> {
                        phoneFormatted.substring(0, 2),
                        phoneFormatted.substring(2, 6),
                        phoneFormatted.substring(6, 10)
                    });
                    
                    return phoneFormatted;
                }
            }
            
            return phone;
        }
        
    }
    
    public class Relation{
        public sObject masterRecord;
        public String masterFieldName;
        
        public String detailsFieldName;
        public List<sObject> detailsRecords;
        
        public Relation(sObject masterRecord, String masterFieldName, String detailsFieldName, List<sObject> detailsRecords){
            this.masterRecord = masterRecord;
            this.masterFieldName = masterFieldName;
            this.detailsFieldName = detailsFieldName;
            this.detailsRecords = detailsRecords;
        }
    }
    
    public static void initializeRelations(List<Relation> relations){
        for(Relation relationVar : relations){
            for(sObject detailsRecordVar : relationVar.detailsRecords){
                Object masterFieldVaule = relationVar.masterRecord.get(relationVar.masterFieldName);
                detailsRecordVar.put(relationVar.detailsFieldName, masterFieldVaule);
            }
        }
    }
    
    
    public class MigrationException extends Exception {}
    public class BindingException extends Exception {}
}
