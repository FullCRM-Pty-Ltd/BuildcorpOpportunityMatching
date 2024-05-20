@IsTest
public without sharing class opportunityScoringRecalcTest {
    
    @TestSetup
    static void testSetup(){
        User usr = new User();
        usr.ProfileId = [SELECT Id FROM Profile WHERE Name = 'BC System Administrator' limit 1].Id;                   
        usr.LastName = 'Test';
        usr.Business_Unit__c = 'Interiors NSW';
        usr.Email = 'test@test.com';
        usr.Username = 'test@test.com' + System.currentTimeMillis();
        usr.CompanyName = 'Salesforce';
        usr.Title = 'Title';
        usr.Alias = 'Roger';
        usr.TimeZoneSidKey = 'America/Los_Angeles';
        usr.EmailEncodingKey = 'UTF-8';
        usr.LanguageLocaleKey = 'en_US';
        usr.LocaleSidKey = 'en_US';
        
        insert usr;
        
        User usr2 = new User();
        usr2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'BC System Administrator' limit 1].Id;                   
        usr2.LastName = 'Test2';
        usr2.Email = 'test@test.com';
        usr2.Username = 'test2@test.com' + System.currentTimeMillis();
        usr2.CompanyName = 'Salesforce';
        usr2.Title = 'Title';
        usr2.Alias = 'Rog2';
        usr2.TimeZoneSidKey = 'America/Los_Angeles';
        usr2.EmailEncodingKey = 'UTF-8';
        usr2.LanguageLocaleKey = 'en_US';
        usr2.LocaleSidKey = 'en_US';
        
        insert usr2;
        
        Id tenderRT = [SELECT Id FROM RecordType WHERE Name = 'Tender' LIMIT 1].Id;
        
        Opportunity opp = new Opportunity(
        	Name = 'Test Opp',
            RecordTypeId = tenderRT,
            StageName = 'Speculative',
            Buildcorp_Business_Unit__c = 'Interiors NSW',
            Sector__c = 'Commercial',
            CloseDate = System.today(),
            Services__c = 'Construction'
        );
        insert opp;
    }
    
    @IsTest
    static void testGetBusinessUnit(){
        User usr = [SELECT Id, Business_Unit__c FROM User WHERE LastName = 'Test' LIMIT 1];
        String businessUnit = opportunityScoringRecalcController.getUserBusinessUnit(usr.Id);
        System.assert(businessUnit == 'Interiors NSW');
        
        User usr2 = [SELECT Id, Business_Unit__c FROM User WHERE LastName = 'Test2' LIMIT 1];
        businessUnit = opportunityScoringRecalcController.getUserBusinessUnit(usr2.Id);
        System.assert(businessUnit == null);
        
    }
    
    @IsTest
    static void testGetFieldString(){
        Map<String,List<Map<String,String>>> result = opportunityScoringRecalcController.getFieldStringListFromFieldSet('Interiors NSW','Tender');
        System.assert(result != null);
        System.assert(result.size() > 0);
    }
    
    @IsTest
    static void testGetMarketOptions(){
        List<String> result = opportunityScoringRecalcController.getMarketOptions('Interiors NSW');
        System.assert(result != null);
        System.assert(result.size() > 0);
    }
    
    @IsTest
    static void testGetNumberOfOpps(){
        List<String> marketValues = new List<String>();
        Integer shouldBeOne = opportunityScoringRecalcController.getNumberOfOppsToUpdate('Interiors NSW','Tender',marketValues);
        Integer shouldBeZero = opportunityScoringRecalcController.getNumberOfOppsToUpdate('Interiors QLD','Tender',marketValues);
        marketValues.add('Commercial');
        Integer shouldBeOneAlso = opportunityScoringRecalcController.getNumberOfOppsToUpdate('Interiors NSW','Tender',marketValues);
        
        System.assertEquals(1,shouldBeOne);
        System.assertEquals(0,shouldBeZero);
        System.assertEquals(1,shouldBeOneAlso);
    }
    
    @IsTest
    static void testUpdateWeightings(){
        
        Opportunity_Scoring_Weight__mdt weighting = [SELECT Id FROM Opportunity_Scoring_Weight__mdt WHERE DeveloperName = 'Test_Do_Not_Delete'][0];
        Map<String,String> weightingMap = new Map<String,String>{weighting.Id => '1x'};
        String result = opportunityScoringRecalcController.updateWeightings(weightingMap);
        
        System.assertEquals('Success',result);
    }

}