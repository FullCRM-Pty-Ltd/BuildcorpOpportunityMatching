@isTest
public class RecalculateAccountTest {
    

    @isTest
    static void testInsert(){
        
        Database.DMLOptions opts = new Database.DMLOptions();

        opts.DuplicateRuleHeader.AllowSave = true;
        
         Account parent = new Account(Name = 'FCPAR1', dupcheck__dc3DisableDuplicateCheck__c= true);
        Database.insert(parent,opts);
        
        Account child1 = new Account(Name = 'FCCHLD1', ParentId = parent.Id, Top_10_Partner__c = 'Victoria;Euroline', Top_5_Target__c = 'Executive;Asset Solutions', dupcheck__dc3DisableDuplicateCheck__c= true);
        Database.insert(child1,opts);
        
        parent = [SELECT Id, Top_10_Partner__c, Top_5_Target__c FROM Account WHERE Id = :parent.Id][0];
        System.assertEquals('Victoria;Euroline',parent.Top_10_Partner__c);
        System.assertEquals('Executive;Asset Solutions',parent.Top_5_Target__c);
        
        Account child2 = new Account(Name = 'FCCHLD2', ParentId = parent.Id, Top_10_Partner__c = 'Victoria;Interiors NSW', Top_5_Target__c = 'Executive;Victoria', dupcheck__dc3DisableDuplicateCheck__c= true);
        Database.insert(child2,opts);
        
        parent = [SELECT Id, Top_10_Partner__c, Top_5_Target__c FROM Account WHERE Id = :parent.Id][0];
        System.assertEquals('Interiors NSW;Victoria;Euroline',parent.Top_10_Partner__c);
        System.assertEquals('Executive;Asset Solutions;Victoria',parent.Top_5_Target__c);
    }
    
    @isTest
    static void testUpdate(){
        
        Database.DMLOptions opts = new Database.DMLOptions();

        opts.DuplicateRuleHeader.AllowSave = true;
        
         Account parent = new Account(Name = 'FCPAR1', dupcheck__dc3DisableDuplicateCheck__c= true);
        Database.insert(parent,opts);
        
        Account child1 = new Account(Name = 'FCCHLD1', ParentId = parent.Id, Top_10_Partner__c = 'Victoria;Euroline', Top_5_Target__c = 'Executive;Asset Solutions', dupcheck__dc3DisableDuplicateCheck__c= true);
        Database.insert(child1,opts);
        
        parent = [SELECT Id, Top_10_Partner__c, Top_5_Target__c FROM Account WHERE Id = :parent.Id][0];
        System.assertEquals('Victoria;Euroline',parent.Top_10_Partner__c);
        System.assertEquals('Executive;Asset Solutions',parent.Top_5_Target__c);
        
		child1.Top_10_Partner__c = 'Victoria;Interiors NSW;Executive';
        child1.Top_5_Target__c = 'Executive;Victoria';
        Database.update(child1,opts);
        
        parent = [SELECT Id, Top_10_Partner__c, Top_5_Target__c FROM Account WHERE Id = :parent.Id][0];
        System.assertEquals('Executive;Interiors NSW;Victoria',parent.Top_10_Partner__c);
        System.assertEquals('Executive;Victoria',parent.Top_5_Target__c);
    }
    
    @isTest
    static void testParentAccUpdate(){
        
        Database.DMLOptions opts = new Database.DMLOptions();

        opts.DuplicateRuleHeader.AllowSave = true;
        
        Account parent = new Account(Name = 'FCPAR1', dupcheck__dc3DisableDuplicateCheck__c= true);
        Database.insert(parent,opts);
        
        Account parent2 = new Account(Name = 'FCPAR2', dupcheck__dc3DisableDuplicateCheck__c= true);
        Database.insert(parent2,opts);
        
        Account child1 = new Account(Name = 'FCCHLD1', ParentId = parent.Id, Top_10_Partner__c = 'Victoria;Euroline', Top_5_Target__c = 'Executive;Asset Solutions', dupcheck__dc3DisableDuplicateCheck__c= true);
        Database.insert(child1,opts);
        
        parent = [SELECT Id, Top_10_Partner__c, Top_5_Target__c FROM Account WHERE Id = :parent.Id][0];
        System.assertEquals('Victoria;Euroline',parent.Top_10_Partner__c);
        System.assertEquals('Executive;Asset Solutions',parent.Top_5_Target__c);
        
		child1.Top_10_Partner__c = 'Victoria;Interiors NSW;Executive';
        child1.Top_5_Target__c = 'Executive;Victoria';
        child1.ParentId = parent2.Id;
        Database.update(child1,opts);
        
        parent = [SELECT Id, Top_10_Partner__c, Top_5_Target__c FROM Account WHERE Id = :parent.Id][0];
        System.assertEquals(null,parent.Top_10_Partner__c);
        System.assertEquals(null,parent.Top_5_Target__c);
        
        parent2 = [SELECT Id, Top_10_Partner__c, Top_5_Target__c FROM Account WHERE Id = :parent2.Id][0];
        System.assertEquals('Executive;Interiors NSW;Victoria',parent2.Top_10_Partner__c);
        System.assertEquals('Executive;Victoria',parent2.Top_5_Target__c);
    }
    
    @isTest
    static void testDelete(){
        
        Database.DMLOptions opts = new Database.DMLOptions();

        opts.DuplicateRuleHeader.AllowSave = true;
        
         Account parent = new Account(Name = 'FCPAR1', dupcheck__dc3DisableDuplicateCheck__c= true);
        Database.insert(parent,opts);
        
        Account child1 = new Account(Name = 'FCCHLD1', ParentId = parent.Id, Top_10_Partner__c = 'Victoria;Euroline', Top_5_Target__c = 'Executive;Asset Solutions', dupcheck__dc3DisableDuplicateCheck__c= true);
        Database.insert(child1,opts);
        
        parent = [SELECT Id, Top_10_Partner__c, Top_5_Target__c FROM Account WHERE Id = :parent.Id][0];
        System.assertEquals('Victoria;Euroline',parent.Top_10_Partner__c);
        System.assertEquals('Executive;Asset Solutions',parent.Top_5_Target__c);
        
        Account child2 = new Account(Name = 'FCCHLD2', ParentId = parent.Id, Top_10_Partner__c = 'Victoria;Interiors NSW', Top_5_Target__c = 'Executive;Victoria', dupcheck__dc3DisableDuplicateCheck__c= true);
        Database.insert(child2,opts);
        
        parent = [SELECT Id, Top_10_Partner__c, Top_5_Target__c FROM Account WHERE Id = :parent.Id][0];
        System.assertEquals('Interiors NSW;Victoria;Euroline',parent.Top_10_Partner__c);
        System.assertEquals('Executive;Asset Solutions;Victoria',parent.Top_5_Target__c);
        
        delete child2;
        
        parent = [SELECT Id, Top_10_Partner__c, Top_5_Target__c FROM Account WHERE Id = :parent.Id][0];
        System.assertEquals('Victoria;Euroline',parent.Top_10_Partner__c);
        System.assertEquals('Executive;Asset Solutions',parent.Top_5_Target__c);
        
    }

}