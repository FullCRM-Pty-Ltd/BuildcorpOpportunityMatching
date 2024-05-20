public with sharing class OpportunityScoringCalculator {


    public static void CalculateOpportunityScore(Map<String, Map<String,String>> oppIdBusinessUnitMap){

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        String soqlQuery = 'SELECT Id, Buildcorp_Business_Unit__c, Record_Type_Name__c, Sector__c, Name';

        Set<String> businessUnitSet = new Set<String>();
        Set<String> recordTypeSet = new Set<String>();

        Map<String,List<Schema.FieldSetMember>> fieldSetMemberMap = new Map<String,List<Schema.FieldSetMember>>();

        Set<String> matchingFieldSet = new Set<String>();

        List<String> sectorNames = new List<String>();

        Set<String> oppIdSet = oppIdBusinessUnitMap.keySet();
        
        for (String oppId : oppIdBusinessUnitMap.keySet()){
        
            String businessUnit = oppIdBusinessUnitMap.get(oppId).get('businessUnit');
            String recordType = oppIdBusinessUnitMap.get(oppId).get('recordType');
            String sector = oppIdBusinessUnitMap.get(oppId).get('sector');

            if(!recordTypeSet.contains(recordType)) recordTypeSet.add(recordType);

            if(!sectorNames.contains(sector) && sector != null) sectorNames.add(sector);

            if(!businessUnitSet.contains(businessUnit)){
                
                businessUnitSet.add(businessUnit);

                String fieldSetName = (businessUnit+'_'+recordType).replace(' ','_')+'_Q';


                Map<String,List<Schema.FieldSetMember>> fieldSetMap;

                Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
                Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Opportunity');
                Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
                
                Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

                if(fieldSetObj == null) return;
                
                List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();

                fieldSetMemberMap.put(businessUnit+recordType, fieldSetMemberList);
                    
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
        
        System.debug('recordTypeSet: '+recordTypeSet);
        System.debug('businessUnitSet: '+businessUnitSet);

        String weightsQuery = '(SELECT Id, Multiplier__c, Field_API_Name__c';
        System.debug(sectorNames);
        for (String sector : sectorNames){
            System.debug(sector);
            weightsQuery+=', '+sector.replace(' ','_')+'__c';
        }

        weightsQuery+=' FROM Opportunity_Scoring_Weights__r)';

        soqlQuery = 'SELECT Id, Record_Type__c, Business_Unit__c, Value_1_Score__c, Value_2_Score__c, Value_3_Score__c, Value_4_Score__c, Value_5_Score__c, Matching_Threshold__c, Questions_Required__c , '+weightsQuery+' FROM Opportunity_Matching_Threshold__mdt WHERE Business_Unit__c IN :businessUnitSet AND Record_Type__c IN :recordTypeSet';

        System.debug('CMDT SOQL Query: '+soqlQuery);
        
        List<Opportunity_Matching_Threshold__mdt> valueScoringList = (List<Opportunity_Matching_Threshold__mdt>)Database.query(soqlQuery);

        Map<String, Opportunity_Matching_Threshold__mdt> valueScoringMap = new Map<String,Opportunity_Matching_Threshold__mdt>();

        for (Opportunity_Matching_Threshold__mdt valueScoring : valueScoringList){
            valueScoringMap.put(valueScoring.Business_Unit__c+valueScoring.Record_Type__c, valueScoring);
        }

        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Opportunity');
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();


        for (String oppId : oppIdBusinessUnitMap.keySet()){

            Opportunity opp = oppMap.get(oppId);
            

            Map<String,List<String>> fieldPickListValueMap = new Map<String,List<String>>();
            String businessUnit = oppIdBusinessUnitMap.get(oppId).get('businessUnit');
            String recordType = oppIdBusinessUnitMap.get(oppId).get('recordType');

            Opportunity_Matching_Threshold__mdt valueScoring = valueScoringMap.get(businessUnit+recordType);

            if(valueScoring == null) return;

            Double oppScore = 0;
            Integer fieldsNotBlank = 0;

            String positiveScores = '<ul style="color:green">';
            String negativeScores = '<ul style="color:red">';

            List<Schema.FieldSetMember> fieldSetMemberList = fieldSetMemberMap.get(opp.Buildcorp_Business_Unit__c+opp.Record_Type_Name__c);
            
            for(Schema.FieldSetMember field : fieldSetMemberList){
                String fieldName = field.getFieldPath();
                String fieldLabel = field.getLabel();

                System.debug('Field: '+fieldName);

                if(opp.get(fieldName) == null) {
                    System.debug('Field is null - skipping... (Non-null field counter = '+fieldsNotBlank+')');
                    continue;
                }
                
                fieldsNotBlank++;
                System.debug('Incrementing non-null field counter - currently '+fieldsNotBlank);
            
                List<String> pickListValuesList= new List<String>();

                String oppFieldValue = (String) opp.get(fieldName);

                System.debug('Opp Field Value is: '+oppFieldValue);

                Integer oppFieldValueIndex;
            
                Schema.DescribeFieldResult fieldResult = DescribeSObjectResultObj.fields.getMap().get(fieldName).getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

                for( Integer i = 1; i <= ple.size(); i++){

                    String valueLabel = ple[i-1].getValue();
                    
                    System.debug('Index: '+i);
                    System.debug('Value Label: '+valueLabel);
                    System.debug('Opp Field Value: '+oppFieldValue);
                    

                    if(oppFieldValue == valueLabel) {

                        //System.debug('Opp field value matches picklist label: '+valueLabel);
                        //System.debug('Index is '+i);

                        oppFieldValueIndex = i;
                        break;
                    }
                }    
                
                //System.debug('oppFieldValueIndex: '+oppFieldValueIndex);

                if(oppFieldValueIndex == 5) negativeScores+='<li>'+fieldLabel+'</li>';
                else if (oppFieldValueIndex == 1) positiveScores+='<li>'+fieldLabel+'</li>';
                
                Double valueScore = Double.valueOf(valueScoring.get('Value_'+oppFieldValueIndex+'_Score__c'));


                Double multiplier;
                String sector = oppIdBusinessUnitMap.get(oppId).get('sector');

                for(Opportunity_Scoring_Weight__mdt scoringWeight : valueScoring.Opportunity_Scoring_Weights__r){
                    if(scoringWeight.Field_API_Name__c == fieldName){
                        if(!sectorNames.isEmpty() && opp.Sector__c != null){
                            String sectorName = sector.replace(' ','_')+'__c';
                            multiplier = Double.valueOf(scoringWeight.get(sectorName));
                        }
                        else{
                            //multiplier = Integer.valueOf(scoringWeight.Multiplier__c.replace('x',''));
                            multiplier = Double.valueOf(scoringWeight.Multiplier__c);
                            
                        }
                        System.debug('Multiplier: '+multiplier);
                        break;
                    }
                }

                valueScore *= multiplier;

                

                System.debug('Adding '+valueScore+' to '+oppScore+' to get '+(oppScore+valueScore));

                oppScore+=valueScore;

            }

            System.debug(fieldsNotBlank+' fields filled in, out of the required '+valueScoring.Questions_Required__c);

            if(negativeScores == '<ul style="color:red">') negativeScores = null;
            if(positiveScores == '<ul style="color:green">') positiveScores = null;

            opp.Business_Unit_Assessment_Positive_Scores__c = positiveScores;
            opp.Business_Unit_Assessment_Negative_Scores__c = negativeScores;

            if(fieldsNotBlank >= valueScoring.Questions_Required__c) {
                System.debug('Enough fields are filled in; setting score to '+oppScore);
                opp.Business_Unit_Score__c = oppScore;
            }
            else 
            {
                System.debug('Not enough fields filled in; setting score to null.');
                opp.Business_Unit_Score__c = null;
            }
            
            oppsToUpdate.add(opp);
        }

        update oppsToUpdate;

    }
    @AuraEnabled
    public static Integer CalculateOpportunityScoreWeighted(String businessUnitName, String recordTypeName, List<String> sectorNames, Map<String,String> weightingList){

        try{
        
            System.debug('Method launched with following parameters:');
            System.debug('businessUnitName: '+businessUnitName);
            System.debug('recordTypeName: '+recordTypeName);
            System.debug('sectorNames: '+sectorNames);
            System.debug('weightingList: '+weightingList);
            List<Opportunity> oppsToUpdate = new List<Opportunity>();

            String soqlQuery = 'SELECT Id, Buildcorp_Business_Unit__c, Sector__c, Name';
                    
            String fieldSetName = (businessUnitName+'_'+recordTypeName).replace(' ','_')+'_Q';

            Map<String,List<Schema.FieldSetMember>> fieldSetMap;

            Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Opportunity');
            Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
            
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

            if(fieldSetObj == null) return 0;
            
            List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
            Set<String> matchingFieldSet = new Set<String>();

            for(Schema.FieldSetMember matchingField : fieldSetMemberList){

                if(!matchingFieldSet.contains(matchingField.getFieldPath())) {
                    soqlQuery+=', '+matchingField.getFieldPath();
                    matchingFieldSet.add(matchingField.getFieldPath());
                }
            }
                
            System.debug(sectorNames);
            if(!sectorNames.isEmpty()) soqlQuery+=' FROM Opportunity WHERE Sector__c IN :sectorNames AND Buildcorp_Business_Unit__c = :businessUnitName AND RecordType.DeveloperName = :recordTypeName';
            else soqlQuery+=' FROM Opportunity WHERE Buildcorp_Business_Unit__c = :businessUnitName AND RecordType.DeveloperName = :recordTypeName';
            System.debug('Opportunity SOQL Query: '+soqlQuery);

            Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>((List<Opportunity>)Database.query(soqlQuery));

            System.debug('Opps retrieved: '+oppMap);

            String weightsQuery = '(SELECT Id, Multiplier__c, Field_API_Name__c';
            for (String sector : sectorNames){
                weightsQuery+=', '+sector.replace(' ','_')+'__c';
            }

            weightsQuery+=' FROM Opportunity_Scoring_Weights__r)';

            soqlQuery = 'SELECT Id, Record_Type__c, Business_Unit__c, Value_1_Score__c, Value_2_Score__c, Value_3_Score__c, Value_4_Score__c, Value_5_Score__c, Matching_Threshold__c, Questions_Required__c , '+weightsQuery+' FROM Opportunity_Matching_Threshold__mdt WHERE Business_Unit__c = :businessUnitName AND Record_Type__c = :recordTypeName';

            System.debug('CMDT SOQL Query: '+soqlQuery);
            
            List<Opportunity_Matching_Threshold__mdt> valueScoringList = (List<Opportunity_Matching_Threshold__mdt>)Database.query(soqlQuery);

            if(valueScoringList.isEmpty()) throw new AuraHandledException('No Matching CMDT Records found for business unit: '+businessUnitName+' and record type: '+recordTypeName);

            Opportunity_Matching_Threshold__mdt valueScoring = valueScoringList[0];


            for (Opportunity opp : oppMap.values()){

                Map<String,List<String>> fieldPickListValueMap = new Map<String,List<String>>();

                if(valueScoring == null) return 0;

                Double oppScore = 0;
                Integer fieldsNotBlank = 0;

                String positiveScores = '<ul style="color:green">';
                String negativeScores = '<ul style="color:red">';

                
                for(Schema.FieldSetMember field : fieldSetMemberList){
                    String fieldName = field.getFieldPath();
                    String fieldLabel = field.getLabel();

                    System.debug('Field: '+fieldName);

                    if(opp.get(fieldName) == null) continue;
                    
                    fieldsNotBlank++;
                
                    List<String> pickListValuesList= new List<String>();

                    String oppFieldValue = (String) opp.get(fieldName);

                    System.debug('Opp Field Value is: '+oppFieldValue);

                    Integer oppFieldValueIndex;
                
                    Schema.DescribeFieldResult fieldResult = DescribeSObjectResultObj.fields.getMap().get(fieldName).getDescribe();
                    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

                    for( Integer i = 1; i <= ple.size(); i++){

                        String valueLabel = ple[i-1].getValue();
                        
                        System.debug('Index: '+i);
                        System.debug('Value Label: '+valueLabel);
                        System.debug('Opp Field Value: '+oppFieldValue);
                        

                        if(oppFieldValue == valueLabel) {

                            System.debug('Opp field value matches picklist label: '+valueLabel);
                            System.debug('Index is '+i);

                            oppFieldValueIndex = i;
                            break;
                        }
                    }    
                    
                    System.debug('oppFieldValueIndex: '+oppFieldValueIndex);

                    if(oppFieldValueIndex == 5) negativeScores+='<li>'+fieldLabel+'</li>';
                    else if (oppFieldValueIndex == 1) positiveScores+='<li>'+fieldLabel+'</li>';
                    
                    Double valueScore = Double.valueOf(valueScoring.get('Value_'+oppFieldValueIndex+'_Score__c'));

                    System.debug('Initial value score: '+valueScore);
                    Double multiplier;
                   
                    multiplier = Double.valueOf(weightingList.get(fieldName));

                    /*for(Opportunity_Scoring_Weight__mdt scoringWeight : valueScoring.Opportunity_Scoring_Weights__r){
                        if(scoringWeight.Field_API_Name__c == fieldName){
                            if(!sectorNames.isEmpty() && opp.Sector__c != null){
                                String sectorName = opp.Sector__c.replace(' ','_')+'__c';
                                multiplier = Double.valueOf(scoringWeight.get(sectorName));
                            }
                            else{
                                //multiplier = Integer.valueOf(scoringWeight.Multiplier__c.replace('x',''));
                                multiplier = Double.valueOf(scoringWeight.Multiplier__c);
                                
                            }
                            System.debug('Multiplier: '+multiplier);
                            break;
                        }
                    }*/
                    System.debug('Multiplier: '+multiplier);

                    valueScore *= multiplier;
                    System.debug('Weighted Value Score: '+valueScore);
                    System.debug('Adding '+valueScore+' to '+oppScore+' to get '+(oppScore+valueScore));

                    oppScore+=valueScore;

                }

				System.debug(fieldsNotBlank+' fields filled in, out of the required '+valueScoring.Questions_Required__c);

                if(negativeScores == '<ul style="color:red">') negativeScores = null;
                if(positiveScores == '<ul style="color:green">') positiveScores = null;

                opp.Business_Unit_Assessment_Positive_Scores__c = positiveScores;
                opp.Business_Unit_Assessment_Negative_Scores__c = negativeScores;

                if(fieldsNotBlank >= valueScoring.Questions_Required__c) {
                    System.debug('Enough fields are filled in; setting score to '+oppScore);
                    opp.Business_Unit_Score__c = oppScore;
                }
                else 
                {
                    System.debug('Not enough fields filled in; setting score to null.');
                    opp.Business_Unit_Score__c = null;
                }
                
                oppsToUpdate.add(opp);
                
            }

            System.debug('Opps to Update: ');
            for(Opportunity opp :oppsToUpdate){
                System.debug(opp);
            }
            update oppsToUpdate;
            return oppsToUpdate.size();
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }

    }

    
}