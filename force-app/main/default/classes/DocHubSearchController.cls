public with sharing class DocHubSearchController {
	
	@AuraEnabled
	public static String getNamespacePrefix() {
		return DocHubHelper.getNamespacePrefix();		
	}

	@AuraEnabled
	public static Map<String, Object> searchDocuments(String searchKey) {
		String url = DocHubHelper.API_URL + DocHubHelper.PROXY_TENANT +
			'/api/document/' + DocHubHelper.ORGANIZATION_ID + '/search?q=' + searchKey;
		String timestamp = String.valueOf(Datetime.newInstance(Datetime.now().dateGMT(),Datetime.now().timeGmt()).getTime());
		String signature = DocHubHelper.createSignature(new List<String> {DocHubHelper.ORGANIZATION_ID, 'documentsearch', timestamp }, null);
		
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod('GET');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('timestamp', timestamp);
		req.setHeader('auth-signature', signature);

		HttpResponse res = h.send(req);
		Map<String,Object> response = new Map<String,Object>();
		System.debug('res.getBody() ' + res.getBody());
		try {

			Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
			List<Object> docList = (List<Object>)JSON.deserializeUntyped(JSON.serialize(resMap.get('result')));
			Set<String> docHubIds = new Set<String>();    
			Set<String> originIds = new Set<String>();                                                       
			for(Object doc : docList) {
				docHubIds.add(String.valueOf(((Map<String,Object>)doc).get('id')));
				originIds.add(String.valueOf(((Map<String,Object>)doc).get('documentId')));
			}

			List<Doc_Hub_Link__c> docHubList = [
				SELECT Id, Document_Name__c, View__c, Origin__c
				FROM Doc_Hub_Link__c 
				WHERE Hub_Document_Id__c IN:docHubIds AND Origin_Id__c IN :originIds AND Status__c  = 'Linked' 
				ORDER BY Document_Name__c
				LIMIT 50000 
			];

			response = new Map<String,Object> {
				'status' => 'Success',
				'result' => JSON.serialize(docHubList)
			};
			
		} 
		catch(Exception e) {
			response = new Map<String,Object> {
				'status' => 'Error',
				'error' => e.getMessage()
			};
		}

		System.debug('response ' + response);

		return response;
	}

}