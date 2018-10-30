@isTest
global class helloAssoManager_test {
    
@istest static void testRestGet() {
        //Id recordId = createTestRecord();
        // Set up a test request
       // Test.setMock(HttpCalloutMock.class, new GetPaymentCalloutMock());
    
    	SingleRequestMock fakePaymentResp = new SingleRequestMock(200,
                                                         'Complete',
                                                         '{"id":"000026162483","ddate":"2018-08-17T15:58:00Z","amount":5.00,"type":"CREDIT","payer_first_name":"Maxime","payer_last_name":"Jacquet","payer_address":"51 rue leon fontaine","payer_zip_code":"78500","payer_city":"Sartrouville","payer_country":"FRA","payer_email":"zerowaste@jacquet.me","payer_birthdate":null,"payer_society":"","payer_is_society":false,"url_receipt":"https://www.helloasso.com/associations/zero-waste-france/formulaires/1/paiement-attestation/5037670","url_tax_receipt":"","actions":[{"id":"000050376701","type":"DONATION","amount":5.00,"status":"PROCESSED"}],"status":"AUTHORIZED"}',
                                                         null);

        SingleRequestMock fakeActionResp = new SingleRequestMock(200,
                                                  'Complete',
                                                  '{"id":"000050376701","id_campaign":"000000279262","id_organism":"000000239631","id_payment":"000026162483","ddate":"2018-08-17T15:57:45.9130675Z","amount":5.00,"type":"DONATION","first_name":"Maxime","last_name":"Jacquet","address":null,"zip_code":null,"city":null,"country":null,"email":"zerowaste@jacquet.me","custom_infos":[{"label":"Comment avez-vous connu lassociation ?","value":"Autre"},{"label":"Par ce don, jadhère à lassociation Zero Waste France : une voix de plus pour le zéro déchet, zéro gaspillage ! ","value":"Oui"}],"status":"PROCESSED","option_label":null}',
                                                   null);
    SingleRequestMock fakeCampaignResp = new SingleRequestMock(200,
                                                  'Complete',
                                                  '{"id":"000000279262","name":"Formulaire principal","slug":"1","type":"FORM","state":"PUBLIC","funding":28472.00,"supporters":475,"url":"https://www.helloasso.com/associations/zero-waste-france/formulaires/1","id_organism":"000000239631","slug_organism":"zero-waste-france","creation_date":"2016-11-02T05:47:12.75Z","last_update":"2016-11-02T05:47:12.75Z","place_name":null,"place_address":null,"place_city":null,"place_zipcode":null,"place_country":null,"start_date":null,"end_date":null}',
                                                   null);

        Map<String, HttpCalloutMock> endpoint2TestResp =
                                   new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('callout:HelloAssoApi/v3/payments/000026162483.json',fakePaymentResp);
        endpoint2TestResp.put('callout:HelloAssoApi/v3/actions/000050376701.json',fakeActionResp);
        endpoint2TestResp.put('callout:HelloAssoApi/v3/campaigns/000000279262.json',fakeCampaignResp);

        HttpCalloutMock multiCalloutMock =
            	                   new MultiRequestMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
     
    
        RestRequest request = new RestRequest();
        request.requestUri = 'http://zerotest-zerowastefrancesbx.cs87.force.com/helloasso/services/apexrest/helloasso/000026162483';
        request.httpMethod = 'GET';
        RestContext.request = request;
        // Call the method to test
        String res = HelloAssoManager.GetPaiement();
        // Verify results
        System.assertEquals('processed', res);
    }
    
    @istest static void testScheduled() {
        //Id recordId = createTestRecord();
        // Set up a test request
       // Test.setMock(HttpCalloutMock.class, new GetPaymentCalloutMock());
        SingleRequestMock fakePaymenstResp = new SingleRequestMock(200,
                                                         'Complete',
                                                         '{"resources":[{"id":"000026162483","ddate":"2018-08-17T15:58:00Z","amount":5.00,"type":"CREDIT","payer_first_name":"Maxime","payer_last_name":"Jacquet","payer_address":"51 rue leon fontaine","payer_zip_code":"78500","payer_city":"Sartrouville","payer_country":"FRA","payer_email":"zerowaste@jacquet.me","payer_birthdate":null,"payer_society":"blabla","payer_is_society":true,"url_receipt":"https://www.helloasso.com/associations/zero-waste-france/formulaires/1/paiement-attestation/5037670","url_tax_receipt":"","actions":[{"id":"000050376701","type":"RECURRENT_DONATION","amount":5.00,"status":"PROCESSED"}],"status":"AUTHORIZED"}],"pagination":{"page":1,"max_page":576,"results_per_page":1}}',
                                                         null);
    
    	SingleRequestMock fakePaymentResp = new SingleRequestMock(200,
                                                         'Complete',
                                                         '{"id":"000026162483","ddate":"2018-08-17T15:58:00Z","amount":5.00,"type":"CREDIT","payer_first_name":"Maxime","payer_last_name":"Jacquet","payer_address":"51 rue leon fontaine","payer_zip_code":"78500","payer_city":"Sartrouville","payer_country":"FRA","payer_email":"zerowaste@jacquet.me","payer_birthdate":null,"payer_society":"blabla","payer_is_society":true,"url_receipt":"https://www.helloasso.com/associations/zero-waste-france/formulaires/1/paiement-attestation/5037670","url_tax_receipt":"","actions":[{"id":"000050376701","type":"RECURRENT_DONATION","amount":5.00,"status":"PROCESSED"}],"status":"AUTHORIZED"}',
                                                         null);

        SingleRequestMock fakeActionResp = new SingleRequestMock(200,
                                                  'Complete',
                                                  '{"id":"000050376701","id_campaign":"000000279262","id_organism":"000000239631","id_payment":"000026162483","ddate":"2018-08-17T15:57:45.9130675Z","amount":5.00,"type":"RECURRENT_DONATION","first_name":"Maxime","last_name":"Jacquet","address":null,"zip_code":null,"city":null,"country":null,"email":"zerowaste@jacquet.me","custom_infos":[{"label":"Comment avez-vous connu lassociation ?","value":"Autre"},{"label":"Par ce don, jadhère à lassociation Zero Waste France : une voix de plus pour le zéro déchet, zéro gaspillage ! ","value":"Oui"}],"status":"PROCESSED","option_label":null}',
                                                   null);
    	SingleRequestMock fakeCampaignResp = new SingleRequestMock(200,
                                                  'Complete',
                                                  '{"id":"000000279262","name":"Formulaire principal","slug":"1","type":"FORM","state":"PUBLIC","funding":28472.00,"supporters":475,"url":"https://www.helloasso.com/associations/zero-waste-france/formulaires/1","id_organism":"000000239631","slug_organism":"zero-waste-france","creation_date":"2016-11-02T05:47:12.75Z","last_update":"2016-11-02T05:47:12.75Z","place_name":null,"place_address":null,"place_city":null,"place_zipcode":null,"place_country":null,"start_date":null,"end_date":null}',
                                                   null);

        Map<String, HttpCalloutMock> endpoint2TestResp =
                                   new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('callout:HelloAssoApi/v3/payments/000026162483.json',fakePaymentResp);
        endpoint2TestResp.put('callout:HelloAssoApi/v3/actions/000050376701.json',fakeActionResp);
        endpoint2TestResp.put('callout:HelloAssoApi/v3/campaigns/000000279262.json',fakeCampaignResp);
        endpoint2TestResp.put('callout:HelloAssoApi/v3/organizations/000000239631/payments.json?from=2018-08-17T17:33:00&results_per_page=1000',fakePaymenstResp);

        HttpCalloutMock multiCalloutMock =
            	                   new MultiRequestMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
     
    
              // Call the method to test
        List<HelloAssoManager.payment> ps=HelloAssoManager.getPayments('2018-08-17T17:33:00');
       
        HelloAssoManager.processPayments(ps); 
        
        // Verify results
        System.assertEquals('processed', 'processed');
    }
    
  
    
 
    
    
    public class MyCustomException extends Exception {}
    
    public class MultiRequestMock implements HttpCalloutMock {
        Map<String, HttpCalloutMock> requests;
    
        public MultiRequestMock(Map<String, HttpCalloutMock> requests) {
            this.requests = requests;
        }
    
        public HTTPResponse respond(HTTPRequest req) {
            HttpCalloutMock mock = requests.get(req.getEndpoint());
            if (mock != null) {
                return mock.respond(req);
            } else {
                    throw new MyCustomException('HTTP callout not supported for test methods '+req.getEndpoint());
            }
        }
    
        public void addRequestMock(String url, HttpCalloutMock mock) {
            requests.put(url, mock);
        }
	}
    
    
public class SingleRequestMock implements HttpCalloutMock {
		protected Integer code;
		protected String status;
		protected String bodyAsString;
		protected Blob bodyAsBlob;
		protected Map<String, String> responseHeaders;

		public SingleRequestMock(Integer code, String status, String body,
                                         Map<String, String> responseHeaders) {
			this.code = code;
			this.status = status;
			this.bodyAsString = body;
			this.bodyAsBlob = null;
			this.responseHeaders = responseHeaders;
		}

		public SingleRequestMock(Integer code, String status, Blob body,
                                         Map<String, String> responseHeaders) {
			this.code = code;
			this.status = status;
			this.bodyAsBlob = body;
			this.bodyAsString = null;
			this.responseHeaders = responseHeaders;
		}

	    public HTTPResponse respond(HTTPRequest req) {
	        HttpResponse resp = new HttpResponse();
			resp.setStatusCode(code);
			resp.setStatus(status);
			if (bodyAsBlob != null) {
				resp.setBodyAsBlob(bodyAsBlob);
			} else {
				resp.setBody(bodyAsString);
			}

			if (responseHeaders != null) {
			     for (String key : responseHeaders.keySet()) {
				resp.setHeader(key, responseHeaders.get(key));
			     }
			}
			return resp;
	    }
}
   
}