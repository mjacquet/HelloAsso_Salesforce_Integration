@istest
public class adhesion_test {
    
    @istest static void testadhesion() {
        account acc=new account(name='a');
        insert acc;
        contact con=new contact(lastname='c',accountid=acc.id);
        insert con;
        test.startTest();
        opportunity opp1=new opportunity(name='opp',demande_adhesion__c=true,npsp__Primary_Contact__c=con.id,closeDate=date.today(),stageName='Posted');
        insert opp1;
        test.stopTest();
        system.assertEquals(1,[select count() from opportunity where npe01__Membership_End_Date__c=:Date.today().addYears(1)]);
        
    }

}