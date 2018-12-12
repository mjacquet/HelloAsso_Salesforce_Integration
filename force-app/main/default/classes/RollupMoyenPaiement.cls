public class RollupMoyenPaiement {
    
    @future
    public static void ProcessRollup(){
        List<npe01__OppPayment__c> paiements_this_year=[SELECT id,npe01__Payment_Method__c,npe01__Opportunity__r.npsp__Primary_Contact__c from npe01__OppPayment__c where npe01__Paid__c=true AND npe01__Payment_Date__c=THIS_YEAR];
        List<npe01__OppPayment__c> paiements_last_year=[SELECT id,npe01__Payment_Method__c,npe01__Opportunity__r.npsp__Primary_Contact__c from npe01__OppPayment__c where npe01__Paid__c=true AND npe01__Payment_Date__c=LAST_YEAR];
        Set<String>contacts_to_process= new Set<String>();
        
        for(npe01__OppPayment__c p : paiements_this_year){
            contacts_to_process.add(p.npe01__Opportunity__r.npsp__Primary_Contact__c);
        }
        for(npe01__OppPayment__c p : paiements_last_year){
            contacts_to_process.add(p.npe01__Opportunity__r.npsp__Primary_Contact__c);
        }
        Map<ID, Contact> m = new Map<ID, Contact>([SELECT Id,Moyens_de_Paiement_ann_e_derni_re__c,Moyens_de_Paiement_annee_en_cours__c FROM Contact where id IN :contacts_to_process]);
        system.debug('contacts to process:');
        system.debug(m);
        for(npe01__OppPayment__c p : paiements_this_year){ 
            contact c=m.get(p.npe01__Opportunity__r.npsp__Primary_Contact__c);
            system.debug(c);
            if(c!=null && !string.isblank(p.npe01__Payment_Method__c)){
                if(string.isBlank(c.Moyens_de_Paiement_annee_en_cours__c))
                    c.Moyens_de_Paiement_annee_en_cours__c=p.npe01__Payment_Method__c;
                else{
                    if(!c.Moyens_de_Paiement_annee_en_cours__c.contains(p.npe01__Payment_Method__c))c.Moyens_de_Paiement_annee_en_cours__c+=','+p.npe01__Payment_Method__c;
                }    
                m.put(c.id,c);
            }
            
        }
        for(npe01__OppPayment__c p : paiements_last_year){
            contact c=m.get(p.npe01__Opportunity__r.npsp__Primary_Contact__c);
            system.debug(c);
            if(c!=null && !string.isblank(p.npe01__Payment_Method__c)){
                if(string.isBlank(c.Moyens_de_Paiement_ann_e_derni_re__c))
                    c.Moyens_de_Paiement_ann_e_derni_re__c=p.npe01__Payment_Method__c;
                else{
                    if(!c.Moyens_de_Paiement_ann_e_derni_re__c.contains(p.npe01__Payment_Method__c))c.Moyens_de_Paiement_ann_e_derni_re__c+=','+p.npe01__Payment_Method__c;
                } 
                m.put(c.id,c);
            }
        }
        system.debug('contacts processed:');
        system.debug(m);
        update m.values();
        
    }
    
    
    //SCHEDULED function
    public void execute(SchedulableContext ctx) {    
        System.debug('processing Rollup moyen de paiement: ');   
        processRollup(); 
    }
    
}