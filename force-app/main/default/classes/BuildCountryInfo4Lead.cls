public class BuildCountryInfo4Lead 
{



    /******************************************************************************************************
    Method can be invoked from a PB on Lead when leads are created
    ******************************************************************************************************/
    @InvocableMethod(label='Update country Info' description='set country field based on CCountry records')
    public static void SetCountryInfo(List<Lead> leads)
    {
    Set<String> LeadCountries = new Set<String>();
    Set<ID> LeadIDs = new Set<ID>();    
    for(Lead theL :leads)
       {
        LeadCountries.add(theL.Country);
        LeadIDs.add(theL.id);
       }

    //collect the CCountry records for the above Countries
    Map<String,CCountry__c> mapC2C = new Map<String,CCountry__c>();
    For(CCountry__c  theCC :[Select Id,Name,CountryCode2__c,CountryCode3__c,Capital_City__c, Region__c,SubRegion__c,RegionalBlock__c from CCountry__c where Name in :LeadCountries ])
       {
        mapC2C.put(theCC.name,theCC); 
       }   
       
    List<Lead> Leads2Update = new List<Lead>();
    //we need to read  the Leads again because the record is not readable (or creat a new in memory lead)
    for(Lead theLead :leads)     
       {
        Lead theSameLard = new Lead(ID = theLead.id); 
         
        CCountry__c rectCountry = mapC2C.get(theLead.Country);
        if(rectCountry == null)
           continue;

        //pass the values from Lead Countries to the Lead   
        theSameLard.CapitalCity__c = rectCountry.Capital_City__c;
        theSameLard.CountryCode2__c = rectCountry.CountryCode2__c;
        theSameLard.CountryCode3__c = rectCountry.CountryCode3__c;
        theSameLard.Region__c = rectCountry.Region__c;
        theSameLard.SubRegion__c = rectCountry.SubRegion__c;
        theSameLard.RegionalBloc__c = rectCountry.RegionalBlock__c; 

        Leads2Update.add(theSameLard);
       }    
       
    /*************************************************************************
    this approach might create problems. If a big number of Leads are created
    (Marketo integration?) so we might reach some limits. invoking this method  
    from Lead creation context migth be problematic. Put it into a scedulable.
    *************************************************************************/
    List<Database.SaveResult> dbsres = Database.update(Leads2Update,false);       
        
    }
  }