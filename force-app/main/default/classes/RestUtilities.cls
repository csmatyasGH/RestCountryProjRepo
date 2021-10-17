public without sharing class RestUtilities 
{

/**********************************************************
method will be invoked from the batch class 
**********************************************************/    
public static List<CCountry__c> getCountries(String theUrl)
{
    List<CCountry__c> retval = new List<CCountry__c>();
    System.Debug('CSABA start Callout');

    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(theUrl);
    request.setMethod('GET');
    HttpResponse response = http.send(request);
    //System.debug('CSABA HTP Response: ' + response.getBody());
    
    if (response.getStatusCode() == 200)
    {
        String JSONs = response.getBody();
        System.debug('JSONu = ' + JSONs);

        //convert the JSON into a class
        List<jsonCountryWrapper> countirsFromJson = (List<jsonCountryWrapper>)JSON.deserialize(JSONs,List<jsonCountryWrapper>.class);

        for(jsonCountryWrapper jci :countirsFromJson)
        {
        CCountry__c CcountryItem = jci.converttoCCountry();
        retval.add(CcountryItem);            
        }         
    }
    else 
    {
     //do somerthing ???
     System.Debug('CSABA REST call status' + response.getStatusCode());
     return null;  
    }
 
    return retval;
}


/****************************************************************
Method is invoked from the Change Data Capture trigger
It collects the CCountry records belonging to the passed IDs then 
get the List of Leads  where the Countrz match with the CCountry 
record Country field  

Param1: CCountryIds  CCountry__c record ids
****************************************************************/
public static void PassRestCountry2Leads(Set<String> CCountryIds)
{
    List<CCountry__c> changedCountries = [Select Id,Name,CountryCode2__c,CountryCode3__c,Capital_City__c,
                                        Region__c,SubRegion__c,RegionalBlock__c from CCountry__c
                                        where id in :CCountryIds ];

    Map<String,CCountry__c> mapC2C = new Map<String,CCountry__c>();
    for(CCountry__c theCountry :changedCountries)
    {
    mapC2C.put(theCountry.name,theCountry); 
    }

    
    List<Lead> Leads4Countries = [Select id, Country,CapitalCity__c,Region__c,
                                CountryCode2__c,CountryCode3__c,SubRegion__c,RegionalBloc__c
                                from Lead where Country in :mapC2C.keySet()]; 

    for(Lead theLead :Leads4Countries)
    {
    String LeadCountry = theLead.Country; 
    CCountry__c rectCountry = mapC2C.get(LeadCountry);
    //pass the values from Lead Countries to the Lead   
    theLead.CapitalCity__c = rectCountry.Capital_City__c;
    theLead.CountryCode2__c = rectCountry.CountryCode2__c;
    theLead.CountryCode3__c = rectCountry.CountryCode3__c;
    theLead.Region__c = rectCountry.Region__c;
    theLead.SubRegion__c = rectCountry.SubRegion__c;
    theLead.RegionalBloc__c = rectCountry.RegionalBlock__c;
    }

    /*************************************************************************
    In real live this might create problems. In a prod org the number of Leads 
    migth be huge, so we might reach some limits. We migth broke List in pieces
    *************************************************************************/
    List<Database.SaveResult> dbsres = Database.update(Leads4Countries,false);

}



}