public class DocHubConnectionController {
	private static final String ORGANIZATION_ID =  UserInfo.getOrganizationId();
	private static final String CREATED_BY =  UserInfo.getName();
	private static final String API_URL = 'callout:ApiUrl';
	private static final String GOOGLE_DRIVE_AUTH = '/auth/google/authorize';
	private static final String CONNECTION_URL = API_URL + '/api/connection/' + ORGANIZATION_ID;
	private static final String DOCUMENT_URL = API_URL + '/api/document/' + ORGANIZATION_ID;

	
	@AuraEnabled
	public static Map<String, Object> createGoogleDriveAuthURL(Map<String, Object> generalData)  {
		generalData.put('orgId', ORGANIZATION_ID);
		generalData.put('createdBy', CREATED_BY);
		generalData.put('origin', 'Salesforce');

		String state = EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(generalData)));
		List<NamedCredential> urlNameCred = [SELECT DeveloperName, Endpoint FROM NamedCredential WHERE DeveloperName = 'ApiUrl'];
		if (urlNameCred.size() == 0) {
			return new Map<String, Object>{
				'Status' => 'Error',
				'Error' => 'Not found Named Credential: ApiUrl'
			};
		}
		return 	new Map<String, Object>{
			'Status' => 'Success',
			'Url' => urlNameCred[0].Endpoint + GOOGLE_DRIVE_AUTH + '?state='+state
		};
	}
	
	@AuraEnabled
	public static Map<String, Object> createConnection(Map<String, Object> generalData) {
		return postHttpRequest(new Map<String, Object> {
			'url' => CONNECTION_URL + '/create',
			'generalData' => generalData,
			'method' => 'Create Connection'
		});
	}
	
	@AuraEnabled
	public static Map<String, Object> unlinkDocument(String Id) {
		System.debug('unlinkDocument ' + Id);
		update new Doc_Hub_Link__c(Id = Id, Status__c = 'Unlinked');
		
		return new Map<String, Object> {
			'status' => 'Success',
			'message' => 'Record updated'
		};
	}

	@AuraEnabled
	public static Map<String, Object> linkDocument(Map<String, Object> generalData) {
		String connectionId = String.valueOf(generalData.get('connectionId'));
		String documentId  = String.valueOf(generalData.get('documentId')); 
		String Id = String.valueOf(generalData.get('Id'));
		Map<String, Object> resDocumentLink = postHttpRequest(new Map<String, Object> {
			'url' => DOCUMENT_URL + '/' + connectionId + '/link/' + documentId,
			'method' => 'Link Document'
		});

		if (resDocumentLink.get('status') == 'Success') {
			
			System.debug('linkDocument resDocumentLink ' + resDocumentLink );
			String nameDoc = String.valueOf(((Map<String, Object>)resDocumentLink.get('result')).get('name')); 
			String docId = String.valueOf(((Map<String, Object>)resDocumentLink.get('result')).get('documentId')); 
			String hubDocId = String.valueOf(((Map<String, Object>)resDocumentLink.get('result')).get('id')); 
			String publishedDate = String.valueOf(((Map<String, Object>)resDocumentLink.get('result')).get('publishedDate'));
			String connectId = String.valueOf(((Map<String, Object>)resDocumentLink.get('result')).get('connectionId'));
			Doc_Hub_Link__c docHub = new Doc_Hub_Link__c(
				Origin_Id__c = docId,
				Hub_Document_Id__c = hubDocId,
				Published_Date__c = !String.isBlank(publishedDate) ? Datetime.valueOf(publishedDate.replace('T',' ')) : null,
				Status__c = 'Linked',
				Connection_Id__c = connectId,
				Document_Name__c = nameDoc
			);

			if (!String.isBlank(Id)) {
				docHub.Id = Id;
			}
			Database.upsert( new List<Doc_Hub_Link__c> { docHub } , false);
		}

		return resDocumentLink;
	}

	
	@AuraEnabled
	public static Map<String, Object> publishDocument(String recordId) {
		if (!String.isBlank(recordId)) {
			Doc_Hub_Link__c dhl = [
				SELECT 
					Id, Connection_Id__c, Origin_Id__c, Status__c 
				FROM Doc_Hub_Link__c 
				WHERE Id = :recordId
			];

			if (dhl == null){
				//error
				return new Map<String, Object> {
					'status' => 'error',
					'message' => 'Record is not found'
				};
			}

			if (dhl.Status__c != 'Linked'){
				//error
				return new Map<String, Object> {
					'status' => 'error',
					'message' => 'Record is not linked'
				};
			}

			Map<String, Object> resDocumentLink = postHttpRequest(new Map<String, Object> {
				'url' => DOCUMENT_URL + '/' + String.valueOf(dhl.Connection_Id__c) + '/publish/' + dhl.Origin_Id__c,
				'method' => 'Publish Connection'
			});

			System.debug('resDocumentLink' + resDocumentLink);
			if (resDocumentLink.get('status') == 'Success') {
			
				String publishedDate = String.valueOf(((Map<String, Object>)resDocumentLink.get('result')).get('publishedDate'));
				Doc_Hub_Link__c docHub = new Doc_Hub_Link__c(
					Id = dhl.Id,
					Published_Date__c = Datetime.valueOf(publishedDate.replace('T',' '))
				);
				//Database.upsert( new List<Doc_Hub_Link__c> { docHub } , Doc_Hub_Link__c.Fields.Origin_Id__c, false);
				Database.update( new List<Doc_Hub_Link__c> { docHub } , false);
			} 
			return resDocumentLink;
		}
		//error
		return new Map<String, Object> {
			'status' => 'error',
			'message' => 'Record id is not found'
		};
	}
	
	@AuraEnabled
	public static String getConnectionList() {
		return getHttpRequest( new Map<String,Object> {
			'url' => CONNECTION_URL  + '/list',
			'method' => 'Get Connection List'
		});	
	}

	@AuraEnabled
	public static String getConnectionIdInfo(String connectionId) {
		return getHttpRequest( new Map<String,Object> {
			'url' => CONNECTION_URL + '/get/' + connectionId,
			'method' => 'Get Connection Info'
		});
	}

	@AuraEnabled
	public static String getDocumentInfo(String connectionId, String documentId) {
		return getHttpRequest( new Map<String,Object> {
			'url' => DOCUMENT_URL + '/' + connectionId + '/get/' + documentId,
			'method' => 'Get Document Info'
		});
	}
	
	public static String DocumentFetch(Map<String, Object> generalData) {
		
		String connectionId = String.valueOf(generalData.get('connectionId'));
		String documentId  = String.valueOf(generalData.get('documentId')); 
		Boolean autoPublish = Boolean.valueOf(generalData.get('autoPublish'));
		String state = EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(
			new Map<String, Object>{ 'createdBy' => CREATED_BY, 'autoPublish' => autoPublish }
		)));
		String res = getHttpRequest( new Map<String,Object> {
			'url' => DOCUMENT_URL + '/' + connectionId + '/fetch/' + documentId + '?state=' + state,
			'method' => 'Document Fetch'
		});
		return (String)JSON.deserializeUntyped(res);
	}

	@AuraEnabled
	public static String getConnectionDocumentList(String connectionId) {
		String jsonString = getHttpRequest( new Map<String,Object> {
			'url' => DOCUMENT_URL + '/' + connectionId + '/list',
			'method' => 'Get Connection Document List'
		});
		System.debug('jsonString ' + jsonString);
		List<Object> docList = (List<Object>)JSON.deserializeUntyped(jsonString);
		
		Set<String> docIds = new Set<String>();                                           
		for(Object doc : docList) {
			if (!String.isBlank(String.valueOf(((Map<String,Object>)doc).get('id')))) {
		 		docIds.add(String.valueOf(((Map<String,Object>)doc).get('id')));
			}
		}

		Map<String, String> docHubStatusMap = new Map<String, String>();
		Map<String, String> docHubIdMap = new Map<String, String>();
		List<Doc_Hub_Link__c> docHubList = [SELECT Id, Origin_Id__c, Status__c FROM Doc_Hub_Link__c WHERE Origin_Id__c IN :docIds];
		for (Doc_Hub_Link__c docHub: docHubList) {
			docHubStatusMap.put(docHub.Origin_Id__c, docHub.Status__c);
			docHubIdMap.put(docHub.Origin_Id__c, docHub.Id);
		}

		for(Object doc : docList) {
			if (!String.isBlank(String.valueOf(((Map<String,Object>)doc).get('id'))) && 
			docHubStatusMap.containsKey(String.valueOf(((Map<String,Object>)doc).get('id')))) {
				 ((Map<String,Object>) doc).put('Status__c',docHubStatusMap.get(String.valueOf(((Map<String,Object>)doc).get('id'))));
				 ((Map<String,Object>) doc).put('sfid',docHubIdMap.get(String.valueOf(((Map<String,Object>)doc).get('id'))));
			}
		}

		System.debug('docList' + docList);
		
		return JSON.serialize(docList);
	}

	@AuraEnabled
	public static String readJsonFileForGoogleServiceAccount(Id idContentDocument) {
		 
		ContentVersion objVersion = [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId =:idContentDocument];
		Map<String, Object> convertJsonToMap = new Map <string, object>();
		try {
			convertJsonToMap = (Map<String,Object>)JSON.deserializeUntyped(objVersion.VersionData.toString());
		}
		catch(Exception e) {
			System.debug('The following exception has occurred: ' + e.getMessage() +' on line number: '+e.getLineNumber());
		}
			
		return EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(convertJsonToMap)));
	}

	private static Map<String, Object> postHttpRequest (Map<String, Object> generalData) {
		String url = String.valueOf(generalData.get('url'));
		Map<String, Object> requestMap = generalData.containsKey('generalData') ? (Map<String,Object>) generalData.get('generalData') : new Map<String, Object>();
		requestMap.put('createdBy', CREATED_BY);
		requestMap.put('origin', 'Salesforce');
		String jsonRes = JSON.serialize(requestMap);
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/json');
		req.setTimeout(120000);
		req.setBody(jsonRes);
		HttpResponse res = h.send(req);
		String resJSON = res.getBody();
		
		insert createLog(new Map<String,Object> {
			'method' => generalData.get('method'),
			'request' => jsonRes,
			'response' => resJSON,
			'responseCode' => res.getStatusCode()
		});

		Map<String,Object> response = new Map<String,Object>();
		try {
			response = (Map<String,Object>)JSON.deserializeUntyped(resJSON);
		} 
		catch(Exception e) {
			System.debug('The following exception has occurred: ' + e.getMessage() +' on line number: '+e.getLineNumber());
			response = new Map<String,Object> {
				'Status' => 'Error',
				'Error' => e.getMessage()
			};
		}
		return response;
	}

	private static String getHttpRequest (Map<String, Object> generalData) {
		String url = String.valueOf(generalData.get('url'));
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod('GET');
		req.setHeader('Content-Type', 'application/json');
		
		HttpResponse res = h.send(req);
		String resJSON = res.getBody();
		Map<String,Object> response = new Map<String,Object>();
		System.debug(resJSON);

		if (generalData.get('method') != 'Document Fetch') {
			insert createLog(new Map<String,Object> {
				'method' => generalData.get('method'),
				'request' => url,
				'response' => resJSON,
				'responseCode' => res.getStatusCode()
			});
		}
		
		try {
			response = (Map<String,Object>)JSON.deserializeUntyped(resJSON);
		} 
		catch(Exception e) {
			System.debug('The following exception has occurred: ' + e.getMessage() +' on line number: '+e.getLineNumber());
			response = new Map<String,Object> {
				'Status' => 'Error',
				'Error' => e.getMessage()
			};
		}
		return JSON.serialize(response.get('result'));
	}

	private static String getOriginUrl() {
		String prefix = URL.getSalesforceBaseURL().toExternalForm().replace('https://', '').split('\\.')[0];
	 	prefix = prefix.removeEnd('--c');
		return 'https://' + prefix.toLowerCase() + '.lightning.force.com';
	}

	private static Doc_Hub_Log__c createLog (Map<String,Object> logs) {
		return new Doc_Hub_Log__c (
			Date__c = Date.today(),
			Method__c = String.valueOf(logs.get('method')),
			Request__c = String.valueOf(logs.get('request')),
			Response__c = String.valueOf(logs.get('response')),
			Response_Code__c = String.valueOf(logs.get('responseCode'))
		);
	}
 
}