@isTest
public class DocHubMockForConnectionController implements HttpCalloutMock {
	public static final String DOCUMENT_URL = DocHubHelper.API_URL + DocHubHelper.PROXY_TENANT + '/api/document/' + DocHubHelper.ORGANIZATION_ID;
	public static final String CONNECTION_URL = DocHubHelper.API_URL + DocHubHelper.PROXY_TENANT + '/api/connection/' + DocHubHelper.ORGANIZATION_ID;

	protected Map<String, String> responseHeaders;
	public HTTPResponse respond(HTTPRequest req) {
		System.assertNotEquals(null, req);
		HttpResponse res = new HttpResponse();
		
		res.setBody(getJsonResponse(req.getEndpoint()));
		return res;
	}

	public static String getJsonResponse (String url){
		Map<String, String> mapResponse = new Map<String,String>{
			DOCUMENT_URL + '/9/fetch/1xRc2xVCMG72uH8EIskmftTNHlvb5ck4JI77CYFMwHhE?state=eyJhdXRvUHVibGlzaCI6dHJ1ZSwiY3JlYXRlZEJ5IjoiVXNlciBVc2VyIn0=' => '{"status":"Success","result":"d9cc6b5a-9b04-4981-aa11-e9fecee56afb"}', //DocumentFetchTest
			CONNECTION_URL + '/create' => '{"status":"Success","result":{"id":10,"tenantId":"00D2w00000FaTZZEA3","name":"test","origin":"GoogleDrive","createdBy":"Alex .","email":"testEmail@gmail.com","links":1,"publishes":1,"shows":0,"status":true,"typeAccess":"ServiceAccount"},"message":"Connection updated"}', //createConnectionTest
			DOCUMENT_URL + '/9/link/1PMu-WYBf0Aexv0SQFwUrVvzUomRhH58iNINiFflX9Kw' => '{"status":"Success","result":{"id":48,"connectionId":9,"documentId":"1PMu-WYBf0Aexv0SQFwUrVvzUomRhH58iNINiFflX9Kw","name":"test","version":"2849","publishedDate":null,"status":"being published","publishes":0,"shows":1},"message":"Document updated"}', //linkDocumentTest
			DOCUMENT_URL + '/9/publish/1xRc2xVCMG72uH8EIskmftTNHlvb5ck4JI77CYFMwHhE' => '{"status":"Success","result":{"id":45,"connectionId":9,"documentId":"1xRc2xVCMG72uH8EIskmftTNHlvb5ck4JI77CYFMwHhE","name":"test","version":"6","publishedDate":"2020-10-30T14:06:05.511Z","status":"published","publishes":2,"shows":7},"message":"Document updated"}', //publishDocumentTest
			CONNECTION_URL + '/list' => '{"status":"Success","result":[{"id":10,"tenantId":"00D2w00000FaTZZEA3","name":"test","origin":"GoogleDrive","createdBy":"Alex .","email":"test@gmail.com","links":1,"publishes":1,"shows":0,"status":true,"typeAccess":"ServiceAccount"},{"id":9,"tenantId":"00D2w00000FaTZZEA3","name":"1","origin":"GoogleDrive","createdBy":"Alex .","email":"testk@gmail.com","status":true,"typeAccess":"OAuth2"}]}', //getConnectionListTest
			CONNECTION_URL + '/get/' + '9' => '{"status":"Success","result":{"id":9,"tenantId":"00D2w00000FaTZZEA3","name":"test","origin":"GoogleDrive","createdBy":"Alex .","email":"test@gmail.com","links":4,"publishes":4,"shows":31,"status":true,"typeAccess":"OAuth2"}}', //getConnectionIdInfoTest
			DOCUMENT_URL + '/9/list?state=eyJwYWdlU2l6ZSI6MjAsInBhZ2VUb2tlbiI6IiIsInNlYXJjaEtleSI6IiJ9' => '{"status":"Success","result":{"files":[{"id":"1pXS1","name":"test","mimeType":"application/vnd.google-apps.folder","trashed":false,"parents":["0AKCmH_v0D1BWUk9PVA"],"version":"5","createdTime":"2019-11-03T17:14:04.872Z","modifiedTime":"2019-11-03T17:14:04.872Z","owners":[{"kind":"drive#user","me":true,"permissionId":"161057","emailAddress":"test@gmail.com"}]}]}}', //getConnectionDocumentListTest
			DOCUMENT_URL + '/9/get/1xRc2xVCMG72uH8EIskmftTNHlvb5ck4JI77CYFMwHhE' => '{"status":"Success","result":{"files":[{"id":"1pXS5nX_T1B1","name":"test","mimeType":"application/vnd.google-apps.folder","trashed":false,"parents":["0AKCmH_v0D1BWUk9PVA"],"version":"5","createdTime":"2019-11-03T17:14:04.872Z","modifiedTime":"2019-11-03T17:14:04.872Z","owners":[{"kind":"drive#user","me":true,"permissionId":"161","emailAddress":"test@gmail.com"}]}]}}', //getDocumentInfoTest
			DOCUMENT_URL + '/testConnectionId/fetch/testOriginIdc?state=eyJhdXRvUHVibGlzaCI6dHJ1ZSwiY3JlYXRlZEJ5IjoiVXNlciBVc2VyIn0=' => '{"status":"Error","error":{"message":"invalid input syntax for integer: testConnectionId"}}', //fetch ???
			CONNECTION_URL + '/get/idFail' => '{"status":"Error","error":{"message":"invalid input syntax for integer: idFail"}}', //getConnectionIdInfoTestFail
			DOCUMENT_URL + '/idFail/get/idFail' => '{"status":"Error","error":{"message":"invalid input syntax for integer: idFail"}}', //getDocumentInfoFail
			DOCUMENT_URL + '/idFail/list?state=eyJwYWdlU2l6ZSI6MjAsInBhZ2VUb2tlbiI6IiIsInNlYXJjaEtleSI6IiJ9' => '{"status":"Error","error":{"message":"invalid input syntax for integer: idFail"}}', //getConnectionDocumentListFailTest
			DOCUMENT_URL + '/9/link/idFileNotFound' => '{"status":"Error","error":{"message":"File not found: idFileNotFound"}}'
		};

		return mapResponse.get(url);
	}
}