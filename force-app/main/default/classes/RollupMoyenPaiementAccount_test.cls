@isTest
private class RollupMoyenPaiementAccount_test {
  @testSetup 
    static void setup() {
       
            
        List<opportunity> opps = new List<opportunity>();   
        List<npe01__OppPayment__c> paiements = new List<npe01__OppPayment__c>();
        List<Account> accounts = new List<Account>();
        // insert 10 accounts
        account acc=new account(name='account');
        insert acc;
      /*  for (Integer i=0;i<10;i++) {
            contacts.add(new contact(lastname='lastname'+i,accountid=acc.id));
        }
        insert contacts;*/
        for (Integer i=0;i<10;i++) {
            opps.add(new opportunity(closeDate=Date.today(),name='opp'+i,accountid=acc.id,Methode_Paiement__c='Carte Bancaire',stageName='Posted'));
        }
        insert opps;
        for (Integer i=0;i<10;i++) {
            paiements.add(new npe01__OppPayment__c(npe01__Payment_Date__c=Date.today(),npe01__Paid__c=true,npe01__Opportunity__c=opps[i].id,npe01__Payment_Method__c='Carte Bancaire'));
        }
        insert paiements;
        
       
        
    }
    static testmethod void test() {        
        Test.startTest();
        RollupMoyenPaiementAccount rmp = new RollupMoyenPaiementAccount();
        Id batchId = Database.executeBatch(rmp);
        Test.stopTest();
        // after the testing stops, assert records were updated properly
        System.assertEquals(1, [select count() from account where Moyens_de_Paiement_annee_en_cours__c = 'Carte Bancaire']);
    }
}