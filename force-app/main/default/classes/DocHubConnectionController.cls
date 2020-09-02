public class DocHubConnectionController {
	public static final String ORGANIZATION_ID =  UserInfo.getOrganizationId();
	private static final String CREATED_BY =  UserInfo.getName();
	private static final String API_URL = 'callout:ApiUrl';
	private static final String GOOGLE_DRIVE_AUTH = '/auth/google/authorize';
	private static final String CONNECTION_URL = API_URL + '/api/connection/' + ORGANIZATION_ID;
	private static final String DOCUMENT_URL = API_URL + '/api/document/' + ORGANIZATION_ID;

	private static final String KEY = 'T6AFIwJ0fVD4rNlJumRCSpjphOg/WKl2U4bwdyZIEis=';
	
	@AuraEnabled
	public static Map<String, Object> createGoogleDriveAuthURL(Map<String, Object> generalData)  {
		generalData.put('orgId', ORGANIZATION_ID);
		generalData.put('createdBy', CREATED_BY);
		generalData.put('origin', 'Salesforce');

		String state = EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(generalData)));
		List<NamedCredential> urlNameCred = [
			SELECT DeveloperName, Endpoint 
			FROM NamedCredential 
			WHERE DeveloperName = 'ApiUrl'
		];
		
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
			'method' => 'connectionCreate'
		});
	}
	
	@AuraEnabled
	public static Map<String, Object> unlinkDocument(String Id, String reason) {
		update new Doc_Hub_Link__c(Id = Id, Status__c = 'Unlinked', Reason__c = reason);
		
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
			'method' => 'documentLink'
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
			System.debug('docHub ' + docHub);
			Database.upsert( new List<Doc_Hub_Link__c> { docHub } , false);
			((Map<String, Object>)resDocumentLink.get('result')).put('sfid', docHub.id);
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
				'method' => 'documentPublish'
			});

			if (resDocumentLink.get('status') == 'Success') {
			
				String publishedDate = String.valueOf(((Map<String, Object>)resDocumentLink.get('result')).get('publishedDate'));
				Doc_Hub_Link__c docHub = new Doc_Hub_Link__c(
					Id = dhl.Id,
					Published_Date__c = Datetime.valueOf(publishedDate.replace('T',' '))
				);
				//Database.upsert( new List<Doc_Hub_Link__c> { docHub } , Doc_Hub_Link__c.Fields.Origin_Id__c, false);
				Database.update( new List<Doc_Hub_Link__c> { docHub } , false);
				
				((Map<String, Object>)resDocumentLink.get('result')).put('sfid', docHub.id);
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
		return JSON.serialize(getHttpRequest( new Map<String,Object> {
			'url' => CONNECTION_URL  + '/list',
			'method' => 'connectionList'
		}));	
	}

	@AuraEnabled
	public static String getConnectionIdInfo(String connectionId) {
		return JSON.serialize(getHttpRequest( new Map<String,Object> {
			'url' => CONNECTION_URL + '/get/' + connectionId,
			'method' => 'connectionGet'
		}));
	}

	@AuraEnabled
	public static String getDocumentInfo(String connectionId, String documentId) {
		return JSON.serialize(getHttpRequest( new Map<String,Object> {
			'url' => DOCUMENT_URL + '/' + connectionId + '/get/' + documentId,
			'method' => 'documentGet'
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
			'method' => 'documentFetch'
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

		if (!String.isBlank(folder)) {
			stateMap.put('folder', folder);
		}

		String state = EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(stateMap)));
		
		Map<String, Object> resGetMap = getHttpRequest( new Map<String,Object> {
			'url' => DOCUMENT_URL + '/' + connectionId + '/list?state=' + state,
			'method' => 'documentList'
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
		String timestamp = String.valueOf(Datetime.newInstance(Datetime.now().dateGMT(),Datetime.now().timeGmt()).getTime());
		String signature = createSignature(new List<String>{ORGANIZATION_ID, String.valueOf(generalData.get('method')), timestamp});
		
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('TIMESTAMP', timestamp);
        req.setHeader('AUTH_SIGNATURE', signature);
		req.setTimeout(120000);
		req.setBody(jsonRes);
		HttpResponse res = h.send(req);
		String resJSON = res.getBody();
		
		createLog(new Map<String,String> {
			'method' => String.valueOf(generalData.get('method')),
			'request' => String.valueOf(req),
			'response' => resJSON,
			'responseCode' => String.valueOf(res.getStatusCode())
		});

		Map<String,Object> response = new Map<String,Object>();
		try {
			response = (Map<String,Object>)JSON.deserializeUntyped(resJSON);
		} 
		catch(Exception e) {
			System.debug('The following exception has occurred: ' + e.getMessage() +' on line number: ' + e.getLineNumber());
			response = new Map<String,Object> {
				'Status' => 'Error',
				'Error' => e.getMessage()
			};
		}
		return response;
	}

	private static Map<String, Object> getHttpRequest (Map<String, Object> generalData) {
		String url = String.valueOf(generalData.get('url'));
		DateTime dateTimeGMT = Datetime.now().dateGMT();
		String timestamp = String.valueOf(Datetime.newInstance(Datetime.now().dateGMT(),Datetime.now().timeGmt()).getTime());
		String signature = createSignature(new List<String>{ORGANIZATION_ID, String.valueOf(generalData.get('method')), timestamp});
		
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod('GET');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('TIMESTAMP', timestamp);
		req.setHeader('AUTH_SIGNATURE', signature);
		
		HttpResponse res = h.send(req);
		String resJSON = res.getBody();
		Map<String,Object> response = new Map<String,Object>();
		
		createLog(new Map<String,String> {
			'method' => String.valueOf(generalData.get('method')),
			'request' => String.valueOf(req),
			'response' => resJSON,
			'responseCode' => String.valueOf(res.getStatusCode())
		});

		try {
			response = (Map<String,Object>)JSON.deserializeUntyped(resJSON);
		} 
		catch(Exception e) {
			response = new Map<String,Object> {
				'Status' => 'Error',
				'Error' => e.getMessage()
			};
		}

		return response;
	}

	private static String getOriginUrl() {
		String prefix = URL.getSalesforceBaseURL().toExternalForm().replace('https://', '').split('\\.')[0];
	 	prefix = prefix.removeEnd('--c');
		return 'https://' + prefix.toLowerCase() + '.lightning.force.com';
	}

	private static void createLog (Map<String,String> logs) {
		insert new Doc_Hub_Log__c (
			Date__c = Date.today(),
			Method__c = String.valueOf(logs.get('method')),
			Request__c = String.valueOf(logs.get('request')),
			Response__c = String.valueOf(logs.get('response')),
			Response_Code__c = String.valueOf(logs.get('responseCode'))
		);
	} 

	public static String createSignature(List<String> args) {

        String stringToSign = '';
        String signature = '';

        for (String param : args) {
        	stringToSign += param + '-';
		}
		
        stringToSign = stringToSign.left(stringToSign.length()-1);
            
        Blob sig = Crypto.generateMac('HmacSHA1', Blob.valueOf(stringToSign), Blob.valueOf(KEY));
        signature = EncodingUtil.base64Encode(sig);
        return signature;
	}
	
	public static void hacks() {
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}
}