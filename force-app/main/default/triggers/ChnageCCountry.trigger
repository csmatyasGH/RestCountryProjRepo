/*************************************************************
This is a PlatformEvent type of trigger generated automatically
when something has changed on the CCountry__c object.
We used it to Collect all Leads where the Country  field match 
with the CCountry__c  record  and  update the relates field(s) 
on the Lead
 ************************************************************/
trigger ChnageCCountry on CCountry__ChangeEvent (after insert) 
{
    List<CCountry__ChangeEvent> changes = Trigger.new;

    System.Debug('CSABA chnage Data Capture trigger start');
    
    Set<String> recIds = new Set<String>();
    
    for (CCountry__ChangeEvent change :changes) 
    {
        /****************************************************************
         Why we have multiple Ids? Well, usually we don't but if  in the 
         same transaction several records "suffer" the same chnages the
         notifications are merged  into 1 Platform event
         ***************************************************************/
        List<String> recordIds = change.ChangeEventHeader.getRecordIds();
        recIds.addAll(recordIds);

    }  
    
         /****************************************************************
        In ChangeDataCapture is possible to check which fields has changed 
        and what is the Value. We do not care here. The CCountry__C object
        contains only those fields we are interested in, so the change in
        any of the fields is OK for us.      (VERIFY THIS ASSUMPTION!!!!)
        
        EventBus.ChangeEventHeader header = change.ChangeEventHeader;
        if (header.changetype == 'CREATE')
            {

            }
        else if ((header.changetype == 'UPDATE'))
            {
                for (String field : header.changedFields)
                {
                    change.get(field); 
                }

            }  
        ****************************************************************/    


        RestUtilities.PassRestCountry2Leads(recIds); 


}