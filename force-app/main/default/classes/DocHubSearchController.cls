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

		// Retrieve list of maximum 10K shared doc hub links records
		List<Doc_Hub_Link__c> docHubLinksListToSearch = [
				SELECT Id, Origin_Id__c, View__c, Hub_Document_Id__c, Origin__c, Document_Name__c
				FROM Doc_Hub_Link__c
				WHERE Status__c  = 'Linked'
				ORDER BY Document_Name__c
				LIMIT 10000
		];

		// Set of original document Ids for search request
		Set<String> docHubLinksOriginIds = new Set<String>();
		// Map of doc hub links ot theirs Ids
		Map<String, Doc_Hub_Link__c> docHubLinkToHubIdMap = new Map<String, Doc_Hub_Link__c>();

		if (!docHubLinksListToSearch.isEmpty()) {
			// Set list of original document ids and map of API Database ids and corresponding doc hub links
			for (Doc_Hub_Link__c docHubLink: docHubLinksListToSearch) {
				docHubLinksOriginIds.add(docHubLink.Origin_Id__c);
				docHubLinkToHubIdMap.put(docHubLink.Hub_Document_Id__c, docHubLink);
			}
		}

		Http http = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('timestamp', timestamp);
		req.setHeader('auth-signature', signature);
		req.setBody(JSON.serialize(docHubLinksOriginIds));

		HttpResponse res = http.send(req);
		Map<String,Object> response = new Map<String,Object>();
		System.debug('res.getBody() ' + res.getBody());

		try {
			Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
			// Response list of documents
			List<DocHubSearchController.SearchResultWrapper> docList = (List<DocHubSearchController.SearchResultWrapper>)JSON.deserialize(JSON.serialize(resMap.get('result')), List<DocHubSearchController.SearchResultWrapper>.class);
			// Result list of documents to render on the result page
			List<DocHubSearchController.SearchResultWrapper> docHubResultList = new List<DocHubSearchController.SearchResultWrapper>();

			// For each document in response list get doc hub link record and add
			// missing fields, also push the document to result list
			for (DocHubSearchController.SearchResultWrapper doc : docList) {
				Doc_Hub_Link__c docHubLink = docHubLinkToHubIdMap.get(doc.id);
				if (docHubLink != null) {
					doc.id = docHubLink.Id;
					doc.origin = docHubLink.Origin__c;
					doc.originalName = docHubLink.Document_Name__c;
					doc.url = docHubLink.View__c.split('"')[1];
					docHubResultList.add(doc);
				}
			}

			// Sort by name
			docHubResultList.sort();

			response = new Map<String,Object> {
				'status' => 'Success',
				'result' => JSON.serialize(docHubResultList)
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

	private class SearchResultWrapper implements Comparable {
		String name {set; get;}
		String originalName {set; get;}
		String id {set; get;}
		String documentId {set; get;}
		String origin {set; get;}
		String url {set; get;}
		List<String> fragments {set; get;}

		public Integer compareTo(Object objToCompare) {
			return originalName.toLowerCase().compareTo(((SearchResultWrapper) objToCompare).originalName.toLowerCase());
		}
	}
}