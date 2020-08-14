global class helloAssoManager implements Schedulable {
   
    public final Integer SYNC_BATCH_SIZE;
    private final String PAYMENT_PLATFORM_PICKLIST_VALUE ;
    private final String PAYMENT_METHOD_CHECK_PICKLIST_VALUE ;
    private final String PAYMENT_METHOD_SEPA_PICKLIST_VALUE ;
    private final String PAYMENT_METHOD_CB_PICKLIST_VALUE ;
    public final String HELLOASSO_ORGID ;
    public final String NOTIFICATION_EMAIL;
    public final Integer DAYS_DELTA;
    
    public helloAssoManager(){
        HelloAsso_Sync_Settings__mdt settings = [SELECT helloasso_orgid__c,Batch_Size__c, email__c, days_delta__c,Payment_Method_SEPA__C,Payment_Method_CB__C,Payment_Method_Check__C,Payment_Platform__c FROM HelloAsso_Sync_Settings__mdt Where DeveloperName='Main'];
        SYNC_BATCH_SIZE=settings.Batch_Size__c.intValue();
        NOTIFICATION_EMAIL=settings.email__c;
        DAYS_DELTA=settings.days_delta__c.intValue();
        PAYMENT_METHOD_CHECK_PICKLIST_VALUE=settings.Payment_Method_check__C;
        PAYMENT_METHOD_SEPA_PICKLIST_VALUE=settings.Payment_Method_SEPA__C;
        PAYMENT_METHOD_CB_PICKLIST_VALUE=settings.Payment_Method_CB__C;
        PAYMENT_PLATFORM_PICKLIST_VALUE=settings.Payment_Platform__c;
        HELLOASSO_ORGID=settings.helloasso_orgid__c;
    }
    
    //scheduled function
    global void execute(SchedulableContext SC) {
        doBatch();
      }

    public void doBatch() {
    	Database.executeBatch(new HelloAssoSyncBatchable(), 1); //1 because we will process 1 page at a time. the size of the page is definied by SYNC_BATCH_SIZE
	}
    
    public void processPaymentsBatch(List<payment> ps){
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

        list <payment> fps=mp.values();
        for(payment fp :fps){
            Boolean toProcess=false;
            for(action a:fp.actions){
                if(a.type=='DONATION' || a.type=='RECURRENT_DONATION'){//'RECURRENT_DONATION
                    toProcess=true;
                }
            }
            if(!toProcess)mp.remove(fp.id);
        }
        
        List<payment> ps_toprocess=mp.values();
        System.debug('map after filtering(size: '+ps_toprocess.size()+')');
        System.debug(ps_toprocess);
      	//process payments
        for(payment p : ps_toprocess){
            processPayment(p); 
        }
    }
 
 
    //PRIVATE functions
    private void ProcessPayment(payment p){
        System.Debug('Processing payment with Id '+p.ID);
        System.Debug(p);   
 
        for(action a: p.actions){
            System.Debug('Payment action');
            if(a.type=='DONATION' || a.type=='RECURRENT_DONATION'){
                //let's create the donation
                Opportunity donation=new Opportunity();
                
               System.Debug('Contact (+household or Organization)');
               Contact con=new contact(); 
               List<contact> cs=[Select id,accountid,name,firstname,lastname,account.name,email,MailingStreet,mailingPostalCode,mailingCity,mailingCountry,description from contact where email=:p.payer_email OR npe01__AlternateEmail__c=:p.payer_email OR npe01__HomeEmail__c=:p.payer_email OR npe01__WorkEmail__c=:p.payer_email];//FOR UPDATE
                if(cs.isEmpty()){
                        System.debug('Cant find contact for this paiement: '+p.id+' from '+p.payer_first_name +' '+p.payer_last_name+' '+p.payer_email+' and amount='+p.amount);
                        npsp.ERR_Handler_API.processError(new applicationException('Cant find contact for this paiement: '+p.id+' from '+p.payer_first_name +' '+p.payer_last_name+' '+p.payer_email+' and amount='+p.amount+' and date='+p.ddate.format()),'HA');
                        return;
                    //No contact with this email. let's create one.
                    /*System.Debug('Creating contact');
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
                    if(p.payer_birthdate!=null)con.Birthdate=p.payer_birthdate.date();
                    insert con;
                    
                    con=[SELECT firstname,lastname, email, account.name,accountid from contact where id=:con.id ];//FOR UPDATE
                    donation.npsp__Primary_Contact__c=con.id;
                    donation.Accountid=con.accountid;*/
                }
                else {
                    con=cs[0];
                    donation.npsp__Primary_Contact__c=cs[0].id;
                    donation.Accountid=cs[0].accountid;
                }
                System.Debug(con);
                if(a.type=='RECURRENT_DONATION'){
                    //looking for existing recurrent_donation
                    npe03__Recurring_Donation__c rd=new npe03__Recurring_Donation__c();
                    List <npe03__Recurring_Donation__c> rds=new List<npe03__Recurring_Donation__c>();
                    List <Account> mxaccos=[SELECT id,RecordType.DeveloperName from account where id = :con.accountid ];
                   
                    if(p.payer_is_society && (!mxaccos.isempty() && mxaccos[0].RecordType.DeveloperName=='Organization')){
                        rds=[SELECT id,npe03__Contact__c,npe03__Organization__c from npe03__Recurring_Donation__c where npe03__Organization__c=:con.accountid and npe03__Open_Ended_Status__c='Open' order by Id asc];// 
                    }
                    else{
                        rds=[SELECT id,npe03__Contact__c,npe03__Organization__c from npe03__Recurring_Donation__c where npe03__Contact__c=:con.id and npe03__Open_Ended_Status__c='Open' order by Id asc];//
                    }
                    
                    if(rds.isEmpty()){
                        System.debug('Cant find recurring donation for this paiement: '+p.id+' from '+p.payer_first_name +' '+p.payer_last_name+' and amount='+p.amount);
                        npsp.ERR_Handler_API.processError(new applicationException('Cant find recurring donation for this helloasso paiement: '+p.id+' from '+p.payer_first_name +' '+p.payer_last_name+' and amount='+p.amount+' and date='+p.ddate.format()),'HA');
                        return;
                    }
                    else rd=rds[0];
                    
                    list<opportunity> ds=[Select id,amount from opportunity where npe03__Recurring_Donation__c=:rd.id and (stageName='Pledged') AND CALENDAR_MONTH(CloseDate)=:p.ddate.month() AND CALENDAR_YEAR(CloseDate)=:p.ddate.year()];//closeDate<:p.ddate.date().addDays(5) and closeDate>:p.ddate.date().addDays(-5) ];//FOR UPDATE
                    if(ds.isEmpty()){
                        System.debug('cant find appropriate donation with recurring donation id: '+rd.id);
                        npsp.ERR_Handler_API.processError(new applicationException('cant find appropriate donation with recurring donation id: '+rd.id+' - HelloAsso.processPayment '+p.ID),'HA');
                        return;
                    }
                    else donation=ds[0];
                }
                else{
                    //let's update the donation
                    donation.name=p.payer_first_name+' '+p.payer_last_name+' donation '+p.ddate.format();
                    donation.amount=a.amount;   
                }
                
                donation.closedate=p.ddate.date();
                donation.StageName='Posted';
                donation.description='';
                
                switch on p.mean{
                    when 'CARD'{donation.Methode_Paiement__c=PAYMENT_METHOD_CB_PICKLIST_VALUE;}//
                    when 'CHECK'{donation.Methode_Paiement__c=PAYMENT_METHOD_CHECK_PICKLIST_VALUE;}
                    when 'SEPA'{donation.Methode_Paiement__c=PAYMENT_METHOD_SEPA_PICKLIST_VALUE;}
                }
                
                System.Debug('Donation');
                System.Debug(donation);
                upsert donation;
                
                //The payment is automatically created when inserting Donation - lets update payment.
                List<npe01__OppPayment__c> npspps=[SELECT id,npe01__Payment_Amount__c,npe01__Check_Reference_Number__c,npe01__Payment_Method__c,Plateforme_de_paiement__c from npe01__OppPayment__c where npe01__Opportunity__c=:donation.id];
                System.Debug('payments');
                
                if(npspps.isEmpty()){
                    // No payment. An error probably occured. That shouldn't happen.
                    System.Debug('No payment associated. There has been an issue.');
                    throw new applicationException('cant find appropriate payment for donation with  id: '+donation.id+' - HelloAsso.processPayment '+p.ID);
                }
                else{
                    npe01__OppPayment__c p1=npspps[0];
                    p1.npe01__Check_Reference_Number__c=p.id;
                    p1.Plateforme_de_paiement__c='Helloasso';
                    switch on p.mean{
                        when 'CARD'{p1.npe01__Payment_Method__c=PAYMENT_METHOD_CB_PICKLIST_VALUE;}//
                        when 'CHECK'{p1.npe01__Payment_Method__c=PAYMENT_METHOD_CHECK_PICKLIST_VALUE;}
                        when 'SEPA'{P1.npe01__Payment_Method__c=PAYMENT_METHOD_SEPA_PICKLIST_VALUE;}
                    }
                    update p1;
                    System.Debug(p1);
                }   
            } 
        } 
    }
    
    public Integer makeGetPagesCallout(String fromdate,Integer rpp) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        System.debug('callout:HelloAssoApi/v3/organizations/'+HELLOASSO_ORGID+'/payments.json?from='+fromdate+'&results_per_page='+rpp+'&page=1');
        request.setEndpoint('callout:HelloAssoApi/v3/organizations/'+HELLOASSO_ORGID+'/payments.json?from='+fromdate+'&results_per_page='+rpp+'&page=1');
        request.setMethod('GET');
        request.setTimeout(20000);
        HttpResponse response = http.send(request);    
        Integer pages = 0;
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            resource res= (resource) JSON.deserialize(response.getBody().replace('"date"','"ddate"'),resource.class);
            pages=res.pagination.max_page;
            System.debug('Number of pages:');
            System.debug(pages);           
        }
        else{
            if (response.getStatusCode() == 401 || response.getStatusCode() == 429) {
               //wait for 2 seconds and retry
               Long startTime = DateTime.now().getTime();
               Long finishTime = DateTime.now().getTime();
               while ((finishTime - startTime) < 10000) {
                   //sleep for 10s
                   finishTime = DateTime.now().getTime();
               }
               return makeGetPagesCallout(fromdate,rpp);
           }
           else throw new applicationException('API Response Code unhandled: '+response.getStatusCode());
       }
        return pages;
    } 
    
    public List<payment> makeGetPaymentsCallout(String fromdate,Integer rpp, String page) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        System.debug('callout:HelloAssoApi/v3/organizations/'+HELLOASSO_ORGID+'/payments.json?from='+fromdate+'&results_per_page='+rpp+'&page='+page);
        request.setEndpoint('callout:HelloAssoApi/v3/organizations/'+HELLOASSO_ORGID+'/payments.json?from='+fromdate+'&results_per_page='+rpp+'&page='+page);
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
        else{
            if (response.getStatusCode() == 401 || response.getStatusCode() == 429) {
                //wait for 2 seconds and retry
                Long startTime = DateTime.now().getTime();
                Long finishTime = DateTime.now().getTime();
                while ((finishTime - startTime) < 10000) {
                    //sleep for 10s
                    finishTime = DateTime.now().getTime();
                }
                return makeGetPaymentsCallout(fromdate,rpp,page);
            }
            else throw new applicationException('API Response Code unhandled: '+response.getStatusCode());
        }
        return payments;
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
        public string mean; 
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
    public class applicationException extends Exception {}
}