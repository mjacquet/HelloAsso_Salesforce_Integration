trigger adhesion on Opportunity (after insert) {
   
   recordtype rt=[select id from recordtype where sobjecttype='opportunity' and developername='Membership'];
   List<opportunity> membership=new list<opportunity>();
    for(opportunity opp:Trigger.new){
        if(opp.demande_adhesion__c==true){
            list<opportunity> adhesion=[SELECT npe01__Membership_End_Date__c from opportunity where recordtypeid=:rt.id AND npsp__Primary_Contact__c=:opp.npsp__Primary_Contact__c AND npe01__Membership_End_Date__c>TODAY];
            if(adhesion.isempty()){
                //create a membership
                opportunity adh=new opportunity();
                adh.npsp__Primary_Contact__c=opp.npsp__Primary_Contact__c;
                adh.accountid=opp.accountid;
                adh.amount=0;
                adh.closedate=Date.today();
                adh.npe01__Membership_Start_Date__c=Date.today();
                adh.npe01__Membership_End_Date__c=Date.today().addYears(1);
                adh.StageName='Closed Won';
                adh.Name='Adhésion - '+date.today().format();
                adh.recordtypeid=rt.id;
                membership.add(adh);

            }
            else{
                adhesion[0].npe01__Membership_End_Date__c=Date.today().addYears(1); 
                 membership.add(adhesion[0]);  
            }
           
        }
    }
    upsert membership;
}