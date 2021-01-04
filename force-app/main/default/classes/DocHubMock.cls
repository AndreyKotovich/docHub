@isTest
public class DocHubMock implements HttpCalloutMock {

	public HTTPResponse respond(HTTPRequest req) {
		HttpResponse res = new HttpResponse();
		
		if (req.getEndpoint() == 'callout:DocHubUrl/register/key/00D2w00000FaTZZEA3') {
			res.setBody('{"status":"Success","result":{"authSignature":"TEST","timestamp":"TEST"}}');
		
		} else if (req.getEndpoint() == 'callout:DocHubUrl/register/tenant/00D2w00000FaTZZEA3') {
			res.setBody('{"status":"Success","result":"TEST"}');
		}
		
		return res;
	}
}