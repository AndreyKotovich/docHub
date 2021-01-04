public class DocHubConnectionController {
	
	public static final String CREATED_BY =  UserInfo.getName();
	public static final String GOOGLE_DRIVE_AUTH = DocHubHelper.PROXY_TENANT + '/auth/google/authorize';
	public static final String CONNECTION_URL = DocHubHelper.API_URL + DocHubHelper.PROXY_TENANT + '/api/connection/' + DocHubHelper.ORGANIZATION_ID;
	public static final String DOCUMENT_URL = DocHubHelper.API_URL + DocHubHelper.PROXY_TENANT + '/api/document/' + DocHubHelper.ORGANIZATION_ID;

	@AuraEnabled
	public static Map<String, Object> createGoogleDriveAuthURL(Map<String, Object> generalData) {
		generalData.put('orgId', DocHubHelper.ORGANIZATION_ID);
		generalData.put('createdBy', CREATED_BY);
		generalData.put('origin', 'Salesforce');

		String state = EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(generalData)));
		List<NamedCredential> urlNameCred = [
			SELECT DeveloperName, Endpoint 
			FROM NamedCredential 
			WHERE DeveloperName = 'DocHubUrl'
		];
		
		if (urlNameCred.size() == 0) {
			return new Map<String, Object>{
				'status' => 'Error',
				'error' => 'Not found Named Credential: DocHubUrl'
			};
		}
		return new Map<String, Object>{
			'status' => 'Success',
			'url' => urlNameCred[0].Endpoint + GOOGLE_DRIVE_AUTH + '?state=' + state
		};
	}
	
	@AuraEnabled
	public static Map<String, Object> createConnection(Map<String, Object> generalData) {
		return postHttpRequest(new Map<String, Object> {
			'url' => CONNECTION_URL + '/create',
			'generalData' => generalData,
			'method' => 'connectioncreate'
		});
	}
	
	@AuraEnabled
	public static Map<String, Object> unlinkDocument(String Id, String reason) {
		
		try {
			update new Doc_Hub_Link__c(Id = Id, Status__c = 'Unlinked', Reason__c = reason);
		} catch (Exception e) {
			return new Map<String, Object> {
				'status' => 'Error',
				'message' => e.getMessage()
			};
		}
		return new Map<String, Object> {
			'status' => 'Success',
			'message' => 'Record updated'
		};
	}

	@AuraEnabled
	public static Map<String, Object> linkDocument(Map<String, Object> generalData) {
		String connectionId = String.valueOf(generalData.get('connectionId'));
		String documentId  = String.valueOf(generalData.get('documentId')); 
		String id = String.valueOf(generalData.get('id'));
		String folder = String.valueOf(generalData.get('folder'));
		String connectionEmail = String.valueOf(generalData.get('connectionEmail'));
		String origin = String.valueOf(generalData.get('origin'));
		
		Map<String, Object> resDocumentLink = postHttpRequest(new Map<String, Object> {
			'url' => DOCUMENT_URL + '/' + connectionId + '/link/' + documentId,
			'method' => 'documentlink'
		});

		if (resDocumentLink.get('status') == 'Success') {
			
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
				Document_Name__c = nameDoc,
				Folder__c = folder,
				Origin__c = origin,
				Linked_By__c = connectionEmail,
				Reason__c = ''
			);

			if (!String.isBlank(id)) {
				docHub.id = id;
			}
			
			Database.upsert( new List<Doc_Hub_Link__c> { docHub } , false);
			((Map<String, Object>)resDocumentLink.get('result')).put('sfid', docHub.id);
		}

		return resDocumentLink;
	}

	@AuraEnabled
	public static Map<String, Object> publishDocument(String recordId) {
		if (!String.isBlank(recordId)) {
			List<Doc_Hub_Link__c> dhls = [
				SELECT 
					Id, Connection_Id__c, Origin_Id__c, Status__c 
				FROM Doc_Hub_Link__c 
				WHERE Id = :recordId
			];

			if (dhls.size() == 0 || dhls[0].Status__c != 'Linked'){
				String errorMsg = dhls.size() == 0 ? 'Record is not found' : 'Record is not linked';
				return new Map<String, Object> {
					'status' => 'error',
					'message' => errorMsg,
					'error' => new Map<String, Object> { 'message' => errorMsg } 
				};
			}

			Map<String, Object> resDocumentLink = postHttpRequest(new Map<String, Object> {
				'url' => DOCUMENT_URL + '/' + String.valueOf(dhls[0].Connection_Id__c) + '/publish/' + dhls[0].Origin_Id__c,
				'method' => 'documentpublish'
			});

			if (resDocumentLink.get('status') == 'Success') {
			
				String publishedDate = String.valueOf(((Map<String, Object>)resDocumentLink.get('result')).get('publishedDate'));
				Doc_Hub_Link__c docHub = new Doc_Hub_Link__c(
					Id = dhls[0].Id,
					Published_Date__c = Datetime.valueOf(publishedDate.replace('T',' '))
				);
				Database.update(new List<Doc_Hub_Link__c> { docHub } , false);
				
				((Map<String, Object>)resDocumentLink.get('result')).put('sfid', docHub.id);
			} 
			return resDocumentLink;
		}
		return new Map<String, Object> {
			'status' => 'error',
			'message' => 'Record id is not found',
			'error' => new Map<String, Object> { 'message' => 'Record id is not found' } 
		};
	}
	
	@AuraEnabled
	public static String getConnectionList() {
		return JSON.serialize(getHttpRequest( new Map<String,Object> {
			'url' => CONNECTION_URL  + '/list',
			'method' => 'connectionlist'
		}));	
	}

	@AuraEnabled
	public static String getConnectionIdInfo(String connectionId) {
		return JSON.serialize(getHttpRequest( new Map<String,Object> {
			'url' => CONNECTION_URL + '/get/' + connectionId,
			'method' => 'connectionget'
		}));
	}

	@AuraEnabled
	public static String getDocumentInfo(String connectionId, String documentId) {
		return JSON.serialize(getHttpRequest( new Map<String,Object> {
			'url' => DOCUMENT_URL + '/' + connectionId + '/get/' + documentId,
			'method' => 'documentget'
		}));
	}
	
	public static Map<String, Object> DocumentFetch(Map<String, Object> generalData) {
		String connectionId = String.valueOf(generalData.get('connectionId'));
		String documentId  = String.valueOf(generalData.get('documentId')); 
		Boolean autoPublish = Boolean.valueOf(generalData.get('autoPublish'));
		String state = EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(
			new Map<String, Object>{ 'createdBy' => CREATED_BY, 'autoPublish' => autoPublish }
		)));

		return getHttpRequest( new Map<String,Object> {
			'url' => DOCUMENT_URL + '/' + connectionId + '/fetch/' + documentId + '?state=' + state,
			'method' => 'documentfetch'
		});
	}

	@AuraEnabled
	public static Map<String, Object> getConnectionDocumentList(Map<String, Object> generalData) {
		String connectionId = String.valueOf(generalData.get('connectionId'));
		String searchKey = generalData.containsKey('searchKey') ? String.valueOf(generalData.get('searchKey')) : '';
		String pageToken = generalData.containsKey('pageToken') ? String.valueOf(generalData.get('pageToken')) : '';
		String folder = generalData.containsKey('folder') ? String.valueOf(generalData.get('folder')) : null;
		
		Map<String, Object> stateMap = new Map<String, Object>{ 
			'searchKey' => searchKey, 
			'pageToken' => pageToken, 
			'pageSize' => 20 
		};

		if (!String.isBlank(folder)) { stateMap.put('folder', folder); }

		String state = EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(stateMap)));
		
		Map<String, Object> resGetMap = getHttpRequest( new Map<String,Object> {
			'url' => DOCUMENT_URL + '/' + connectionId + '/list?state=' + state,
			'method' => 'documentlist'
		});
		
		if (resGetMap.get('status') == 'Error') {
			return new Map<String,Object> {
				'status' => resGetMap.get('status') ,
				'error' => resGetMap.get('error')
			};
		}
		
		Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(resGetMap.get('result')));
		
		List<Object> docList = (List<Object>)JSON.deserializeUntyped(JSON.serialize(resMap.get('files')));

		Set<String> docIds = new Set<String>();                                           
		for(Object doc : docList) {
			if (!String.isBlank(String.valueOf(((Map<String,Object>)doc).get('id')))) {
		 		docIds.add(String.valueOf(((Map<String,Object>)doc).get('id')));
			}
		}

		Map<String, String> docHubStatusMap = new Map<String, String>();
		Map<String, String> docHubIdMap = new Map<String, String>();
		List<Doc_Hub_Link__c> docHubList = [
			SELECT Id, Origin_Id__c, Status__c 
			FROM Doc_Hub_Link__c 
			WHERE Connection_Id__c =:connectionId AND Origin_Id__c IN :docIds
		];
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
 		
		return new Map<String, Object> {
			'files' => JSON.serialize(docList),
			'nextPageToken' => resMap.containsKey('nextPageToken') ? 
				EncodingUtil.Base64Encode(Blob.valueOf((String)resMap.get('nextPageToken'))) : ''
		};
	}

	@AuraEnabled
	public static String readJsonFileForGoogleServiceAccount(Id idContentDocument) {
		List<ContentVersion> objVersion = [SELECT Id, VersionData 
										   FROM ContentVersion 
										   WHERE ContentDocumentId =:idContentDocument 
										   AND FileType = 'JSON'
										   LIMIT 1];
		Map<String, Object> convertJsonToMap = new Map <string, object>();
		if (objVersion.size() == 0) { return null; }
		try {
			convertJsonToMap = (Map<String,Object>)JSON.deserializeUntyped(objVersion[0].VersionData.toString());
		}
		catch(Exception e) {
			System.debug('The following exception has occurred: ' + e.getMessage() +' on line number: '+e.getLineNumber());
		}
		
		return EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(convertJsonToMap)));
	}

	private static Map<String, Object> postHttpRequest(Map<String, Object> generalData) {
		String url = String.valueOf(generalData.get('url'));
		Map<String, Object> requestMap = generalData.containsKey('generalData') ? (Map<String,Object>) generalData.get('generalData') : new Map<String, Object>();
		requestMap.put('createdBy', CREATED_BY);
		requestMap.put('origin', 'Salesforce');
		String jsonRes = JSON.serialize(requestMap);
		String timestamp = String.valueOf(Datetime.newInstance(Datetime.now().dateGMT(),Datetime.now().timeGmt()).getTime());
		String signature = DocHubHelper.createSignature(new List<String>{DocHubHelper.ORGANIZATION_ID, String.valueOf(generalData.get('method')), timestamp}, null);
		
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('timestamp', timestamp);
		req.setHeader('auth-signature', signature);
		req.setTimeout(120000);
		req.setBody(jsonRes);
		HttpResponse res = h.send(req);
		String resJSON = res.getBody();
		if (res.getStatusCode() == 400) { resJSON = 'Sorry, something went wrong'; }
		DocHubHelper.createLog(new Map<String,String> {
			'method' => String.valueOf(generalData.get('method')),
			'request' => String.valueOf(req),
			'response' => resJSON,
			'responseCode' => String.valueOf(res.getStatusCode())
		});
		
		if (res.getStatusCode() == 400) {
			return new Map<String,Object> {
				'status' => 'Error',
				'message' => resJSON,
				'error' => new Map<String,Object> { 'message' => resJSON }
			};
		}

		Map<String,Object> resMap = new Map<String,Object>();
		try {
			resMap = (Map<String,Object>)JSON.deserializeUntyped(resJSON);
		} 
		catch(Exception e) {
			System.debug('The following exception has occurred: ' + e.getMessage() +' on line number: ' + e.getLineNumber());
			resMap = new Map<String,Object> {
				'status' => 'Error',
				'message' => e.getMessage(),
				'error' => new Map<String,Object> { 'message' => e.getMessage() }
			};
		}
		return resMap;
	}
	
	private static Map<String, Object> getHttpRequest(Map<String, Object> generalData) {
		String url = String.valueOf(generalData.get('url'));
		DateTime dateTimeGMT = Datetime.now().dateGMT();
		String timestamp = String.valueOf(Datetime.newInstance(Datetime.now().dateGMT(),Datetime.now().timeGmt()).getTime());
		String signature = DocHubHelper.createSignature(new List<String>{DocHubHelper.ORGANIZATION_ID, String.valueOf(generalData.get('method')), timestamp}, null);
		
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod('GET');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('timestamp', timestamp);
		req.setHeader('auth-signature', signature);
		
		HttpResponse res = h.send(req);
		String resJSON = res.getBody();
		
		DocHubHelper.createLog(new Map<String,String> {
			'method' => String.valueOf(generalData.get('method')),
			'request' => String.valueOf(req),
			'response' => resJSON,
			'responseCode' => String.valueOf(res.getStatusCode())
		});
		
		Map<String,Object> resMap = new Map<String,Object>();
		
		try {
			resMap = (Map<String,Object>)JSON.deserializeUntyped(resJSON);
		} 
		catch(Exception e) {
			resMap = new Map<String,Object> {
				'status' => 'Error',
				'message' => e.getMessage(),
				'error' => new Map<String,Object> { 'message' => e.getMessage() }
			};
		}
		return resMap;
	}

}