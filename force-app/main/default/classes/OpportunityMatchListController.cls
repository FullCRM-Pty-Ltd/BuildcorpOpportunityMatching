/*
 * Opportunity Match List LWC Controller
 * 
 * Created Date: 28/07/2023
 * Created By: Callum Van Den Hoek (FullCRM)
 * 
 * Description:
 * 
 * This class is used as an Apex controller for the OpportunityMatchList Lightning Web Component.
 * The class includes methods that compare a given Opportunity to a selection of other Opportunities,
 * and compare the values of a set of fields, defined as Field Sets on the Opportunity object.
 * If any of these Opportunities have above a certain number of fields that match the input Opportunity's fields,
 * they will be included into a list that will eventually be returned out of the method.
 * 
 * The LWC will then use this returned list of Opportunities to populate a 'Related List'-style component on the 
 * Opportunity page.
 * 
 * 
 */

 public with sharing class OpportunityMatchListController {

    @AuraEnabled (cacheable=false)
    public static List<Opportunity> RetrieveMatchingOpportunities(Id opportunityToMatchId){

        boolean customException = false;

        try {

            Opportunity mainOpp = [SELECT Id, Buildcorp_Business_Unit__c, RecordTypeId FROM Opportunity WHERE Id = :opportunityToMatchId];

            String businessUnit;

            if(mainOpp.Buildcorp_Business_Unit__c != null) businessUnit = mainOpp.Buildcorp_Business_Unit__c;
            else{
                customException = true;
                System.debug('Please Enter a Business Unit for this Opportunity');
                AuraHandledException e = new AuraHandledException('Please Enter a Business Unit for this Opportunity');
                e.setMessage('Please Enter a Business Unit for this Opportunity');
                throw e;
            }
            
            String fieldSetName = businessUnit.replace(' ','_')+'_Questionnaire';
            
            System.debug('Getting matching fields from '+fieldSetName+' fieldset.');
            
            List<Schema.FieldSetMember> matchingFieldList = GetFieldsFromFieldSet('Opportunity', fieldSetName);
            
            System.debug('Fields retrieved: '+matchingFieldList);
            
            String soqlQuery = 'SELECT Id, Name';
            
            for(Schema.FieldSetMember matchingField : matchingFieldList){
                soqlQuery+=', '+matchingField.getFieldPath();
            }

            String columnFieldSetName = businessUnit.replace(' ','_')+'_Columns';

            System.debug('Getting column display fields from '+columnFieldSetName+' fieldset.');
            
            List<Schema.FieldSetMember> columnFieldList = GetFieldsFromFieldSet('Opportunity', columnFieldSetName);
            
            System.debug('Fields retrieved: '+columnFieldList);
            
            for(Schema.FieldSetMember columnField : columnFieldList){
                String fieldPath = columnField.getFieldPath();

                if(columnField.getType().name().toLowerCase() == 'reference'){
                    if(fieldPath.endsWith('Id')) fieldPath = fieldPath.replace('Id','.Name');
                    else if(fieldPath.endsWith('__c')) fieldPath = fieldPath.replace('__c','__r.Name');
                }

                soqlQuery+=', '+fieldPath;
            }

            soqlQuery+=' FROM Opportunity WHERE Id !=\''+opportunityToMatchId+'\' AND Buildcorp_Business_Unit__c = \''+businessUnit+'\' AND RecordTypeId = \''+mainOpp.RecordTypeId+'\' AND (';

            for(Schema.FieldSetMember matchingField : matchingFieldList){
                String fieldPath = matchingField.getFieldPath();
                fieldPath = matchingField.getFieldPath();

                soqlQuery+=fieldPath+' != null OR ';
            }

            soqlQuery = soqlQuery.left(soqlQuery.length()-4);
            soqlQuery += ')';

            System.debug('SOQL Query updated: '+soqlQuery);
            /*Query should like like this: 
            'SELECT Id, Name, {Field1}, {Field2}, etc., 
            FROM Opportunity 
            WHERE Id != {MainOppID} AND Buildcorp_Business_Unit__c = {MainOppBusinessUnit} AND RecordTypeId = {MainOppRecordTypeId} AND ({Field1} != null OR {Field2} != null OR ... etc.)'
            */


            List<Opportunity> oppsToCompare = Database.query(soqlQuery);

            if(oppsToCompare.isEmpty()){
                customException = true;
                System.debug('Error caught: No Opportunities Found To Compare Against.');
                AuraHandledException e = new AuraHandledException('No Opportunities Found To Compare Against.');
                e.setMessage('No Opportunities Found To Compare Against.');
                throw e;
            }
            
            soqlQuery = 'SELECT Id, Name';
            
            for(Schema.FieldSetMember matchingField : matchingFieldList){
                soqlQuery+=', '+matchingField.getFieldPath();
            }
            soqlQuery+=' FROM Opportunity WHERE Id =\''+opportunityToMatchId+'\'';
            
            
            mainOpp = (Opportunity)Database.query(soqlQuery)[0];
            
            List<Opportunity_Matching_Threshold__mdt> matchingThresholdList = [SELECT Id, Matching_Threshold__c FROM Opportunity_Matching_Threshold__mdt WHERE Business_Unit__c = :businessUnit];
            Opportunity_Matching_Threshold__mdt matchingThreshold;
            if(!matchingThresholdList.isEmpty()){
                matchingThreshold = matchingThresholdList[0];
            }
            else{
                customException = true;
                System.debug('No Matching Threshold Found for Business Unit \''+businessUnit+'\'');
                AuraHandledException e = new AuraHandledException('No Matching Threshold Found for Business Unit \''+businessUnit+'\'');
                e.setMessage('No Matching Threshold Found for Business Unit \''+businessUnit+'\'');
                throw e;
            }
            
            Double matchingThresholdPct = matchingThreshold.Matching_Threshold__c/100;
            
            System.debug('Matching Threshold: '+matchingThresholdPct);
            
            List<Opportunity> matchedOpportunityList = new List<Opportunity>();
            
            for(Opportunity oppToCompare : oppsToCompare){
                Double fieldsMatched = 0;
                Double totalFieldCount = 0;
                System.debug('****************************************************');
                System.debug('Opportunity: '+oppToCompare.Name);
                for(Schema.FieldSetMember field : matchingFieldList){
                    String mainOppFieldValue = (String) mainOpp.get(field.getFieldPath());
                    String thisOppFieldValue = (String) oppToCompare.get(field.getFieldPath());
                    
                    if(mainOppFieldValue == null && thisOppFieldValue == null) continue;

                    if(mainOppFieldValue == thisOppFieldValue) fieldsMatched++; 
                    totalFieldCount++;
                                        
                }
                
                Double matchedPct = fieldsMatched / totalFieldCount;
                
                System.debug('Total Fields: '+totalFieldCount+', Matched Fields: '+fieldsMatched+', Percentage Match: '+matchedPct);
                
                if(matchedPct >= matchingThresholdPct){
                    
                    System.debug('This Opportunity has matched above the required threshold.');
                    oppToCompare.Match_Percent__c = matchedPct;
                    matchedOpportunityList.add(oppToCompare);
                    
                }
                
            }
            
            if(!matchedOpportunityList.isEmpty()) return matchedOpportunityList;
            else {
                System.debug('No Matching Opportunities Found.');
                AuraHandledException e = new AuraHandledException('No Matching Opportunities Found.');
                e.setMessage('No Matching Opportunities Found.');
                customException = true;
                throw e;
            }
        } 
        catch (Exception e) {
            System.debug('Error caught: '+e.getMessage()+'\n'+e.getStackTraceString());
            AuraHandledException ex;
            if(customException == false) {
                ex = new AuraHandledException(e.getMessage()+'\n'+ e.getStackTraceString());
                ex.setMessage(e.getMessage()+'\n'+ e.getStackTraceString());
            }
            else {
                ex = new AuraHandledException(e.getMessage());
                ex.setMessage(e.getMessage());
            }
            throw ex;
        }
    }


    //For Match Pct: return Map<Opportunity,Double> where the value is the percent, input this map into the below method 
    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> GetColumnsFromFieldSet(Id opportunityId){
        Opportunity opp = [SELECT Id, Buildcorp_Business_Unit__c FROM Opportunity WHERE Id = :opportunityId][0];

        String businessUnit = opp.Buildcorp_Business_Unit__c;

        String fieldSetName = businessUnit.replace(' ','_')+'_Columns';

        List<Schema.FieldSetMember> fieldList = GetFieldsFromFieldSet('Opportunity', fieldSetName);

        List<Map<String,Object>> columnMap = new List<Map<String,Object>>();
        Map<String,Map<String,String>> typeAttributes = new Map<String,Map<String,String>>();
        typeAttributes.put('label', new Map<String,String>{'fieldName' =>'Name'});
        Map<String,Object> recordURL = new Map<String,Object>{'label'=>'Name', 'fieldName'=>'recordURL','type'=>'url','typeAttributes' => typeAttributes, 'sortable' => true};

        columnMap.add(recordURL);

        for (Schema.FieldSetMember field : fieldList){

            String fieldPath = field.getFieldPath();

            System.debug('Field Type: '+field.getType().name());

            String fieldType; 
            switch on field.getType().name(){
                when 'BOOLEAN'{
                    fieldType = 'boolean';
                }
                when 'CURRENCY'{
                    fieldType = 'currency';
                }
                when 'DATE'{
                    fieldType = 'date-local';
                }
                when 'DATETIME'{
                    fieldType = 'date';
                }
                when 'DOUBLE', 'INTEGER', 'LONG'{
                    fieldType = 'number';
                }
                when 'EMAIL'{
                    fieldType = 'email';
                }
                when 'PHONE'{
                    fieldType = 'phone';
                }
                when else{
                    fieldType = 'text';
                }
            }

            System.debug('Field Path: '+fieldPath);
            
            Map<String,Object> fieldMap = new Map<String,Object>{'label'=> field.getLabel(), 'fieldName' => fieldPath, 'type' => fieldType, 'sortable' => true};
            System.debug('Field Map: '+fieldMap);
            columnMap.add(fieldMap);
        }

        Map<String, Object> cellAttributes = new Map<String, Object>{'alignment'=>'left', 'class' => new Map<String,String>{'fieldName' => 'textColour'}};
        Map<String,Object> matchPercentMap = new Map<String,Object>{'label' => 'Match %', 'fieldName' => 'Match_Percent__c', 'type' => 'percent', 'sortable' => true, 'cellAttributes' => cellAttributes};
        columnMap.add(matchPercentMap);
        System.debug(columnMap);
        return columnMap;

    }

    public static List<Schema.FieldSetMember> GetFieldsFromFieldSet(String objectName, String fieldSetName){

        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

        system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName));

        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

        List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        system.debug('fieldSetMemberList ====>' + fieldSetMemberList);  

        return fieldSetMemberList; 

    }
}