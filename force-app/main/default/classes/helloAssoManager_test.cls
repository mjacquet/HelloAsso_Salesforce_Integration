@isTest
global class helloAssoManager_test {

    

    @istest static void CalloutClassTest() {
        
        account a = new account(name='account');
        insert a;
        contact c = new contact(lastname='contact',accountid=a.id,email='test@test.com');
        insert c;
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(npe03__Organization__c=a.id,name='RD',npe03__Amount__c=50,npe03__Open_Ended_Status__c='Open');
        insert rd;
        npe03__Recurring_Donation__c rd2 = new npe03__Recurring_Donation__c(npe03__Contact__c=c.id,name='RDc',npe03__Amount__c=50,npe03__Open_Ended_Status__c='Open');
        insert rd2;
        opportunity  o=new opportunity(name='test',amount=50,stageName='Pledged',closeDate=Date.newInstance(2018,08,17),npe03__Recurring_Donation__c=rd2.id);
        insert o;
        opportunity  o2=new opportunity(name='test',amount=50,stageName='Pledged',closeDate=Date.newInstance(2018,08,17),npe03__Recurring_Donation__c=rd.id);
        insert o2;
        
        test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        HelloAssoManager ham=new HelloAssoManager();
        ham.doBatch();
        Test.stopTest();
    }

    global class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        private Boolean apierror=true;

        global HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            if(apierror){
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('');
                res.setStatusCode(429);
                apierror=false;
                return res;
            }
            else{
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"resources":[{"id":"000081102923","ddate":"2018-08-17T15:58:00Z","amount":50.00,"type":"CREDIT","payer_first_name":"Maxime","payer_last_name":"Jacquet","payer_address":"qsc","payer_zip_code":"00500","payer_city":"XXXXX","payer_country":"FRA","payer_email":"test@test.com","payer_birthdate":null,"payer_society":"blabla","payer_is_society":false,"url_receipt":"https://www.helloasso.com/associations/zero-waste-france/formulaires/1/paiement-attestation/5037670","url_tax_receipt":"","actions":[{"id":"000050376701","type":"RECURRENT_DONATION","amount":50.00,"status":"PROCESSED"}],"status":"AUTHORIZED"},{"id":"000081102924","ddate":"2018-08-17T15:58:00Z","amount":50.00,"type":"CREDIT","payer_first_name":"Maxime","payer_last_name":"Jacquet","payer_address":"qsc","payer_zip_code":"00500","payer_city":"XXXXX","payer_country":"FRA","payer_email":"test2@test.com","payer_birthdate":null,"payer_society":"blabla","payer_is_society":true,"url_receipt":"https://www.helloasso.com/associations/zero-waste-france/formulaires/1/paiement-attestation/5037670","url_tax_receipt":"","actions":[{"id":"000050376702","type":"RECURRENT_DONATION","amount":50.00,"status":"PROCESSED"}],"status":"AUTHORIZED"}],"pagination":{"page":1,"max_page":1,"results_per_page":1}}');
                res.setStatusCode(200);
                apierror=true;
                return res;
            }
            
        }
    }
        
        public class MyCustomException extends Exception {} 
   
}