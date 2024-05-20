trigger RecalculateAccountTrigger on Account (after insert, after update, after delete) {
    
    Set<Id> parentAccountIds = new Set<Id>();
    
    if(Trigger.isInsert){
        for(Account acc : Trigger.new){
            if(acc.ParentId != null && (acc.Top_10_Partner__c != null || acc.Top_5_Target__c != null)) parentAccountIds.add(acc.ParentId);
        }
    }
    
    else if(Trigger.isUpdate){
        for(Account acc : Trigger.new){
            
            Account oldAcc = Trigger.oldMap.get(acc.Id);
            
            if( oldAcc.ParentId != acc.ParentId){
                if (acc.ParentId != null) parentAccountIds.add(acc.ParentId);
                parentAccountIds.add(oldAcc.ParentId);
            }
            else if(
                oldAcc.Top_10_Partner__c != acc.Top_10_Partner__c || oldAcc.Top_5_Target__c != acc.Top_5_Target__c) {
                    if( oldAcc.ParentId != acc.ParentId){
                        if (acc.ParentId != null) parentAccountIds.add(acc.ParentId);
                        parentAccountIds.add(oldAcc.ParentId);
                    }
                    else parentAccountIds.add(acc.ParentId);
        	}
        }
    }
    
    else if(Trigger.isDelete){
        for (Account acc : Trigger.old){
            if(acc.ParentId != null) parentAccountIds.add(acc.ParentId);
        }
    }
    
    if(!parentAccountIds.isEmpty()) RecalculateAccountTop10or5.updateAccount(parentAccountIds);

}