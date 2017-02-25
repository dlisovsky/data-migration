public class MigrationCSVReader {
    
    private final static String DEFAULT_ROW_SEPARATOR = '\r\n';
    private final static String DEFAULT_COLUMN_SEPARATOR = '\t';
    
    private final String rowSeparator;
    private final String columnSeparator;
    
    public MigrationCSVReader (){
        this.rowSeparator = DEFAULT_ROW_SEPARATOR;
        this.columnSeparator = DEFAULT_COLUMN_SEPARATOR;
    }
    
    public MigrationCSVReader (String rowSeparator, String columnSeparator){
        this.rowSeparator = rowSeparator;
        this.columnSeparator = columnSeparator;
    }
    
    public CSVWrapper parseCSV(String rawData){
        List<String> headers;
        List<List<String>> rows = new List<List<String>>();
        
        try {
            RowReader rowReader = new RowReader(rawData, this.rowSeparator);
            
            // Read header of CSV.
            List<String> columnsNames = new List<String>();
            if (rowReader.hasNext()) {
                headers = safeSplit(rowReader.next(), this.columnSeparator);
            }
            
            // Read CSV rows.
            while (rowReader.hasNext()) {
                List<String> columns = safeSplit(rowReader.next(), this.columnSeparator);

                if (columns.size() != headers.size()) {
                    throw new CSVReaderException(String.format('Invalid columns count for row: {0}. Header columns count: {1}. Row columns count: {2}.', new List<String>{
                        String.valueOf(rows.size() + 1),
                        String.valueOf(headers.size()),
                        String.valueOf(columns.size())
                    }));
                }

                rows.add(columns);
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage() + ': ' + ex.getStackTraceString());
            throw new CSVReaderException(ex);
        }
        
        return new CSVWrapper(headers, rows);
    }
    
    private static List<String> safeSplit(String inStr, String delim) {
        
        Integer regexFindLimit = 100;
        Integer regexFindCount = 0;
        
        List<String> output = new List<String>();
        
        Matcher matcher = Pattern.compile(delim).matcher(inStr);
        
        Integer lastEnd = 0;
    
        while(!matcher.hitEnd())
        {
            while(regexFindCount < regexFindLimit && !matcher.hitEnd())
            {
                if(matcher.find())
                {
                    output.add(inStr.substring(lastEnd, matcher.start()));  
                    lastEnd = matcher.end();
                }
                else
                {
                    output.add(inStr.substring(lastEnd));
                    lastEnd = inStr.length();
                }
                
                regexFindCount++;
            }
    
            // Note: Using region() to advance instead of substring() saves 
            // drastically on heap size. Nonetheless, we still must reset the 
            // (unmodified) input sequence to avoid a 'Regex too complicated' 
            // error.
            matcher.reset(inStr);        
            matcher.region(lastEnd, matcher.regionEnd());
            
            regexFindCount = 0;
        }
        
        return output;
    }
    
    public class CSVWrapper {
        
        private List<String> headers;
        private List<List<String>> rows;
        
        private CSVWrapper(List<String> headers, List<List<String>> rows){
            this.headers = headers;
            this.rows = rows;
        }
        
        // Starts from 0;
        public Map<String, String> getRowData(Integer rowIndex){
            if (rowIndex < 0 || rowIndex >= rows.size()){
                throw new CSVReaderException('Index is out of bounds - ' + rowIndex);
            }   
            
            Map<String, String> result = new Map<String, String>();
            
            List<String> rowData = rows.get(rowIndex);
            
            Integer columnIndex = 0;
            for(String header : headers){
                result.put(header, rowData.get(columnIndex));
                columnIndex++;
            }
            
            return result;
        }
        
        public Integer getTotalRows(){
            return rows.size();
        }
        
        public List<String> getColumnValues(String columnName) {
            List<String> columnValues = new List<String>();

            Integer totalRows = getTotalRows();
            for (Integer rowIndex = 0; rowIndex < totalRows; rowIndex++) {
                String columnValue = getRowData(rowIndex).get(columnName);
                if (String.isNotBlank(columnValue)) {
                    columnValues.add(columnValue);
                }
            }

            return columnValues;
        }

        public Set<String> getColumnUniqueValues(String columnName) {
            return new Set<String>(getColumnValues(columnName));
        }

    }
    
    private class RowReader implements Iterator<String>, Iterable<String> {      
        
        private final String rowSeparator;
        private String rowData;
    
        public RowReader(String rowData, String rowSeparator) {       
            this.rowData = rowData;
            this.rowSeparator = rowSeparator;
        }
    
        public Boolean hasNext() {
            return rowData.length() > 0;
        }   
    
        public String next() {
            String row = null;
            Integer endPos = rowData.indexOf(rowSeparator);
            if(endPos < 0) {
                row = rowData;
                rowData = '';
            } else {
                row = rowData.substring(0, endPos);
                rowData = rowData.substring(endPos + rowSeparator.length(), rowData.length());             
            }
            return row;
        }
    
        public Iterator<String> Iterator() {
            return this;   
        }           
    } 
    
    public class CSVReaderException extends Exception{}
    
}
