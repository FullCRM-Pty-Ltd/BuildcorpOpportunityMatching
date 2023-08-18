trigger OpportunityScoringCalculatorTrigger on Opportunity (after insert, after update) {


    Map<String,String> oppIdBusinessUnitMap = new Map<String,String>();
    Map<String,List<Schema.FieldSetMember>> fieldSetMemberMap = new Map<String,List<Schema.FieldSetMember>>();
    
    for (Opportunity opp : Trigger.new){

        if(opp.Buildcorp_Business_Unit__c == null) continue;

        String businessUnit = opp.Buildcorp_Business_Unit__c;

        String fieldSetName = businessUnit.replace(' ','_')+'_Questionnaire';
        
        System.debug('Getting matching fields from '+fieldSetName+' fieldset.');
        
        List<Schema.FieldSetMember> matchingFieldList;
        if(!fieldSetMemberMap.keySet().contains(businessUnit)){
            matchingFieldList = OpportunityMatchListController.GetFieldsFromFieldSet('Opportunity', fieldSetName);
            fieldSetMemberMap.put(businessUnit,matchingFieldList);
        }
        else{
            matchingFieldList = fieldSetMemberMap.get(businessUnit);
        }

        for(Schema.FieldSetMember matchingField : matchingFieldList){
            String matchingFieldPath = matchingField.getFieldPath();

            if(Trigger.isUpdate){
                Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
                if(oldOpp.get(matchingFieldPath) != opp.get(matchingFieldPath)) {
                    oppIdBusinessUnitMap.put(opp.Id, opp.Buildcorp_Business_Unit__c);
                    break;
                }
            }
            else{
                if(opp.get(matchingFieldPath) != null){
                    oppIdBusinessUnitMap.put(opp.Id, opp.Buildcorp_Business_Unit__c);
                    break;
                }
            }
            
        }

        if (!oppIdBusinessUnitMap.isEmpty()) OpportunityScoringCalculator.CalculateOpportunityScore(oppIdBusinessUnitMap);
    }

}