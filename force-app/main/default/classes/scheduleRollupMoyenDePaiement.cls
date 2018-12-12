global class scheduleRollupMoyenDePaiement Implements Schedulable{
    //SCHEDULED function to be moved in another class
      
    global void execute(SchedulableContext ctx) {    
        System.debug('processing Rollup moyen de paiement: ');   
        RollupMoyenPaiement b = new RollupMoyenPaiement(); //ur batch class
        database.executebatch(b); 
     }
}