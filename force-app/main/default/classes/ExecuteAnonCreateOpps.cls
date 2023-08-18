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

Map<String,List<Schema.FieldSetMember>> fieldSetMap;

Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Opportunity');
Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get('Interiors_NSW_Questionnaire');

List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
Map<String,List<String>> fieldPickListValueMap = new Map<String,List<String>>();

List<Opportunity> oppsToCreate = new List<Opportunity>();

for(Schema.FieldSetMember field : fieldSetMemberList){
    String fieldName = field.getFieldPath();

    List<String> pickListValuesList= new List<String>();

    Schema.DescribeFieldResult fieldResult = DescribeSObjectResultObj.fields.getMap().get(fieldName).getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for( Schema.PicklistEntry pickListVal : ple){
        pickListValuesList.add(pickListVal.getLabel());
    }     
    fieldPickListValueMap.put(fieldName,picklistValuesList);

}

Opportunity oppToMatch = new Opportunity(Name = 'Matching Test Opp', CloseDate = System.today(), StageName = 'Speculative', Services__c = 'Construction', Buildcorp_Business_Unit__c = 'Interiors NSW');
List<Account> accList = [SELECT Id, BillingStreet, ShippingStreet, Name FROM Account];

for (Integer i = 0; i < 30 ; i++){
    Opportunity opp = new Opportunity(Services__c = 'Construction',Buildcorp_Business_Unit__c = 'Interiors NSW');


    for(Schema.FieldSetMember field : fieldSetMemberList){


        List<String> picklistValueList = fieldPickListValueMap.get(field.getFieldPath());
        
        String randomPicklistValue = fieldPickListValueMap.get(field.getFieldPath())[generateRandomFromRange(0,picklistValueList.size()-1)];
        if(i == 0){
            oppToMatch.put(field.getFieldPath(),randomPicklistValue);
        }

        if(Math.mod(i, 2) == 0){
            opp.put(field.getFieldPath(), oppToMatch.get(field.getFieldPath()));
        }
        else{
            opp.put(field.getFieldPath(),randomPicklistValue);
        }
        
    }
    Integer randNumber = generateRandomFromRange(0,accList.size()-1);
    opp.AccountId = accList[randNumber].Id;
    String streetname;
    if(accList[randNumber].BillingStreet != null) streetname = accList[randNumber].BillingStreet;
    else streetname = accList[randNumber].ShippingStreet; 
    opp.Name = accList[randNumber].Name+' - '+streetname;
    opp.Amount = randNumber*100;
    Integer randDay = generateRandomFromRange(1,28);
    Integer randMonth = generateRandomFromRange(1,12);
    Integer randYear = generateRandomFromRange(2019,2024);
    Date newCloseDate = Date.newInstance(randYear, randMonth, randDay);
    opp.CloseDate = newCloseDate;
    Integer randNumber2 = generateRandomFromRange(1,4);
    switch on (randNumber2){
        when 1{
            opp.StageName = 'Speculative';
        }
        when 2{
            opp.StageName = 'Potential';
        }
        when 3{
            opp.StageName = 'Tender';
        }
        when 4{
            opp.StageName = 'Complete';
            opp.Lost_To__c = accList[0].Id;
        }
    }
    if (i == 0) oppsToCreate.add(oppToMatch);
    System.debug(opp);
    oppsToCreate.add(opp);
}

System.debug(oppsToCreate);
insert oppsToCreate;