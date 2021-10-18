@isTest 
private class RestCountrIesTest 
{

    
    @testSetup static void BuildTesrtRecords() 
    {
    //create some leads
    List<Lead> Leads = new List<Lead> ();
    List<String> countries = new List<String>{'Austria', 'Germany', 'Hungary'};
    for(integer i = 0; i<3; i++)
        {
            Lead lidu = new Lead();
            lidu.Lastname = 'Lead_LN' + String.valueof(i);
            lidu.Country = countries[i];
            lidu.LeadSource = 'Web';
            lidu.Company = 'Home_' + String.valueof(i);
             Leads.add(lidu);
        }
    insert Leads;

    //check if  the owner since was set. We have to refresh it
    Lead lidu = [Select id,Owner_Since__c  from LEad limit 1];
    System.assertnotEquals(lidu.Owner_Since__c,NULL);
    }
 


    //{} []
    /********************************************************************************************************
    NOT TEST CLASS. wE USE IT TO TEST  THE CONVERSION AND GET  SOME TEST CCountry RECORDS FOR OTHER PURPOSES.
    param1: count:  number of records 2  create
    param2: countries 'country1Code/Country1Name,....,countryNCode/CountryNName'
     *******************************************************************************************************/
    private static List<jsonCountryWrapper> createTestWrapperCountries(integer count, List<String> countries)
    {
    List<jsonCountryWrapper> wrapperCs = new List<jsonCountryWrapper>();
    for(integer i = 0; i< count; i++)
        {
            jsonCountryWrapper wr = new jsonCountryWrapper();
            wr.regionalBlocs = new List<jsonCountryWrapper.regionalBloc>();          
            string[] countryNameCode = countries[i].split('/');
            wr.alpha2Code= countryNameCode[0];            
            wr.name = countryNameCode[1];


            wr.alpha3Code = 'C3' + String.valueof(i);
            wr.capital = 'Capital_' + String.valueof(i);
            wr.region = 'region_' + String.valueof(i);
            wr.subregion = 'SubRegion_' + String.valueof(i);

            jsonCountryWrapper.regionalBloc rb = new jsonCountryWrapper.regionalBloc();
            rb.acronym = 'acr_1' + String.valueof(i);
            wr.regionalBlocs.add(rb);

            wrapperCs.add(wr);           
        }

     return wrapperCs;
    }

    @isTest 
    /***************************************************
    Test converttoCCountry meth. from jsonCountryWrapper
    ***************************************************/
    private static void TestWraapperCCountryConverter() 
    {
        List<String> countries = new List<String>{'AT/Austria','DE/Germany','HU/Hungary'};
        List<jsonCountryWrapper> wrappers = createTestWrapperCountries(3,countries);
        System.assertEquals(wrappers.size(),3);
         
        CCountry__c converted = wrappers[0].converttoCCountry();
        System.assertEquals(converted.name,'Austria');
        System.assertEquals(converted.CountryCode2__c,'AT'); 
        
        //alter a bit the Country code, insert and pass it to Lead
        converted.CountryCode2__c = 'XX';
        //To test űDataChnageCapture trigger we need the below.
        Test.enableChangeDataCapture();
        insert converted;
        Test.getEventBus().deliver();  
        
        Set<String> recIds = new Set<String>();
        recIds.add(converted.id);
         
        RestUtilities.PassRestCountry2Leads(recIds);

        Lead ATLead = [Select id ,CountryCode2__c from Lead where Country = 'Austria'];
        System.assertnotEquals(ATLead,NULL);
        System.assertEquals(ATLead.CountryCode2__c,'XX');
    }    


    @isTest 
    /*********************************************
    Test getCountries method  from class
    RestUtilities
    *********************************************/
    private static void TestRestUtilGetCountries() 
    {
        List<CCountry__c> restcs;

        Test.startTest(); //since we do  an insert before (create test records) we need to start another session

        Test.setMock(HttpCalloutMock.class, new RestCountriesMock());
        // Call the method that performs the callout
        restcs = RestUtilities.getCountries('https://restcountries.com/v2/alpha?codes=at,hu');

        Test.stopTest(); 

        insert restcs;
        Set<String> countryIDs = new Set<String>();
        for(CCountry__c theC :restcs)
          {
            countryIDs.add(theC.id);
          }
        RestUtilities.PassRestCountry2Leads(countryIDs);


    }   
    
    @isTest    
    /********************************

    ********************************/
    private static void Testbatch_1() 
    {
     //without custommetadatatype 
     batchCollectCountryInfo batchu = new batchCollectCountryInfo();
     Test.startTest(); //since we do  an insert before (create test records) we need to start another session;

     Test.setMock(HttpCalloutMock.class, new RestCountriesMock());
     Id idu = Database.ExecuteBatch(batchu,100);

     Test.stopTest();      

    }  
 

    @isTest        
    /********************************
    before calling batch we assure we
    have some countries needed by the
    QuewryLocatior
    ********************************/
    private static void Testbatch_2() 
    {
        //create some CCountry records to be available in the batch query Locator 
        List<String> countries = new List<String>{'AT/AustriaXX','HU/HungaryXX'};  //alter a bit the Coutry name to simulate change    
        List<jsonCountryWrapper> wrappers = createTestWrapperCountries(2,countries);
        
        List<CCountry__c> CCountries = new List<CCountry__c>();
        for(jsonCountryWrapper wr :wrappers)
            {
            CCountry__c converted = wr.converttoCCountry();  
            CCountries.add(converted);        
            }
        insert CCountries;
        
        Testbatch_1();
    }  

    @isTest    
    /********************************
    Need for Coverage. Fake test
    ********************************/
    private static void TesthasChanged() 
    {
        batchCollectCountryInfo batch = new batchCollectCountryInfo();
        //we are not going to run the batch, Just test one of its method

        CCountry__c source = new CCountry__c();
        source.CountryCode3__c = 'source';

        CCountry__c target = new CCountry__c();
        target.CountryCode3__c = 'target';        
        
        Boolean change = batch.HasChanged(source,target);
        System.assertEquals(change,true);
    } 
    
    @isTest    
    /*************************************
    create a CCountry then create a Lead
    and check if the country info fields
    are populated. Test the PRocess Builder
    and the invocable
    *************************************/
    private static void TestLeadCreation() 
    {
    List<String> countries = new List<String>{'HU/Hungary'};
    List<jsonCountryWrapper> wrappers = createTestWrapperCountries(1,countries);
    CCountry__c converted = wrappers[0].converttoCCountry();
    insert converted;

    Lead lidu = new Lead();
    lidu.Lastname = 'MyLead';
    lidu.Country = 'Hungary';
    lidu.LeadSource = 'Web';
    lidu.Company = 'HomeLead';

    insert lidu;

    lidu = [Select id,CapitalCity__c from Lead where Lastname = 'MyLead' limit 1];
    system.assertnotEquals(lidu.CapitalCity__c,null);
    }    
             

}