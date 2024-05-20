public without sharing class opportunityScoringRecalcController {

    @AuraEnabled (cacheable=true)
    public static string getUserBusinessUnit(String userID){
        try {

            User u = [SELECT Id, Business_Unit__c FROM User WHERE Id = :userID][0];
            return u.Business_Unit__c;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled (cacheable=true)
    public static List<Map<String,String>> getPicklistValues(String objectName, String picklistName){
        try {
            Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectName) ;
            Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
            Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
            Schema.DescribeFieldResult fieldResult = fields.get(picklistName).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

            List<Map<String,String>> picklistValues = new List<Map<String,String>>();
            for( Schema.PicklistEntry pickListVal : ple){
                System.debug(pickListVal.getLabel() +' '+pickListVal.getValue());
                picklistValues.add(new Map<String,String>{'label' => picklistVal.getLabel(), 'value' => picklistVal.getValue()});
            }

            if(!picklistValues.isEmpty()) return picklistValues;
            else return null;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled (cacheable = false)
    public static Map<String,List<Map<String,Object>>> getFieldStringListFromFieldSet(String businessUnitName, String recordTypeName, List<String> sectorList){
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Opportunity');
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

        String fieldSetName = (businessUnitName+'_'+recordTypeName).replace(' ','_').replace('_/_','_')+'_Q';

		System.debug('Field Set: '+fieldSetName);
        system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName));

        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
		
        if(fieldSetObj == null) {
            throw new AuraHandledException('No Field Set found with name '+fieldSetName);
        }
        Map<String,List<Map<String,Object>>> fieldNameMap = new Map<String,List<Map<String,Object>>>();
        
        List<Schema.FieldSetMember> fieldSetMembers = fieldSetObj.getFields();

        System.debug('Getting all Opp Matching CMDT where Business_Unit__c = '+businessUnitName+' and record type name = '+recordTypeName);

        List<Opportunity_Matching_Threshold__mdt> weightingHeaders = [SELECT Id FROM Opportunity_Matching_Threshold__mdt WHERE Business_Unit__c = :businessUnitName AND Record_Type__c = :recordTypeName];

        Id weightingHeader;

        if(!weightingHeaders.isEmpty()){
            weightingHeader = weightingHeaders[0].Id;
            System.debug('Weighting header: '+weightingHeader);
        }
        else{
            throw new AuraHandledException('CMDT not found for business unit '+businessUnitName);
        }
        String soqlQuery = 'SELECT Id, Field_API_Name__c, Multiplier__c';
        if(!sectorList.isEmpty()){
            for (String sector : sectorList){
                soqlQuery+=', '+sector.replace(' ','_')+'__c';
            }
        }
        soqlQuery+=' FROM Opportunity_Scoring_Weight__mdt WHERE Opportunity_Matching_Scoring__c = :weightingHeader';
        System.debug('CMDT Query: '+soqlQuery);

        List<Opportunity_Scoring_Weight__mdt> weightingFields = (List<Opportunity_Scoring_Weight__mdt>)Database.query(soqlQuery);

        System.debug('Returned CMDT: '+weightingFields);
        //List<Opportunity_Scoring_Weight__mdt> weightingFields = [SELECT Id, Field_API_Name__c, Multiplier__c FROM Opportunity_Scoring_Weight__mdt WHERE Record_Type__c = :recordTypeName];
        Map<String,Opportunity_Scoring_Weight__mdt> fieldWeightMap = new Map<String,Opportunity_Scoring_Weight__mdt>();
        if(weightingFields.isEmpty()){
            throw new AuraHandledException('Weighting Field CMDT not found for record type '+recordTypeName);
        }
        else{
            for(Opportunity_Scoring_Weight__mdt weightingField : weightingFields){
                System.debug('Putting '+weightingField+' at key '+weightingField.Field_API_Name__c);
                fieldWeightMap.put(weightingField.Field_API_Name__c, weightingField);
            }
        }

        for (Schema.FieldSetMember fieldSetMember : fieldSetMembers){
            String fieldName = fieldSetMember.getFieldPath();
            String fieldLabel = fieldSetMember.getLabel();
            System.debug('Field: '+fieldName+'. Label: '+fieldLabel);
            Schema.sObjectField field = fieldSetMember.getSObjectField();
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            String values = '';
            for(Schema.PicklistEntry picklistValue : picklistValues){
                values+=picklistValue.getLabel()+', ';
            }
            values = values.left(values.length()-2);
            System.debug('Values: '+values);
            Opportunity_Scoring_Weight__mdt fieldWeight = fieldWeightMap.get(fieldName);
            Map<String,Object> weightMap = new Map<String,Object>{'label'=>fieldLabel,'values' => values,'multiplier' => fieldWeight.Multiplier__c,'id' => fieldWeight.Id};
            List<String> sectorMap = new List<String>();
            //Map<String,String> sectorMap = new Map<String,String>();
            if(!sectorList.isEmpty()){
                for (Integer i = 0; i < sectorList.size(); i++){
                    String sector = sectorList[i];
                    //sectorMap.put(String.valueOf(i),(String)fieldWeight.get(sector.replace(' ','_')+'__c'));
                    sectorMap.add((String)fieldWeight.get(sector.replace(' ','_')+'__c'));
                }
                weightMap.put('Multipliers',sectorMap);
            }
            fieldNameMap.put(fieldName,new List<Map<String,Object>>{weightMap});
        }

        System.debug(fieldNameMap);

        return fieldNameMap; 
    }

    @AuraEnabled (cacheable=true)
    public static List<String> getMarketOptions(String businessUnit){
        try {
            Schema.DescribeFieldResult depend = Opportunity.Sector__c.getDescribe();
            Schema.sObjectField controlToken = depend.getController();
            Schema.DescribeFieldResult control = controlToken.getDescribe();
            List<Schema.PicklistEntry> controlEntries =
            (   control.getType() == Schema.DisplayType.Boolean
            ?   null
            :   control.getPicklistValues()
            );
         
            String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
            List<String> dependentPicklistValues = new List<String>();
            for ( Schema.PicklistEntry entry : depend.getPicklistValues() ) if ( entry.isActive() )
            {
                List<String> base64chars =
                    String.valueOf
                    (   ((Map<String,Object>) JSON.deserializeUntyped( JSON.serialize( entry ) )).get( 'validFor' )
                    ).split( '' );
                for ( Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++ )
                {
                    Object controlValue =
                    (   controlEntries == null
                    ?   (Object) (index == 1)
                    :   (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getValue() : null)
                    );
                    System.debug(controlValue);
                    Integer bitIndex = index / 6, bitShift = 5 - Math.mod( index, 6 );
                    if  (   controlValue == null
                        ||  (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0
                        ) continue;
                    if(controlValue == businessUnit){
                        dependentPicklistValues.add( entry.getLabel() );
                    }
                }
            }
        System.debug(dependentPicklistValues);
        return dependentPicklistValues;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled (cacheable=false)
    public static Integer getNumberOfOppsToUpdate(String businessUnit, String recordTypeName, List<String> marketValues){
        try {
            Integer oppAmount;
            if(!marketValues.isEmpty()){
                oppAmount = Database.countQuery('SELECT count() FROM Opportunity WHERE Buildcorp_Business_Unit__c = :businessUnit AND RecordType.Name = :recordTypeName AND Sector__c IN :marketValues');
            }
            else oppAmount = Database.countQuery('SELECT count() FROM Opportunity WHERE Buildcorp_Business_Unit__c = :businessUnit AND RecordType.Name = :recordTypeName');
            return oppAmount;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled (cacheable=true)
    public static string updateWeightings(Map<String,String> weightings, List<String> sectorList){
        try {
            System.debug(weightings);
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            System.debug(weightings.KeySet());
            List<Opportunity_Scoring_Weight__mdt> weightingList = [SELECT Id, DeveloperName, Multiplier__c FROM Opportunity_Scoring_Weight__mdt WHERE Id IN :weightings.keySet()];
            System.debug('CMDT records retrieved: ');
            System.debug(weightingList);
            for(Opportunity_Scoring_Weight__mdt weighting : weightingList){
                List<Metadata.Metadata> cmdtList = Metadata.Operations.retrieve(Metadata.MetadataType.CustomMetadata, new List<String>{'Opportunity_Scoring_Weight.'+weighting.DeveloperName});
                if(cmdtList.isEmpty()) throw new AuraHandledException('No Custom Metadata found with name: Opportunity_Scoring_Weight.'+weighting.DeveloperName);
                Metadata.CustomMetadata cmdt = (Metadata.CustomMetadata) cmdtList[0];
                //Metadata.CustomMetadata cmdt = new Metadata.CustomMetadata();
                cmdt.fullName = 'Opportunity_Scoring_Weight.'+weighting.DeveloperName;
                cmdt.label = weighting.DeveloperName;
                Metadata.CustomMetadataValue multiplierField = new Metadata.CustomMetadataValue();
                multiplierField.field = 'Multiplier__c'; 
                multiplierField.value = weightings.get(weighting.Id);
                cmdt.values.add(multiplierField);

                if(!sectorList.isEmpty()){
                    for (String sector: sectorList){
                        Metadata.CustomMetadataValue sectorMultiplier = new Metadata.CustomMetadataValue();
                        sectorMultiplier.field = sector.replace(' ','_')+'__c'; 
                        sectorMultiplier.value = weightings.get(weighting.Id);
                        cmdt.values.add(sectorMultiplier); 
                    }
                }
                else{
                    Schema.DescribeFieldResult fieldDescribe = Opportunity.Sector__c.getDescribe();
                    List<Schema.PicklistEntry> sectorPicklist = fieldDescribe.getPicklistValues();
                    for(Schema.PicklistEntry sector : sectorPicklist){
                        Metadata.CustomMetadataValue sectorMultiplier = new Metadata.CustomMetadataValue();
                        sectorMultiplier.field = sector.getLabel().replace(' ','_')+'__c'; 
                        sectorMultiplier.value = weightings.get(weighting.Id);
                        cmdt.values.add(sectorMultiplier); 
                    }
                }
                
                System.debug('Adding cmdt: '+cmdt);
                mdContainer.addMetadata(cmdt);
            }

            System.debug('mdContainer: '+mdContainer);
            
            if(mdContainer.getMetadata().size() > 0){            
                Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, null);
                return 'Success';
            }
            else return 'Nothing Updated';
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}