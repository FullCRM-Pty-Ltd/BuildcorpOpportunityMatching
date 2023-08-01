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

    @AuraEnabled (cacheable=true)
    public static List<Opportunity> RetrieveMatchingOpportunities(Id opportunityToMatchId){
        try {

            Opportunity mainOpp = [SELECT Id, Buildcorp_Business_Unit__c FROM Opportunity WHERE Id = :opportunityToMatchId];

            String businessUnit = mainOpp.Buildcorp_Business_Unit__c;
            
            String fieldSetName = businessUnit.replace(' ','_')+'_Questionnaire';
            
            System.debug('Getting fields from '+fieldSetName+' fieldset.');
            
            List<Schema.FieldSetMember> matchingFieldList = GetFieldsFromFieldSet('Opportunity', fieldSetName);
            
            System.debug('Fields retrieved: '+matchingFieldList);
            
            String soqlQuery = 'SELECT Id, Name, Record_URL__c';
            
            for(Schema.FieldSetMember matchingField : matchingFieldList){
                System.debug('Field Name: '+matchingField.getFieldPath());
                soqlQuery+=', '+matchingField.getFieldPath();
            }

            String columnFieldSetName = businessUnit.replace(' ','_')+'_Columns';

            System.debug('Getting fields from '+columnFieldSetName+' fieldset.');
            
            List<Schema.FieldSetMember> matchingColumnFieldList = GetFieldsFromFieldSet('Opportunity', columnFieldSetName);
            
            System.debug('Fields retrieved: '+matchingColumnFieldList);
            
            for(Schema.FieldSetMember matchingField : matchingColumnFieldList){
                String fieldPath = matchingField.getFieldPath();
                System.debug('Field Name: '+matchingField.getFieldPath());
                if(matchingField.getType().name().toLowerCase() == 'reference'){
                    fieldPath = matchingField.getFieldPath().replace('Id','.Name');
                    fieldPath = matchingField.getFieldPath().replace('__c','__r.Name');
                }
                else fieldPath = matchingField.getFieldPath();

                if(matchingField.getType().name().toLowerCase() == 'reference'){
                    System.debug('Reference Field: '+fieldPath);
                    if(fieldPath.endsWith('Id')) fieldPath = fieldPath.replace('Id','.Name');
                    else if(fieldPath.endsWith('__c')) fieldPath = fieldPath.replace('__c','__r.Name');
                }

                soqlQuery+=', '+fieldPath;
            }

            soqlQuery+=' FROM Opportunity WHERE Id !=\''+opportunityToMatchId+'\' AND Buildcorp_Business_Unit__c = \''+businessUnit+'\'';
            System.debug('SOQL Query formed: '+soqlQuery);
            
            List<Opportunity> oppsToCompare = Database.query(soqlQuery);
            
            soqlQuery = 'SELECT Id, Name';
            
            for(Schema.FieldSetMember matchingField : matchingFieldList){
                System.debug('Field Name: '+matchingField.getFieldPath());
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
                AuraHandledException e = new AuraHandledException('Error: No Matching Threshold Found for Business Unit \''+businessUnit+'\'');
                e.setMessage('Error: No Matching Threshold Found for Business Unit \''+businessUnit+'\'');
                throw e;
            }
            
            Double matchingThresholdPct = matchingThreshold.Matching_Threshold__c/100;
            
            System.debug('Matching Threshold: '+matchingThresholdPct);
            
            List<Opportunity> matchedOpportunityList = new List<Opportunity>();
            
            for(Opportunity oppToCompare : oppsToCompare){
                Double fieldsMatched = 0;
                System.debug('****************************************************');
                System.debug('Opportunity: '+oppToCompare.Name);
                for(Schema.FieldSetMember field : matchingFieldList){
                    String mainOppFieldValue = (String) mainOpp.get(field.getFieldPath());
                    String thisOppFieldValue = (String) oppToCompare.get(field.getFieldPath());
                    
                    if(mainOppFieldValue == thisOppFieldValue){
                        fieldsMatched++;
                        System.debug('Comparing field: '+field.getFieldPath()+'. Main Opp: "'+mainOppFieldValue+'", This Opp: "'+thisOppFieldValue+'" -- Matched!');
                    } 
                    
                    else System.debug('Comparing field: '+field.getFieldPath()+'. Main Opp: "'+mainOppFieldValue+'", This Opp: "'+thisOppFieldValue+'"');
                    
                }
                
                Double totalFieldCount = matchingFieldList.size();
                Double matchedPct = fieldsMatched / totalFieldCount;
                
                System.debug('Total Fields: '+totalFieldCount+', Matched Fields: '+fieldsMatched+', Percentage Match: '+matchedPct);
                
                if(matchedPct >= matchingThresholdPct){
                    
                    System.debug('This Opportunity has matched above the required threshold.');
                    oppToCompare.Match_Percent__c = matchedPct;
                    matchedOpportunityList.add(oppToCompare);
                    
                }
                
            }
            
            if(!matchedOpportunityList.isEmpty()) return matchedOpportunityList;
            else return null;
        } 
        catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage()+'\n'+ e.getStackTraceString());
            ex.setMessage(e.getMessage()+'\n'+ e.getStackTraceString());
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
        Map<String,Object> recordURL = new Map<String,Object>{'label'=>'Name', 'fieldName'=>'Record_URL__c','type'=>'url','typeAttributes' => typeAttributes, 'sortable' => true};

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

            if(field.getType().name().toLowerCase() == 'reference'){
                System.debug('Reference Field: '+fieldPath);
                if(fieldPath.endsWith('Id')) fieldPath = fieldPath.replace('Id','.Name');
                else if(fieldPath.endsWith('__c')) fieldPath = fieldPath.replace('__c','__r.Name');
                Map<String,Object> fieldMap = new Map<String,Object>{
                    'label'=> field.getLabel(), 
                    'fieldName' => '/lightning/r/+row.'+field.getFieldPath()+'+/view', 
                    'type' => 'url', 
                    'typeAttributes' => new Map<String, Object>{
                        'label' => new Map<String, String>{
                            'fieldName' => 'row.'+fieldPath
                        },
                        'target' => '_self'
                    },
                    'sortable' => true
                };
                System.debug(fieldMap);
                columnMap.add(fieldMap);
            }
            else{
                System.debug('Field Path: '+fieldPath);
                
                Map<String,Object> fieldMap = new Map<String,Object>{'label'=> field.getLabel(), 'fieldName' => fieldPath, 'type' => fieldType, 'sortable' => true};
                System.debug('Field Map: '+fieldMap);
                columnMap.add(fieldMap);
            }
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