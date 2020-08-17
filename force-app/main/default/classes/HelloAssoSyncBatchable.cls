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
        if (job.NumberOfErrors > 0 ) {
            npsp.ERR_Handler_API.processError(new applicationException('La synchronization des paiements HelloAsso a échoué avec '+ job.NumberOfErrors + ' erreur(s).\n\nJob ID: '+ job.Id +'\nMessage: '+ job.ExtendedStatus +'\n\n'),'HA');
        }
    }
    public class applicationException extends Exception {} 
}