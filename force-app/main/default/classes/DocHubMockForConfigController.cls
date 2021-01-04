@isTest
public class DocHubMockForConfigController implements HttpCalloutMock {

	public HTTPResponse respond(HTTPRequest req) {
		HttpResponse res = new HttpResponse();
		res.setBody(getJsonResponse(req.getEndpoint()));
		return res;
	}
	
	public static String getJsonResponse (String url){
		Map<String, String> mapResponse = new Map<String,String>{
			DocHubHelper.API_URL + '/register/key/' + DocHubHelper.ORGANIZATION_ID => ' {"status":"Success","result":{"authSignature":"HQ14n35cTMf5afpVbguGgZ1NATM=","timestamp":"1604317132041"}}',
			DocHubHelper.API_URL + '/register/tenant/' + DocHubHelper.ORGANIZATION_ID => '{"status":"Success","result":"734ca0d0-e3e5-4b80-b666-6f9ca3b5e7b0"}'
		};
	return mapResponse.get(url);
	}
	
}