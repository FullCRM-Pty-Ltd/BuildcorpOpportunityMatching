public with sharing class OpportunityScoringCalculator {


    public static void CalculateOpportunityScore(Map<String, String> oppIdBusinessUnitMap){

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        String soqlQuery = 'SELECT Id, Buildcorp_Business_Unit__c, Name';

        Set<String> businessUnitSet = new Set<String>();

        Map<String,List<Schema.FieldSetMember>> fieldSetMemberMap = new Map<String,List<Schema.FieldSetMember>>();

        Set<String> matchingFieldSet = new Set<String>();

        Set<String> oppIdSet = oppIdBusinessUnitMap.keySet();
        
        for (String oppId : oppIdBusinessUnitMap.keySet()){
        
            String businessUnit = oppIdBusinessUnitMap.get(oppId);

            if(!businessUnitSet.contains(businessUnit)){
                
                businessUnitSet.add(businessUnit);

                String fieldSetName = businessUnit.replace(' ','_')+'_Questionnaire';

                Map<String,List<Schema.FieldSetMember>> fieldSetMap;

                Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
                Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Opportunity');
                Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
                
                Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

                if(fieldSetObj == null) return;
                
                List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();

                fieldSetMemberMap.put(businessUnit, fieldSetMemberList);
                    
                for(Schema.FieldSetMember matchingField : fieldSetMemberList){

                    if(!matchingFieldSet.contains(matchingField.getFieldPath())) {
                        soqlQuery+=', '+matchingField.getFieldPath();
                        matchingFieldSet.add(matchingField.getFieldPath());
                    }
                }
            }
        }

        soqlQuery+=' FROM Opportunity WHERE Id IN :oppIdSet';

        System.debug('Opportunity SOQL Query: '+soqlQuery);

        Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>((List<Opportunity>)Database.query(soqlQuery));

        soqlQuery = 'SELECT Id, Business_Unit__c, Value_1_Score__c, Value_2_Score__c, Value_3_Score__c, Value_4_Score__c, Value_5_Score__c, Matching_Threshold__c FROM Opportunity_Matching_Threshold__mdt WHERE Business_Unit__c IN :businessUnitSet';

        System.debug('CMDT SOQL Query: '+soqlQuery);
        
        List<Opportunity_Matching_Threshold__mdt> valueScoringList = (List<Opportunity_Matching_Threshold__mdt>)Database.query(soqlQuery);

        Map<String, Opportunity_Matching_Threshold__mdt> valueScoringMap = new Map<String,Opportunity_Matching_Threshold__mdt>();

        for (Opportunity_Matching_Threshold__mdt valueScoring : valueScoringList){
            valueScoringMap.put(valueScoring.Business_Unit__c, valueScoring);
        }

        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Opportunity');
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();


        for (String oppId : oppIdBusinessUnitMap.keySet()){

            Opportunity opp = oppMap.get(oppId);

            Map<String,List<String>> fieldPickListValueMap = new Map<String,List<String>>();

            Opportunity_Matching_Threshold__mdt valueScoring = valueScoringMap.get(oppIdBusinessUnitMap.get(oppId));

            if(valueScoring == null) return;

            Integer oppScore = 0;

            List<Schema.FieldSetMember> fieldSetMemberList = fieldSetMemberMap.get(opp.Buildcorp_Business_Unit__c);
            
            for(Schema.FieldSetMember field : fieldSetMemberList){
                String fieldName = field.getFieldPath();

                System.debug('Field: '+fieldName);

                if(opp.get(fieldName) == null) continue;
            
                List<String> pickListValuesList= new List<String>();

                String oppFieldValue = (String) opp.get(fieldName);

                System.debug('Opp Field Value is: '+oppFieldValue);

                Integer oppFieldValueIndex;
            
                Schema.DescribeFieldResult fieldResult = DescribeSObjectResultObj.fields.getMap().get(fieldName).getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

                for( Integer i = 1; i <= ple.size(); i++){

                    String valueLabel = ple[i-1].getLabel();

                    if(oppFieldValue == valueLabel) {

                        System.debug('Opp field value matches picklist label: '+valueLabel);
                        System.debug('Index is '+i);

                        oppFieldValueIndex = i;
                        break;
                    }
                }    
                
                Integer valueScore = Integer.valueOf(valueScoring.get('Value_'+oppFieldValueIndex+'_Score__c'));

                System.debug('Adding '+valueScore+' to '+oppScore+' to get '+(oppScore+valueScore));

                oppScore+=valueScore;

            }

            System.debug('Opp Score: '+oppScore);

            opp.Business_Unit_Score__c = oppScore;
            oppsToUpdate.add(opp);
        }

        update oppsToUpdate;

    }

    
}