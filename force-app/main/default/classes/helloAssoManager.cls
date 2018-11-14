@RestResource(urlMapping='/')
global with sharing class helloAssoManager implements Schedulable {
    //REST Endpoints exposed
    
    @HttpGet
    global static String GetPaiement() {
        RestRequest request = RestContext.request;
        // grab the caseId from the end of the URL
        String pId = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
        
        System.debug('GET received');
        System.debug(pId);
        if(!String.isBlank(pID)&& pid!='helloasso'){
        	Payment p=getPayment(pId); 
            for (Integer i = 0; i < p.actions.size(); i++) {
                p.actions[i]=getAction(p.actions[i].Id);
            }      
            processPayment(p);   
    
        	return 'processed';
    	}
    	else return 'nothing to process';
        
        //URL: https://cs87.salesforce.com/services/apexrest/helloasso
        //http://zerotest-zerowastefrancesbx.cs87.force.com/helloasso/services/apexrest/helloasso
    }
    @HttpPost
    global static String postPaiement() {// this method will be called at every payment. We will then have a daily scheduled Apex thet will verify no payments falled throught the cracks.
        System.debug('POST received');
        System.debug(RestContext.request.params);
        String pId=RestContext.request.params.get('id');
        System.debug('payment ID to process: '+pId);
        String aId=RestContext.request.params.get('action_id');
        System.debug('action ID to process: '+aId);
        
        Payment p=getPayment(pId); 
        for (Integer i = 0; i < p.actions.size(); i++) {
            p.actions[i]=getAction(p.actions[i].Id);
        }      
        processPayment(p);   
        return '';
    }    
    
    //PUBLIC functions
    
    public static List<payment> getPayments(String fromdate){//'2018-08-17T17:09:47'
        system.debug('getPayments');
        List<payment> p=makeGetPaymentsCallout(fromdate);
        system.debug(p);
        return p;
    } 
    
    public static payment getPayment(String paymentId){
        system.debug('getPayment');
        payment p=makeGetPaymentCallout(paymentId);
        system.debug(p);
        return p;
    } 
    
    public static action getAction(String actionId){
        system.debug('getAction');
        action a=makeGetActionCallout(actionId);
        system.debug(a);
        return a;
    } 
 /*   
    public static list<action> getActions(String fromdate){
        system.debug('getActions');
        List<action> a=makeGetActionsCallout(fromdate);
        system.debug(a);
        return a;
    } 
 */   
    public static void processPayment(payment p){
        List<npe01__OppPayment__c> npsp_ps=[SELECT id,npe01__Check_Reference_Number__c from npe01__OppPayment__c where Plateforme_de_paiement__c='Helloasso' AND npe01__Check_Reference_Number__c = :p.id];
        if(npsp_ps.isempty()){
            boolean bo=doProcessPayment(p);
        } 
    }
	public static void processPayments(List<payment> ps){
        //Process to remove the payments already processed.
        List<String>pids=new list<string>();
        Map<String,Payment> mp=new Map<String,Payment>();
        for(payment p : ps){
            pids.add(p.id);
            mp.put(p.id,p);
        }
       System.debug('map before filtering (size: '+pids.size()+')');
       System.debug(mp);
       List<npe01__OppPayment__c> npsp_ps=[SELECT id,npe01__Check_Reference_Number__c from npe01__OppPayment__c where Plateforme_de_paiement__c='Helloasso' AND npe01__Check_Reference_Number__c IN :pids];
       for(npe01__OppPayment__c npp : npsp_ps){
           mp.remove(npp.npe01__Check_Reference_Number__c);
       }
        //let's also filter by removing payment where there is no donations...
       List<String> cpids=new list<string>();
       List<String> conids=new list<string>();
       list <payment> fps=mp.values();
        for(payment fp :fps){
            Boolean toProcess=false;
            for(action a:fp.actions){
                if(a.type=='DONATION' || a.type=='RECURRENT_DONATION'){//'RECURRENT_DONATION
                    toProcess=true;
                    cpids.add(a.id_campaign);
                }
            }
            if(!toProcess)mp.remove(fp.id);
            else conids.add(fp.payer_email);
        }
       
       List<payment> ps_toprocess=mp.values();
       System.debug('map after filtering(size: '+ps_toprocess.size()+')');
       System.debug(ps_toprocess);
       
        for(payment p : ps_toprocess){
            futureProcessPayment(p.id);
        }  
    }
    
    @future(callout=true)
    public static void futureProcessPayment(String pid){
        Payment p=getPayment(pId);
        if(p!=null){
            for (Integer i = 0; i < p.actions.size(); i++) {
                p.actions[i]=getAction(p.actions[i].Id);
            }      
            processPayment(p); 
        }
    }
    
    
    //SCHEDULED function
    global void execute(SchedulableContext ctx) {
        datetime myDateTime = datetime.now();
        mydatetime=myDateTime.addHours(-25);
       // datetime myactiondatetime=myDateTime.addHours(-120);
        String Fromdate=mydateTime.format('yyyy-MM-dd\'T\'HH:mm:ss');
      //  String ActionFromdate=mydateTime.format('yyyy-MM-dd\'T\'HH:mm:ss');
       // fromdate='2018-10-02T00:00:01';//test
      //  actionfromdate='2018-01-01T00:00:01';//test
        System.debug('processing date: '+Fromdate);
        //'2018-08-17T17:09:47';
        List<payment> ps=getPayments(Fromdate);
        System.debug('Received payments: '+ps.size());
      //  List<action> acs=getActions(ActionFromdate);
       
        processPayments(ps); 
    }
    
    //PRIVATE functions
    private static boolean doProcessPayment(payment p){
        System.Debug('Processing payment with Id '+p.ID);
        System.Debug(p);   
        //We will need to loop through actions to process only donations, not inscriptions (ticket sales for event).
        //Why are there some payments without actions??? Bug opened with helloasso (ticket #143935). Ignoring those payments for now.
        //We get the campaign through the action
        for(action a: p.actions){
            System.Debug('Payment action');
            if(a.type=='DONATION' || a.type=='RECURRENT_DONATION'){// . //if we already processed a donation, then it is a duplicate helloasso case #144372
                //let's create the donation
                
                Opportunity donation=new Opportunity();
                
                //Looking for the campaign to link the donation
                System.Debug('campaign');
                List<Campaign> camps=[SELECT id from campaign where helloassoid__c=:a.id_campaign];
                if(camps.isEmpty()){
                    Campaign camp=new campaign();
                    haCampaign hac=makeGetCampaignCallout(a.id_campaign);
                    camp.name=hac.name;
                    camp.helloassoid__c=a.id_campaign;
                    insert camp;
                    System.Debug(camp);
                    donation.campaignId=camp.id;
                }
                else {
                    donation.campaignId=camps[0].id;
                    System.Debug(camps[0].id);
                }
                
                // let's attach to a contact. Here based on email. We don't handle existing duplicates, that will be handled in Salesforce.
                System.Debug('Contact (+household or Organization)');
                List<contact> cs=[Select id,accountid,name,firstname,lastname,account.name,email from contact where email=:p.payer_email FOR UPDATE];
                Contact con=new contact();
                if(cs.isEmpty()){
                    //No contact with this email. let's create one.
                    System.Debug('Creating contact');
                    if(p.payer_is_society){//this is an organization, not an household
                        Account acc=new account();
                        acc.shippingStreet=p.payer_address;
                        acc.shippingPostalCode=p.payer_zip_code;
                        acc.shippingCity=p.payer_city;
                        acc.shippingCountry=p.payer_country;
                        acc.name=p.payer_society;
                        insert acc;
                        System.Debug(acc);
                        con.GW_Volunteers__Volunteer_Organization__c=p.payer_society;
                        con.accountid=acc.id;
                    }
                    con.firstname=p.payer_first_name;
                    con.lastname=p.payer_last_name;
                    con.MailingStreet=p.payer_address;
                    con.mailingPostalCode=p.payer_zip_code;
                    con.mailingCity=p.payer_city;
                    con.mailingCountry=p.payer_country;
                    con.email=p.payer_email;
                    con.Birthdate=p.payer_birthdate.date();
                    insert con;
                    con=[SELECT firstname,lastname, email, account.name,accountid from contact where id=:con.id FOR UPDATE];
                    donation.npsp__Primary_Contact__c=con.id;
                    donation.Accountid=con.accountid;
                }
                else {//maybe we can add a loop to update info or add info from this payment.
                    con=cs[0];
                    donation.npsp__Primary_Contact__c=cs[0].id;
                    donation.Accountid=cs[0].accountid;
                }
                System.Debug(con);
                if(a.type=='RECURRENT_DONATION'){
                    //looking for existing recurrent_donation
                    npe03__Recurring_Donation__c rd=new npe03__Recurring_Donation__c();
                    List <npe03__Recurring_Donation__c> rds=new List<npe03__Recurring_Donation__c>();
                    if(p.payer_is_society){
                        rds=[SELECT id,npe03__Contact__c,npe03__Organization__c from npe03__Recurring_Donation__c where npe03__Organization__c=:con.accountid ];
                    }
                    else{
                        rds=[SELECT id,npe03__Contact__c,npe03__Organization__c from npe03__Recurring_Donation__c where npe03__Contact__c=:con.id];
                    }
                    if(rds.isEmpty()){
                        
                        if(p.payer_is_society){ 
                            rd.npe03__Organization__c=con.accountid;
                            rd.Name='Donation récurrente - '+con.account.name;
                        }
                        else {
                            rd.npe03__Contact__c=con.id;
                            rd.Name='Donation récurrente - '+con.Firstname+' ' +con.Lastname;
                        }
                        rd.npe03__Amount__c=a.amount;
                        rd.npe03__Date_Established__c=a.ddate.date();
                        rd.npe03__Installment_Period__c='Monthly';
                        rd.npe03__Open_Ended_Status__c='Open';
                        insert rd;
                    }
                    else rd=rds[0];
                    
                    donation=[Select id,amount from opportunity where npe03__Recurring_Donation__c=:rd.id and stageName='Pledged' order by closeDate asc LIMIT 1 ];//FOR UPDATE
                    donation=[Select id,amount from opportunity where id=:donation.id FOR UPDATE];
                    
                }
                else{
                    //let's update the donation
                    donation.name=p.payer_first_name+' '+p.payer_last_name+' donation '+p.ddate.format();
                    donation.amount=a.amount;   
                }
                
                donation.closedate=p.ddate.date();
                donation.StageName='Posted';
                for(custom_infos ci:a.custom_infos){
                    donation.description=ci.label+ ': '+ci.value+'\n';
                    if(ci.label.contains('adhérent')){
                        if(ci.value=='Oui'){
                            donation.Demande_adhesion__c=true;//créer une adhésion.
                        }
                        else donation.Demande_adhesion__c=false;
                        //pour slimpay egalement: 
                    }
                    if(ci.label.contains('newsletter')){
                        if(ci.value=='Oui'){
                            con.newsletter__c=true;
                            update con;
                        }
                        else{
                            con.newsletter__c=false;
                            update con;
                        }
                    }
                    if(ci.label.contains('connu')){
                        con.contact_comment_connu__c=ci.value;
                        update con;
                    }
                }

                switch on p.type{
                        when 'CREDIT'{donation.Methode_Paiement__c='Carte Bancaire';}//
                        when 'CHEQUE'{donation.Methode_Paiement__c='Chèque';}
                        when 'SEPA'{donation.Methode_Paiement__c='Prélèvement Automatique';}
                    }
                
                System.Debug('Donation');
                upsert donation;
                System.Debug(donation);
                
                //The payment is automatically created when inserting Donation - lets update payment.
                List<npe01__OppPayment__c> npspps=[SELECT id from npe01__OppPayment__c where npe01__Opportunity__c=:donation.id];
                System.Debug('payments');
                
                if(npspps.isEmpty()){
                    // No payment. An error probably occured. That shouldn't happen.
                    System.Debug('No payment associated. There has been an issue.');
                }
                else{
                    npe01__OppPayment__c p1=npspps[0];
                    p1.npe01__Check_Reference_Number__c=p.id;
                    p1.Plateforme_de_paiement__c='Helloasso';
                    switch on p.type{
                        when 'CREDIT'{p1.npe01__Payment_Method__c='Carte Bbncaire';}//
                        when 'CHEQUE'{p1.npe01__Payment_Method__c='Chèque';}
                        when 'SEPA'{P1.npe01__Payment_Method__c='Prélèvement Automatique';}
                    }
                    
                    //paiment type to map (cheque, credit, SEPA)
                    update p1;
                    System.Debug(p1);
                } 
                
            } 
        } 
        return true;
    }
    
 
    
    
    
    private static List<payment> makeGetPaymentsCallout(String fromdate) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:HelloAssoApi/v3/organizations/000000239631/payments.json?from='+fromdate+'&results_per_page=1000');//BACK to 10000 after test
        request.setMethod('GET');
        request.setTimeout(20000);
        HttpResponse response = http.send(request);    
        List<payment> payments = new List<payment>();
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            resource res= (resource) JSON.deserialize(response.getBody().replace('"date"','"ddate"'),resource.class);
            payments = res.resources;
            System.debug('Received the following payments:');
            System.debug(payments);           
        }
        return payments;
    } 
    
    
    private static payment makeGetPaymentCallout(String paymentID) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:HelloAssoApi/v3/payments/'+paymentID+'.json');
        request.setMethod('GET');
        request.setTimeout(20000);
        HttpResponse response = http.send(request);    
        payment payment=new payment();
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            payment = (payment) JSON.deserialize(response.getBody().replace('"date"','"ddate"'),payment.class);
            // Cast the values in the 'animals' key as a list
            //payment = (Object) results.get('resources');
            System.debug('Received the following payment details:');
            System.debug(payment);
            
        }
        return payment;
    } 
  /*  
    private static List<action> makeGetActionsCallout(String fromdate) {//type = DONATION | INSCRIPTION | SUBSCRIPTION | RECURRENT_DONATION | OPTION
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:HelloAssoApi/v3/organizations/000000239631/actions.json?from='+fromdate+'&results_per_page=1000');//back to 10000
        request.setMethod('GET');
        request.setTimeout(20000);
        HttpResponse response = http.send(request);    
        List<action> actions = new List<action>();
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            actionresource res= (actionresource) JSON.deserialize(response.getBody().replace('"date"','"ddate"'),actionresource.class);
            actions = res.resources;
            System.debug('Received the following actions:');
            System.debug(actions);        
        }
        return actions;
    } */
    
    private static action makeGetActionCallout(String actionId) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:HelloAssoApi/v3/actions/'+actionID+'.json');
        request.setMethod('GET');
        request.setTimeout(20000);
        HttpResponse response = http.send(request);    
        action action=new action();
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            action = (action) JSON.deserialize(response.getBody().replace('"date"','"ddate"'),action.class);
            System.debug('Received the following action:');
            System.debug(action);
            
        }
        return action;
    } 
    private static haCampaign makeGetCampaignCallout(String CampId) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:HelloAssoApi/v3/campaigns/'+CampId+'.json');
        request.setMethod('GET');
        request.setTimeout(20000);
        HttpResponse response = http.send(request);    
        haCampaign haCampaign=new haCampaign();
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            haCampaign = (haCampaign) JSON.deserialize(response.getBody(),haCampaign.class);
            System.debug('Received the following campaign:');
            System.debug(haCampaign);
            
        }
        return haCampaign;
    } 
    
    
    //INNER CLASSES   
    global class actionresource{
        public List<action> resources;
        public pagination pagination;
    }
    global class resource{
        public List<payment> resources;
        public pagination pagination;
    }
    
    global class pagination{
        public integer page;
        public integer max_page;
        public integer results_per_page;
    }
    global class payment
    {
        public String id;
        public Decimal amount;
        public datetime ddate;
        public string type;
        public string payer_first_name;
        public string payer_last_name;
        public string payer_address;
        public string payer_zip_code;
        public string payer_city;
        public string payer_country;
        public string payer_email;
        public datetime payer_birthdate;
        public string payer_society;
        public boolean payer_is_society;
        public string url_receipt;
        public string url_tax_receipt;
        public string status;
        public string mean; //moyen de paiement NEW
        public List<action> actions;
    }
    global class action{
        public String id;
        public String type;
        public Decimal amount;
        public String status;
        public String id_campaign;
        public String id_payment;
        public String id_organism;
        public datetime ddate;
        public String first_name;
        public String last_name;
        public String address; 
        public String zip_code; 
        public String city;
        public String country;
        public String email;
        public String option_label;  
        public List<custom_infos> custom_infos;           
    }
    global class custom_infos{
        public String label;
        public String value;            
    }
    global class haCampaign{
        public String id;
        public String name;
        public String slug;
        public String type;
        public String state;
        public Decimal funding;
        public Integer supporters;
        public String url;
        public String id_organism;
        public String slug_organism;
        public Datetime creation_date;
        public Datetime last_update;
        public String place_name;
        public String place_address;
        public String place_city;
        public String place_zipcode;
        public String place_country;
        public Datetime start_date;
        public Datetime end_date;
    }
}