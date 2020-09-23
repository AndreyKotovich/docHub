public with sharing class DocHubSearchController {

	@AuraEnabled
	public static String getNamespacePrefix() {
		return DocHubHelper.getNamespacePrefix();
	}

	@AuraEnabled
	public static Map<String, Object> searchDocuments(String searchKey) {
		String url = DocHubHelper.API_URL + DocHubHelper.PROXY_TENANT +
			'/api/document/' + DocHubHelper.ORGANIZATION_ID + '/search?q=' + EncodingUtil.urlEncode(searchKey, 'UTF-8');
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
			List<DocHubSearchController.SearchResultWrapper> docList = (List<DocHubSearchController.SearchResultWrapper>)JSON.deserialize(JSON.serialize(resMap.get('result')), List<DocHubSearchController.SearchResultWrapper>.class);
			Map<String, DocHubSearchController.SearchResultWrapper> docMap = new Map<String, DocHubSearchController.SearchResultWrapper>();
			for(DocHubSearchController.SearchResultWrapper doc : docList) {
				docMap.put(doc.id, doc);
			}

			List<Doc_Hub_Link__c> docHubList = [
				SELECT Id, Document_Name__c, View__c, Origin__c, Hub_Document_Id__c
				FROM Doc_Hub_Link__c
				WHERE Hub_Document_Id__c IN :docMap.keySet() AND Status__c  = 'Linked'
				ORDER BY Document_Name__c
				LIMIT 50000
			];

			List<DocHubSearchController.SearchResultWrapper> docHubResponseList = new List<DocHubSearchController.SearchResultWrapper>();

			if (!docHubList.isEmpty()) {
				for (Doc_Hub_Link__c docHubLink: docHubList) {
					DocHubSearchController.SearchResultWrapper doc = docMap.get(docHubLink.Hub_Document_Id__c);
					doc.id = docHubLink.Id;
					doc.origin = docHubLink.Origin__c;
					doc.url = docHubLink.View__c.split('"')[1];
					docHubResponseList.add(doc);
				}
			}

			response = new Map<String,Object> {
				'status' => 'Success',
				'result' => JSON.serialize(docHubResponseList)
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

	private class SearchResultWrapper {
		String name {set; get;}
		String id {set; get;}
		String documentId {set; get;}
		String origin {set; get;}
		String url {set; get;}
		List<String> fragments {set; get;}
	}
}