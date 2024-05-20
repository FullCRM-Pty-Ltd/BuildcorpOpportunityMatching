public class RecalculateAccountTop10or5 {
    
    public static void updateAccount(Set<Id> parentAccountIds){
        
        List<Account> childAccounts = [SELECT Id, Top_10_Partner__c, Top_5_Target__c, ParentId FROM Account WHERE ParentId IN :parentAccountIds];
        List<Account> parentAccounts = [SELECT Id, Top_10_Partner__c, Top_5_Target__c, (SELECT Id, Top_10_Partner__c, Name, Top_5_Target__c FROM ChildAccounts) FROM Account WHERE Id IN :parentAccountIds];
        
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Account parentAccount : parentAccounts){
        
            List<String> parentTop10 = new List<String>();
            if(parentAccount.Top_10_Partner__c != null) parentTop10 = parentAccount.Top_10_Partner__c.split(';');
            List<String> parentTop5 = new List<String>();
            if(parentAccount.Top_5_Target__c != null) parentTop5 = parentAccount.Top_5_Target__c.split(';');
            
            List<String> allChildrenTop10 = new List<String>();
            List<String> allChildrenTop5 = new List<String>();
            
            for (Account child : parentAccount.ChildAccounts){
                
                System.debug('Child Account: '+child.Name+', Top 10: '+child.Top_10_Partner__c+', Top 5: '+child.Top_5_Target__c);
                
                if(child.Top_10_Partner__c != null){
                    List<String> childTop10 = child.Top_10_Partner__c.split(';');
                    
                    for (String top10 : childTop10){
                        if(!allChildrenTop10.contains(top10)) allChildrenTop10.add(top10);
                    }
                }
                
                if(child.Top_5_Target__c != null){
                    List<String> childTop5 = child.Top_5_Target__c.split(';');
                    
                    for (String top5 : childTop5){
                        if(!allChildrenTop5.contains(top5)) allChildrenTop5.add(top5);
                    }
                }
            }
            
            System.debug('All Top 10: '+allChildrenTop10);
            System.debug('All Top 5: '+allChildrenTop5);
            
            System.debug('Parent Top 10 (Initial): '+parentTop10);
            System.debug('Parent Top 5 (Initial): '+parentTop5);
            
            if(allChildrenTop10.isEmpty()) parentTop10 = null;
            
            else{
                for (Integer i = 0; i < parentTop10.size(); i++){
                    if(!allChildrenTop10.contains(parentTop10[i])) parentTop10.remove(i);
                }
            }
            
            if(allChildrenTop5.isEmpty()) parentTop5 = null;
            
            else{
                for (Integer i = 0; i < parentTop5.size(); i++){
                    if(!allChildrenTop5.contains(parentTop5[i])) parentTop5.remove(i); 
                }
            }
            
            System.debug('Parent Top 10 (After Removal): '+parentTop10);
            System.debug('Parent Top 5 (After Removal): '+parentTop5);
            
            for (String top10 : allChildrenTop10){
                if(!parentTop10.contains(top10)) parentTop10.add(top10);
            }
            
            for (String top5 : allChildrenTop5){
                if(!parentTop5.contains(top5)) parentTop5.add(top5);
            }
            
            System.debug('Parent Top 10 (After Addition): '+parentTop10);
            System.debug('Parent Top 5 (After Addition): '+parentTop5);
            
            String top10Value = null;
            String top5Value = null;
            
            if(parentTop10 != null){
                top10Value = parentTop10.toString().replace(', ',';');
                top10Value = top10Value.replace('(','');
                top10Value = top10Value.replace(')','');
            }
            
            If(parentTop5 != null){
                top5Value = parentTop5.toString().replace(', ',';');
                top5Value = top5Value.replace('(','');
                top5Value = top5Value.replace(')','');
            }
            
            System.debug('Top 10 Value: '+top10Value);
            System.debug('Top 5 Value: '+top5Value);
            
            
            parentAccount.Top_10_Partner__c = top10Value;
            parentAccount.Top_5_Target__c = top5Value;
            
            System.debug(parentAccount);
            accountsToUpdate.add(parentAccount);
        }
        
        update accountsToUpdate;
        
    }

}