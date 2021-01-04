@isTest
public class DocHubMockForSearchController implements HttpCalloutMock{
	public static final String SEARCH_URL = DocHubHelper.API_URL +  DocHubHelper.PROXY_TENANT + '/api/document/' + DocHubHelper.ORGANIZATION_ID + '/search?q=';
	public Boolean temp = true;

	public HTTPResponse respond(HTTPRequest req) {
		HttpResponse res = new HttpResponse();
		
		res.setBody(getJsonResponse(req.getEndpoint()));
		return res;
	}   

	public static String getJsonResponse (String url){
		Map<String, String> mapResponse = new Map<String,String>{
			SEARCH_URL + 'test' => '{"status":"Error","error":{"message":"Error message","original":{"message":"Error message"}}}',
			SEARCH_URL + 'testKey' => '{"status":"Success","result":[{"id":3,"documentId":"12345qwerty","connectionId":1,"name":"Document 1 with <i><strong>query highlighted</strong></i>","version":"29","publishedDate":"2020-09-16T09:05:28.022Z","status":"published","publishes":9,"shows":30,"fragments":["text fragment with <i><strong>query highlighted</strong></i>","text fragment with <i><strong>query highlighted</strong></i>","text fragment with <i><strong>query highlighted</strong></i>","text fragment with <i><strong>query highlighted</strong></i>","text fragment with <i><strong>query highlighted</strong></i>"]}]}'            
		};
		return mapResponse.get(url);
	}
}