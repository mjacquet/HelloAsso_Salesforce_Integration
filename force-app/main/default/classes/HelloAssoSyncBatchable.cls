global class HelloAssoSyncBatchable implements Database.Batchable<String>, Database.AllowsCallouts {
    global set<String> calloutPages=new Set<String>(); 
    @TestVisible
    private helloAssoManager service = new helloAssoManager();

   /* global HelloAssoSyncBatchable(String query) {
        this.query = query;
    }*/

    global Iterable<String> start(Database.BatchableContext context){
        //This should be in the constructor or from a custom setting
        system.debug('userinfo');
        system.debug(Userinfo.getUserId());
        system.debug(Userinfo.getUserName());
        
        datetime myDateTime = datetime.now();
        mydatetime=myDateTime.addHours(-48);
       // String Fromdate=mydateTime.format('yyyy-MM-dd\'T\'HH:mm:ss');
         String Fromdate=mydateTime.format('2019-01-01\'T\'00:00:00');
        
        //call and get the pages
        //10 is the number of results per page. should come from custom setting
        Integer pages = helloAssoManager.makeGetPagesCallout(Fromdate+'Z','10');
        System.Debug(pages);
        for(Integer i=1;i<=pages;i++){
            calloutPages.add(i.format());
        }
        return (Iterable<String>)calloutPages;
    }

    global void execute(Database.BatchableContext context, String[] page) {
        System.debug(page);
        system.debug('userinfo');
        system.debug(Userinfo.getUserId());
        system.debug(Userinfo.getUserName());
        datetime myDateTime = datetime.now();
        mydatetime=myDateTime.addHours(-48);
        String Fromdate=mydateTime.format('2019-01-01\'T\'00:00:00');
        List<HelloAssoManager.payment> ps=HelloAssoManager.makeGetPaymentsCallout(Fromdate+'Z','10',page[0]);
        HelloAssoManager.processPaymentsBatch(ps);
        /*for (Contact contact : batchContacts) {
            service.syncContact(contact);
        }*/
    }

    global void finish(Database.BatchableContext context) {
        // Check for errors and send an email if batch failed
        AsyncApexJob job = [SELECT Id, NumberOfErrors, ExtendedStatus FROM AsyncApexJob WHERE Id = :context.getJobId()];
        System.debug('SlimPay sync job finished with '+ job.NumberOfErrors +' error(s)');
        if (job.NumberOfErrors > 0) {
            String emailBody = 'La synchronization des paiements SlimPay à échouée avec '+ job.NumberOfErrors + ' erreur(s).\n\n'+
                'Job ID: '+ job.Id +'\n'+
                'Message: '+ job.ExtendedStatus +'\n\n'+
                'Consultez les logs de Salesforce pour plus de détails.';
            sendEmailToAdmins('Echec de la synchronization SlimPay', emailBody);
        }
    }

    @TestVisible
    private void sendEmailToAdmins(String subject, String body) {
        // Get admin emails
        List<String> adminEmails = new List<String>();
        for (User admin : [SELECT Email FROM User WHERE Profile.Name = 'System Administrator']) {
           // adminEmails.add(admin.Email);
        }
        adminEmails.add('mjacquet@salesforce.com');//to be changed, but need to put in prod
        // Send email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(adminEmails);
        email.setSubject(subject);
        email.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
    }

    global static Id getRunningJobId() {
        String batchClassName = HelloAssoSyncBatchable.class.getName();
        Id batchClassId = [SELECT Id FROM ApexClass WHERE Name =: batchClassName].Id;
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE Status NOT IN ('Aborted', 'Completed', 'Failed') AND ApexClassId =: batchClassId];
        return (jobs.size() == 0) ? null : jobs[0].Id;
    }
}