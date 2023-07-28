@IsTest
public with sharing class OpportunityMatchListControllerTest {

    //Map where Key = the business unit name and Value = the list of fields from its corresponding Questionnaire Field Set
    Map<String,List<Schema.FieldSetMember>> fieldSetMap;

    @TestSetup
    static void TestSetup(){
        
        List<String> businessUnitList = GetPickListValuesFromField('Opportunity','Buildcorp_Business_Unit__c');
        System.debug('Retrieved Business Units: '+businessUnitList);

        Map<String,List<Schema.FieldSetMember>> tempFieldSetMap = new Map<String,List<Schema.FieldSetMember>>();

        for (String businessUnit : businessUnitList){

            //tempFieldSetMap.put(businessUnit,GetFieldsFromFieldSet(objectName, fieldSetName));
            
        }
        
        //fieldSetMap = tempFieldSetMap;

    }

    @isTest
    static void RetrieveMatchingOpportunitiesTest() {

        Opportunity oppToMatch = new Opportunity(Name = 'Match This One', CloseDate = System.today(), StageName = 'Speculative', Services__c = 'Construction');
        insert oppToMatch;
        
        

    }

    static List<String> GetPickListValuesFromField(String objectName, String fieldName){

        List<String> pickListValues = new List<String>();

        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        List<String> pickListValuesList= new List<String>();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

        Schema.DescribeFieldResult fieldResult = DescribeSObjectResultObj.fields.getMap().get(fieldName).getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.add(pickListVal.getLabel());
		}     
		return pickListValuesList;

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