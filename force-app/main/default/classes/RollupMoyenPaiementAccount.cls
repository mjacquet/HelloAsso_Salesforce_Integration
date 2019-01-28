global class RollupMoyenPaiementAccount implements 
Database.Batchable<sObject>, Database.Stateful{
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global set<id> pc=new set<id>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT id,npe01__Payment_Method__c,npe01__Opportunity__r.accountid,npe01__Payment_Date__c '+
            'from npe01__OppPayment__c '+
            'WHERE npe01__Paid__c=true AND (npe01__Payment_Date__c=THIS_YEAR OR npe01__Payment_Date__c=LAST_YEAR)'
        );
    }
    
    global void execute(Database.BatchableContext bc, List<npe01__OppPayment__c> scope){
        // process each batch of records
        Set<String>accounts_to_process= new Set<String>();
        
        for(npe01__OppPayment__c p : scope){
            accounts_to_process.add(p.npe01__Opportunity__r.accountid);
        }
        Map<ID, Account> m = new Map<ID, Account>([SELECT Id,Moyens_de_Paiement_ann_e_derni_re__c,Moyens_de_Paiement_annee_en_cours__c FROM Account where id IN :accounts_to_process]);
        system.debug('accounts to process:');
        system.debug(m);
        for(npe01__OppPayment__c p : scope){ 
            account c=m.get(p.npe01__Opportunity__r.accountid);
            if(c!=null && !pc.contains(c.id)){
                c.Moyens_de_Paiement_ann_e_derni_re__c='';
                c.Moyens_de_Paiement_annee_en_cours__c='';
                pc.add(c.id);
            }
            system.debug(c);
            if(c!=null && !string.isblank(p.npe01__Payment_Method__c)){
                if(p.npe01__Payment_Date__c.year()==system.date.today().year()){
                	if(string.isBlank(c.Moyens_de_Paiement_annee_en_cours__c))
                        c.Moyens_de_Paiement_annee_en_cours__c=p.npe01__Payment_Method__c;
                    else{
                        if(!c.Moyens_de_Paiement_annee_en_cours__c.contains(p.npe01__Payment_Method__c))c.Moyens_de_Paiement_annee_en_cours__c+=','+p.npe01__Payment_Method__c;
                    } 
                }  
                else{
                    if(string.isBlank(c.Moyens_de_Paiement_ann_e_derni_re__c))
                    c.Moyens_de_Paiement_ann_e_derni_re__c=p.npe01__Payment_Method__c;
                else{
                    if(!c.Moyens_de_Paiement_ann_e_derni_re__c.contains(p.npe01__Payment_Method__c))c.Moyens_de_Paiement_ann_e_derni_re__c+=','+p.npe01__Payment_Method__c;
                	} 
                }  
                m.put(c.id,c);
            }
           recordsProcessed=recordsProcessed+1; 
        }
        system.debug('Accounts processed:');
        system.debug(m);
        update m.values();
    }    
    
    global void finish(Database.BatchableContext bc){
          System.debug(recordsProcessed + ' records processed. Shazam!');
        /*
AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
JobItemsProcessed,
TotalJobItems, CreatedBy.Email
FROM AsyncApexJob
WHERE Id = :bc.getJobId()];
// call some utility to send email
EmailUtils.sendMessage(a, recordsProcessed);*/
    } 
    
}