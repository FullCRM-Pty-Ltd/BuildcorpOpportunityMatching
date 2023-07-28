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
    public static List<Opportunity> RetrieveMatchingOpportunities(Id opportunityToMatchId, String businessUnit){
        try {

                String fieldSetName = businessUnit.replace(' ','_')+'_Questionnaire';

                System.debug('Getting fields from '+fieldSetName+' fieldset.');

                List<Schema.FieldSetMember> matchingFieldList = GetFieldsFromFieldSet('Opportunity', fieldSetName);

                System.debug('Fields retrieved: '+matchingFieldList);

                for(Schema.FieldSetMember matchingField : matchingFieldList){
                    System.debug('Field Name: '+matchingField.getFieldPath());
                }
            
            

            return null;
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
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