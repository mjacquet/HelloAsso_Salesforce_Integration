({
    init : function(component, event, helper) {
        
    },
    dedup : function(component,event,helper){
        var d = component.get("v.simpleRecord");
       
         var action = component.get("c.processDuplicate");
     
        action.setParams({"dId": d.Id,"pId": d.ID_paiement__c,"dedup":false });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state == "SUCCESS"){
                console.log('success');
                $A.get("e.force:refreshView").fire();
                $A.get("e.force:closeQuickAction").fire();
            } else {
                component.set("v.hasErrors", true);
                console.log('errors');

                let errors = response.getError();
                console.log(JSON.parse(JSON.stringify(errors)));
                let message = 'Unknown error '; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    if(errors[0].message)message = errors[0].message;
  
                }
                if(errors[0].pageErrors){
                    errors[0].pageErrors.forEach( function(pageError) {
						message+=(pageError.message);						
					});
                }
                
                component.set("v.errorFromDedup", message);
            }
        });
        $A.enqueueAction(action);
        
    }
})