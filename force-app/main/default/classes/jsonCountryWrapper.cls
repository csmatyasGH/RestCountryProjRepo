/*******************************************
wrapper class for Json.  Take care that the
member  name should match exactly  the name
of the  memebers in the JSON  return body
No need to replicate all JSON members, just 
the ones we need
Taker care of  the INNER child elements too.
 * ****************************************/ 
public with sharing class jsonCountryWrapper 
{
    public jsonCountryWrapper() 
    {

    }

public string name;
public string alpha2Code;
public string alpha3Code;
public string capital;
public string region;
public string subregion;

public List<regionalBloc> regionalBlocs;



public class regionalBloc
 {
    public string acronym;
    public string name;
}

public CCountry__c converttoCCountry()
{
  CCountry__c retval = new CCountry__c();
  retval.name = name;
  retval.Capital_City__c = capital;

  retval.CountryCode2__c = alpha2Code;  
  retval.CountryCode3__c = alpha3Code; 
  
  retval.Region__c = region; 
  retval.SubRegion__c = subregion; 

  if(regionalBlocs.size() > 0)
    {
      retval.RegionalBlock__c = regionalBlocs[0].acronym; 
    }

  return retval;
}

    
}