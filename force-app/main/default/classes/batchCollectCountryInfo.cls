/**********************************************************************************************************************

**********************************************************************************************************************/
global class batchCollectCountryInfo implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts
{

    private final string BASERESTURL = 'https://restcountries.com/v2/';
    private string fullURL;

    private string queryu;  //used in queryLocator

    private CountyURLBuilder__mdt cmdt;
    global integer batchJobcount = 0;

/**************************************************
constructor. read the CustomMetadata to build  URL

https://restcountries.com/v2/all
https://restcountries.com/v2/regionalbloc/eu
 https://restcountries.com/v2/alpha?codes=at,hu,it
*************************************************/
public batchCollectCountryInfo()
    {
      List<CountyURLBuilder__mdt> cmdt = [Select command__c,parameter__c from CountyURLBuilder__mdt 
                                          where Active__c = true
                                          limit 1
                                         ];
    if(cmdt != NULL && cmdt.size() == 1)
       {
        fullURL = BASERESTURL + cmdt[0].command__c;
        if(cmdt[0].parameter__c != null)
        fullURL = fullURL + cmdt[0].parameter__c;
       }  
    else
       {
        fullURL = BASERESTURL +'regionalbloc/eu' ; //should be ALL
       }   
       
    }
    
    /***************************************************************
    
    ***************************************************************/      
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
       String query = BuildQueryLocator();
       return Database.getQueryLocator(query);
    }
    
    /*************************************************************************
    make the callout depending on the custom setting and currentCountry    
    *************************************************************************/    
    global void execute(Database.BatchableContext BC, List<CCountry__c> scope) 
    {
      //when the batch run for the first time there is  no  CCountry__c
      //records at all so the batch body  wil not run. We have to check
      batchJobcount++;  //just to be sure that we have at least 1 job.

      /******************************************************************
       convert the returned list into a map  where Key is the Country Code 
      and values are th CCountry__c record. we will use  this  to compare
      ther current records with the values  returned by the REST API call
      *******************************************************************/
      Map<String,CCountry__c> mapCCountry = new Map<String,CCountry__c>();

      for(CCountry__c restcountry :scope)
         {
         mapCCountry.put(restcountry.CountryCode2__c,restcountry);   //nsmer or alpha2Code ?
         }   
  

      //make the callout then see if and parameter of a country has changed 
      List<CCountry__c> restCountries = RestUtilities.getCountries(fullURL); 
  

      List<CCountry__c> Countries2Update = BuildCountry2Update(restCountries,mapCCountry);
       
   

      if(Countries2Update.size() > 0)
         {
         List<Database.UpsertResult> dbusr = Database.Upsert(Countries2Update,CCountry__c.CountryCode2__c); 
           //we can do something with the upsertresult if we want to collect statistics or do errorhandling. 
         }
         
    }


    /***********************************************
    when the batch run for the first time the  body  
    of the batch do not run so we have to handle the 
    REST call from here.  (batchJobcount == 0)
    ***********************************************/ 
    global void finish(Database.BatchableContext BC) 
    {  
      if(batchJobcount == 0)    
        {
         fullURL = 'https://restcountries.com/v2/regionalbloc/eu'; 
         List<CCountry__c> restCountries = RestUtilities.getCountries(fullURL);   
         List<Database.UpsertResult> dbusr = Database.Upsert(restCountries,CCountry__c.CountryCode2__c,false); 
        }
 
    }

    /*********************************
     Method looks useless in this case
     but I use to build dynamic queries
     in my batches
    *********************************/
    private string BuildQueryLocator()
    {
 
    queryu = 'Select Name,Capital_City__c,CountryCode2__c,CountryCode3__c,Region__c,SubRegion__c,RegionalBlock__c from CCountry__c order by name';
 
    return queryu; 
    }

    /*****************************************************************
    Check if any parameter if the country has chnaged
    I ound this very unliklelly. I these key elements  rarely chnage 
    ina countries.  Maybe the capital once in a century or maybe the
    Regional block 
    *****************************************************************/
    private Boolean HasChanged(CCountry__c source, CCountry__c target)
    {

    if(source.Region__c != target.Region__c) 
       return true;

    if(source.SubRegion__c != target.SubRegion__c) 
       return true;
       
    if(source.RegionalBlock__c != target.RegionalBlock__c) 
       return true;    

    if(source.name != target.name) 
       return true;

    if(source.Capital_City__c != target.Capital_City__c) 
       return true;       

    if(source.CountryCode2__c != target.CountryCode2__c) 
       return true;    
       
    if(source.CountryCode3__c != target.CountryCode3__c) 
       return true;        
       
    return false;      
    }   
    
   /*****************************************************************************************************************
   compare the exisitng counties details against the date received from the REST call 

   Param1: restcountries read from the REST API
   Param2: mapCCountry obtained from database CCountry__c  in the query locator
   *****************************************************************************************************************/
   private List<CCountry__c> BuildCountry2Update(List<CCountry__c> restcountries,Map<String,CCountry__c> mapCCountry)
    {
      List<CCountry__c> retval = new List<CCountry__c>();   
    
      for(CCountry__c restCountry :restCountries)
      {
       String cname = restcountry.name;    //Name or alpha2Code ?
       String code2 = restcountry.CountryCode2__c;       

       CCountry__c existingCountry;
       if(mapCCountry != NULL)
          existingCountry = mapCCountry.get(code2); //cname or code2 ?

       if(existingCountry == NULL)
         {
         retval.add(restcountry); //brand new country
         }
      else
         {
          if(HasChanged(existingCountry,restCountry) == true)
          retval.add(restcountry);
         }   
      } 

      return retval;
    } 


}