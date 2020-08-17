global class HelloAssoSyncBatchable implements Database.Batchable<String>, Database.AllowsCallouts {
    global set<String> calloutPages=new Set<String>(); 
    @TestVisible
    private helloAssoManager service = new helloAssoManager();

    global Iterable<String> start(Database.BatchableContext context){
        
        String Fromdate=datetime.now().addDays(-service.DAYS_DELTA).format('yyyy-MM-dd\'T\'HH:mm:ss');
        if(Test.isRunningTest())Fromdate='yyyy-MM-dd\'T\'HH:mm:ss';
        //call and get the number of API response pages
        Integer pages = service.makeGetPagesCallout(Fromdate+'Z',service.SYNC_BATCH_SIZE);
        System.Debug(pages);
        for(Integer i=1;i<=pages;i++){
            calloutPages.add(i.format());
        }
        return (Iterable<String>)calloutPages;
    }

    global void execute(Database.BatchableContext context, String[] page) {
        System.debug(page);
        String Fromdate=datetime.now().addDays(-service.DAYS_DELTA).format('yyyy-MM-dd\'T\'HH:mm:ss');
        if(Test.isRunningTest())Fromdate='yyyy-MM-dd\'T\'HH:mm:ss';
        List<HelloAssoManager.payment> ps=service.makeGetPaymentsCallout(Fromdate+'Z',service.SYNC_BATCH_SIZE,page[0]);
        service.processPaymentsBatch(ps);
    }

    global void finish(Database.BatchableContext context) {
        // Check for errors and send an email if batch failed
        AsyncApexJob job = [SELECT Id, NumberOfErrors, ExtendedStatus FROM AsyncApexJob WHERE Id = :context.getJobId()];
        System.debug('HelloAsso sync job finished with '+ job.NumberOfErrors +' error(s)');
        if (job.NumberOfErrors > 0 || (Test.isRunningTest() && !runningInASandbox()) ) {
            String emailBody = 'La synchronization des paiements HelloAsso à échouée avec '+ job.NumberOfErrors + ' erreur(s).\n\n'+
                'Job ID: '+ job.Id +'\n'+
                'Message: '+ job.ExtendedStatus +'\n\n'+
                'Consultez les logs de Salesforce pour plus de détails.';
            sendEmailToAdmins('Echec de la synchronization HelloAsso', emailBody);
        }
    }

    @TestVisible
    private void sendEmailToAdmins(String subject, String body) {
        // Get admin emails
        List<String> adminEmails = new List<String>();
        adminEmails.add(service.NOTIFICATION_EMAIL);
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

    public static Boolean runningInASandbox() {
        return [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
      }
}