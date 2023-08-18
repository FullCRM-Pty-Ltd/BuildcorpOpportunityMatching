@IsTest
public with sharing class OpportunityMatchListControllerTest {

    //Map where Key = the business unit name and Value = the list of fields from its corresponding Questionnaire Field Set
    Map<String,List<Schema.FieldSetMember>> fieldSetMap;

    @TestSetup
    static void TestSetup(){
        
        List<String> businessUnitList = GetPickListValuesFromField('Opportunity','Buildcorp_Business_Unit__c');
        System.debug('Retrieved Business Units: '+businessUnitList);

        Map<String,List<Schema.FieldSetMember>> tempFieldSetMap = new Map<String,List<Schema.FieldSetMember>>();
        
        List<String> newBusinessUnitList = new List<String>();

        for (String businessUnit : businessUnitList){

            String fieldSetName = businessUnit.replace(' ','_')+'_Questionnaire';

            List<Schema.FieldSetMember> fieldSetMemberList = GetFieldsFromFieldSet('Opportunity', fieldSetName);

            if(!fieldSetMemberList.isEmpty()){ 
                System.debug(businessUnit+': '+fieldSetMemberList);
                tempFieldSetMap.put(businessUnit, fieldSetMemberList);
                newBusinessUnitList.add(businessUnit);
            }
            
        }
        
        businessUnitList = newBusinessUnitList;

        System.debug(tempFieldSetMap);

        Map<String,List<String>> fieldPickListValueMap = new Map<String,List<String>>();

        for(String businessUnit : tempFieldSetMap.keySet()){
            for (Schema.fieldSetMember field : tempFieldSetMap.get(businessUnit)){
                fieldPickListValueMap.put(field.getFieldPath(), GetPickListValuesFromField('Opportunity',field.getFieldPath()));
            }
        }

        System.debug(fieldPickListValueMap);


        List<Opportunity> oppsToCreate = new List<Opportunity>();

        for(String businessUnit : businessUnitList){

            System.debug('Business Unit: '+businessUnit);

            if(tempFieldSetMap.containsKey(businessUnit)){

                Opportunity oppToMatch = new Opportunity(Name = 'Match - '+businessUnit, CloseDate = System.today(), StageName = 'Speculative', Services__c = 'Construction', Buildcorp_Business_Unit__c = businessUnit);

                for(Schema.FieldSetMember field : tempFieldSetMap.get(businessUnit)){

                    //System.debug('Field: '+field.getFieldPath());

                    List<String> picklistValueList = fieldPickListValueMap.get(field.getFieldPath());

                    //System.debug('Picklist Values: '+picklistValueList);

                    Integer randomNumber = generateRandomFromRange(0,picklistValueList.size()-1);

                    String randomPicklistValue = fieldPickListValueMap.get(field.getFieldPath())[randomNumber];

                    //System.debug('Value Chosen: '+randomPicklistValue);

                    oppToMatch.put(field.getFieldPath(),randomPicklistValue);
                }

                oppsToCreate.add(oppToMatch);

                for (Integer i = 0; i < 6 ; i++){
                    Opportunity opp = new Opportunity(Name = businessUnit+' Test Opp '+i, CloseDate = System.today(), StageName = 'Speculative', Services__c = 'Construction',Buildcorp_Business_Unit__c = businessUnit);
					

                    for(Schema.FieldSetMember field : tempFieldSetMap.get(businessUnit)){

                        //System.debug('Field: '+field.getFieldPath());
    
                        List<String> picklistValueList = fieldPickListValueMap.get(field.getFieldPath());
    
                        //System.debug('Picklist Values: '+picklistValueList);
                        //
                        
                        if(Math.mod(i, 2) == 0){
                        	opp.put(field.getFieldPath(), oppToMatch.get(field.getFieldPath()));
                    	}
    					
                        else{
                            Integer randomNumber = generateRandomFromRange(0,picklistValueList.size()-1);
        
                            String randomPicklistValue = fieldPickListValueMap.get(field.getFieldPath())[randomNumber];
        
                            //System.debug('Value Chosen: '+randomPicklistValue);
                            
                            opp.put(field.getFieldPath(),randomPicklistValue);
                        }
                    }

                    oppsToCreate.add(opp);

                }
            }

            
        }
        System.debug(oppsToCreate);
		insert oppsToCreate;
        
        
        //fieldSetMap = tempFieldSetMap;

    }

    @isTest
    static void RetrieveMatchingOpportunitiesTest() {

        List<Opportunity> mainOpps = [SELECT Id, Buildcorp_Business_Unit__c FROM Opportunity WHERE Name LIKE 'Match%'];
        
        for(Opportunity mainOpp : mainOpps){
            List<Opportunity> matchedOpportunities = OpportunityMatchListController.RetrieveMatchingOpportunities(mainOpp.Id);
            
            System.assert(matchedOpportunities.size() >= 3);
            
        }
        
        

    }

    @isTest
    static void GetColumnsFromFieldSetTest(){

        List<Opportunity> mainOpps = [SELECT Id, Buildcorp_Business_Unit__c FROM Opportunity WHERE Name LIKE 'Match%'];

        for(Opportunity mainOpp : mainOpps){

            String fieldSetName = mainOpp.Buildcorp_Business_Unit__c.replace(' ','_')+'_Columns';

            List<Schema.FieldSetMember> fieldSetMemberList = GetFieldsFromFieldSet('Opportunity', fieldSetName);

            List<Map<String,Object>> columnMap = OpportunityMatchListController.GetColumnsFromFieldSet(mainOpp.Id);

            System.debug('fieldSetMemberList: '+fieldSetMemberList);
            SYstem.debug('ColumnMap: '+columnMap);

            System.assertEquals(fieldSetMemberList.size()+2,columnMap.size(),'Column Retrieval Failed: '+(fieldSetMemberList.size()+2)+' columns expected, '+columnMap.size()+' columns retrieved.');


        }
    }

    @isTest
    static void NoOpportunitiesMatchingTest(){
        List<Opportunity> allOpps = [SELECT Id FROM Opportunity WHERE NOT( Name LIKE 'Match%' )];
        delete allOpps;

        List<Opportunity> mainOpps = [SELECT Id, Buildcorp_Business_Unit__c FROM Opportunity WHERE Name LIKE 'Match%'];
        
        Boolean error = false;

        try{
            for(Opportunity mainOpp : mainOpps){
                OpportunityMatchListController.RetrieveMatchingOpportunities(mainOpp.Id);            
            }
        }
        catch(Exception e){
            error = true;
        }

        System.assert(error);

    }

    @isTest
    static void NoMatchingThresholdCMDTTest(){
        List<Opportunity> mainOpps = [SELECT Id, Buildcorp_Business_Unit__c FROM Opportunity];
        
        for(Opportunity mainOpp : mainOpps){
            mainOpp.Buildcorp_Business_Unit__c = null;            
        }

        update mainOpps;
        
        Boolean error = false;

        try{
            for(Opportunity mainOpp : mainOpps){
                OpportunityMatchListController.RetrieveMatchingOpportunities(mainOpp.Id);            
            }
        }

        catch (Exception e){
            error = true;
        }

        System.assert(error);
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

    //method to return random value between 2 numbers
    public static Integer generateRandomFromRange(integer startNum, integer endNum){
        Integer returnValue;
        //Logic- first we will generate random boolean value which will decide if we want to
        //add the random number from startNum or will subtract random number from endNum
        Integer randomNumber = Integer.valueof((math.random() * 10));
        boolean addSubFlag= math.mod(randomNumber,2) == 0 ? true : false;
        
        integer diffInRange = endNum-startNum;
        //Now find random number staring from 0 to diffInRange
        Integer randomNum = Math.mod(Math.round(Math.random()*diffInRange+1),diffInRange);
        
        //If addSubFlag is true, we will add random number generated between 0 and diffInRange from start number
        //else we will subtract random number from end number
                if(addSubFlag){
            if(diffInRange > 1)
                returnValue =startNum + randomNum;
            else
                returnValue =startNum;
        }else{
            if(diffInRange > 1)
                returnValue = endNum - randomNum;
            else
                returnValue =endNum;
        }
        return returnValue;
    }
}