@isTest
/********************************************************
Test class does not allowe callOut so we use this Mock
class which build a fake response which looks like a real
one.
I removed from the Rest Body the majority of the fields to 
keep is small and readable

Probably I should have created a non-success response too
********************************************************/
global class RestCountriesMock implements HttpCalloutMock 
{

    global HTTPResponse respond(HTTPRequest request) 
       {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('[{ "name": "Hungary", "alpha2Code": "HU", "alpha3Code": "HUN","capital": "Budapest", "subregion": "Central Europe","region": "Europe", "regionalBlocs": [ {"acronym": "EU", "name": "European Union"}] }]');
        response.setStatusCode(200);
        return response; 
       }
}