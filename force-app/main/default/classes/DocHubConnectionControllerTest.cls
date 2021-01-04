@isTest
public class DocHubConnectionControllerTest {
	public static final String DOCUMENT_URL = DocHubHelper.API_URL + DocHubHelper.PROXY_TENANT + '/api/document/' + DocHubHelper.ORGANIZATION_ID;
	public static final String CONNECTION_URL = DocHubHelper.API_URL + DocHubHelper.PROXY_TENANT + '/api/connection/' + DocHubHelper.ORGANIZATION_ID;
	public static final String CREATED_BY =  UserInfo.getName();


	@testSetup static void setup() {
	   insert new OrgSignatureKey__c(key__c = '345678');
	}
	
	public static Doc_Hub_Log__c getLog() {
		List<Doc_Hub_Log__c> logs = [SELECT id, Method__c, Date__c, Response__c, Response_Code__c FROM Doc_Hub_Log__c];
		if (logs.size() > 0 ) { return logs[0]; }
		return new Doc_Hub_Log__c();
	}
	
	@isTest static void createGoogleDriveAuthURLTest() {

		Map<String, Object> genData = DocHubConnectionController.createGoogleDriveAuthURL( new Map<String, Object> {
			'connectionName' => 'testConnection',
			'connectionOrigin' => 'GoogleDrive'
		});
		System.assertEquals(true, String.valueOf(genData.get('url')).containsIgnoreCase('https://api-dochub.succraft.com' + DocHubConnectionController.GOOGLE_DRIVE_AUTH + '?state='));
		System.assertEquals('Success', genData.get('status'));
	}

	@isTest static void createConnectionTest() {
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);
		Test.startTest();
		Map<String, Object> resMap = DocHubConnectionController.createConnection(new Map<String, Object> {
			'connectionName' => 11,
			'connectionOrigin' => 'GoogleDrive',
			'state' => 'eyJjbGllbnRfeDUwOV9jZXJ0X3VybCI6Imh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL3JvYm90L3YxL21ldGFkYXRhL3g1MDkvdGVzdC0xNSU0MHNhZ2Utc2VudHJ5LTI4NDIxMC5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIsImF1dGhfcHJvdmlkZXJfeDUwOV9jZXJ0X3VybCI6Imh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL29hdXRoMi92MS9jZXJ0cyIsInRva2VuX3VyaSI6Imh0dHBzOi8vb2F1dGgyLmdvb2dsZWFwaXMuY29tL3Rva2VuIiwiYXV0aF91cmkiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20vby9vYXV0aDIvYXV0aCIsImNsaWVudF9pZCI6IjExODE2NjIyOTY2NDIxNzUyNTI0NSIsImNsaWVudF9lbWFpbCI6InRlc3QtMTVAc2FnZS1zZW50cnktMjg0MjEwLmlhbS5nc2VydmljZWFjY291bnQuY29tIiwicHJpdmF0ZV9rZXkiOiItLS0tLUJFR0lOIFBSSVZBVEUgS0VZLS0tLS1cbk1JSUV2QUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktZd2dnU2lBZ0VBQW9JQkFRQzQrZGh1cEFtYzE0K1dcblYwelRKZktxOHp6WEFTV1hQMHBWTFM0c3VOdktpV2JqbXZtaFNOUzJsVldqTnViWWJuOTl5cUdURXBoS0xkZkFcbjJDTWY1RUhNWGw4YzZOU1dIL1diRlExdHhJNW82VG5VYUVpOUJjeUVuS3FlUG13QTRoOFlrUjl0bG1wZ3dVT3ZcblF3ampKYmc2VmpWSzhjUTlkRXg1dEE5eityTnZmdDlNQW82MTdSN0xLRmhZU3g4cFhEeCszTUFCdWlHYmJUQVZcbkpOWHo1ZXhKV2hqOStpTzR4VnZCNUY4WGY0TmUwbWU5QlFtWEJJYlZQaE5jeklmV0RqM1VBdHRjcExhYXNxOWRcblpna3kvU0dtcXNoS0I5MnI5TXB4UURQd2tNTHRxV2hXQUQ2Um14WVdPMDcyekF1cllTYTZUVHJrckdzNlVjcGlcbmpiS2ZxWXJoQWdNQkFBRUNnZ0VBV0tFeDhGVjkyNTQzaVFBY2FlRjVaQ3EyNElnR3BIRXBZeVdLUmRodlM1ekpcblpVNG94UHc2RzUvekVBaXExRklobVRyQmIxQk9FdURqUzEza2VvL3FiUXRjeEdQVkZIZU12WGw1WFRwOFI4MVVcbkxhK29CcFhrT0RnKzBpS3pxanF1VHAyZWN1cEszMEJLOTR1Rmt4ek1LSHVNL25OWUpWLzNrcXJSYXE5WlVaYWxcblI1VURnOGlUb2MrOWhVYjVQelpZTTB4VXdkMEgzVjl6bW9FaWVGWjhQdFRlZUZpRXpUQUpXRG13OTk1WUFZdnpcbmNuekl5MldvZXFxaldKSmhaM0lBUTdMdzgvUU1wcEJkUEMyU014Slp4cC9GN1I4bWxxZm02SFZLOU10VVQ0eTdcbmNzQnd5dEdyTWg5akN1RTVhN2ZxakYzTkI4UzRyOEdscDIzbjl4Y1ZSd0tCZ1FEMWVXME0ycFQ3bWZZZ1ZyRGdcblpGMDVvTDl6dlFjd3p2V3hkNXRFRlU1OWRYQ0pkbFoyMkJsQmtPS2VOK1FXRWI2MmZVL01rNFZ4WTgvSk1UTGFcblluRCtxSVR2bmhKWmR6N0F2UHFxeWY3OFV2MjRDV20xa0ZhYzNNVHpBMVdNVk9QcUgvTHEvdzBiNVFkcEFlODlcbkt4cWNsUGlSeWNmNlB2TG9DK2xqSWdtdFh3S0JnUURBNkZRTzhmcVl2VlNEZHljemliZis1VzVZWnRmaHQ2ZXVcbkZGZHJpRjhOeFJ4UHV4c2xBc2FBKzk5dkdYeTN0Sjh6b2NXd0QxZWtvV3RlL0dkZFh3clFlRWhQRjJPTkxBVmZcbnU5ZURMQ3pFV1dvN3I0TGdkQWtnTS9OT3hOVmRENmFJdEJreEtLUmJFZDBxc3poK3Z2RGQvZUxjYVg4Wko4eUdcbkFMd1FTTnR2dndLQmdGUUlQRmVSSUQwOVNHOXJuZU5ER0ZMWS81RThYWkRNMkhqbkxBVFRrbW9LWVByOXdyMnVcblhuNytmVVdTZG9kRGpkams3d05tWU9FZlBRdHZ4eXZSVlVNb0oxSHI5L1llaHlIdHo1WFZ6bTlNYmNTcG5FRm1cblp2QU45M0lGYXl5K0JzT29LajFlRUh2REhKVks3ejR1V2s3T0JJWEw0S1IvRmlKdnFYYWhPVlRiQW9HQUNSQWhcbk90NkZmbjJPcGVxSUxmU3ZiMHRLSnQ4V0QyVzRmQVk2b1RPeis0cWlMT0RHZ3JPaHJkZW5oS20yNFU2Y0dDbm1cbmhzSUJ4UnRNVnhjV3FCMVovYmRZOWxaTCtBcjBhYTRDandnWlJsUkpHR3JEaEZZUFE3TU5JRXRCRnZFd1NzWGpcblZScnF0ZGllQW02UEhlMU1sYkZpNGlZV3NaRGNIQU9XMGxFSjlqTUNnWUF0SmdTSzJscEJHWHJxSmdpUkxYem1cbjdtbUZhZlJjUitKa1NER0lJbzJHNmd5akVUNVhQZzJLYldwQWc4cjRyQitqUnBZYnpubmlqa1V3UDNmd2gzMi9cbkxEY1hTSUVuVkxEdU5OMno3bnRrUUNhUjg3R0ZoSFV4cXhEZXRRNDBvQ2RLbUNnT25HRTRBNnduWGxDUGJiLytcbmRZcDdWc25GSFBaVUl2QmdEa1pnRHc9PVxuLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLVxuIiwicHJpdmF0ZV9rZXlfaWQiOiI5M2VhOTEwYTAxN2Q5YmU5Yjg5YWY5YWMyNWY4ZmI5NWRiNmNiN2I5IiwicHJvamVjdF9pZCI6InNhZ2Utc2VudHJ5LTI4NDIxMCIsInR5cGUiOiJzZXJ2aWNlX2FjY291bnQifQ==',
			'typeAccess' => 'ServiceAccount'
		});
		System.assertEquals('Success', resMap.get('status'));

		Map<String, Object> mapResponsLog = (Map<String, Object>) JSON.deserializeUntyped(getLog().Response__c);
		Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize((mapResponsLog.get('result'))));
		
		System.assertEquals('testEmail@gmail.com', res.get('email'));
		System.assertEquals('GoogleDrive', res.get('origin'));
		System.assertEquals('test', res.get('name'));

		System.assertEquals('Success', mapResponsLog.get('status'));
		System.assertEquals('connectioncreate', getLog().Method__c);
		Test.stopTest();
	}

	@isTest static void unlinkDocumentTest(){
		Doc_Hub_Link__c log = new Doc_Hub_Link__c(Status__c = 'Unlinked',
												  Reason__c = 'Test');
		insert log;
		
		Test.startTest();
			Map<String, Object> resMap = DocHubConnectionController.unlinkDocument(log.Id, 'testReason');
			System.assertEquals('Success', resMap.get('status'));
		Test.stopTest();
	}

	@isTest static void unlinkDocumentTestFail() {
		Map<String, Object> resMap = DocHubConnectionController.unlinkDocument(null, 'testReason');
		System.assertEquals('Error', resMap.get('status'));
	}

	@isTest static void linkDocumentTest(){
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);

		Test.startTest();
			Map<String, Object> resMap = DocHubConnectionController.linkDocument(new Map<String, Object> {
				'connectionId' => 9,
				'documentId' => '1PMu-WYBf0Aexv0SQFwUrVvzUomRhH58iNINiFflX9Kw',
				'connectionEmail' => 'test@gmail.com'
			});
			
			Doc_Hub_Link__c link = [SELECT Connection_Id__c, Status__c, Linked_By__c, Document_Name__c FROM Doc_Hub_Link__c];
			System.assertEquals('9', link.Connection_Id__c);
			System.assertEquals('Linked', link.Status__c);
			System.assertEquals('test@gmail.com', link.Linked_By__c);
			System.assertEquals('test', link.Document_Name__c);

			Map<String, Object> mapResponsLog = (Map<String, Object>) JSON.deserializeUntyped(getLog().Response__c);
			System.assertEquals('Success', mapResponsLog.get('status'));
			System.assertEquals('documentlink', getLog().Method__c);

			Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize((mapResponsLog.get('result'))));
			System.assertEquals('test', res.get('name'));
			System.assertEquals(9, res.get('connectionId'));
			System.assertEquals('2849', res.get('version'));
		Test.stopTest();
	}

	@isTest static void linkDocumentTestFail() {
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);
		Test.startTest();
			Map<String, Object> resMap = DocHubConnectionController.linkDocument(new Map<String, Object> {
				'connectionId' => 9,
				'documentId' => 'idFileNotFound'
			});

			System.assertEquals('Error', resMap.get('status'));
			System.assertEquals('File not found: idFileNotFound', (((Map<String, Object>)resMap.get('error')).get('message')));
		Test.stopTest();    
	}

	@isTest static void publishDocumentTest(){
		Doc_Hub_Link__c link = new Doc_Hub_Link__c(
			Status__c = 'Linked',
			Reason__c = 'Test',
			Connection_Id__c = '9',
			Origin_Id__c = '1xRc2xVCMG72uH8EIskmftTNHlvb5ck4JI77CYFMwHhE'
		);
		insert link;

		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);
		Test.startTest();
			Map<String, Object> resMap = DocHubConnectionController.publishDocument(link.Id);
			System.assertEquals('Success', resMap.get('status'));

			Map<String, Object> mapResponsLog = (Map<String, Object>) JSON.deserializeUntyped(getLog().Response__c);
			System.assertEquals('Success', mapResponsLog.get('status'));
			System.assertEquals('documentpublish', getLog().Method__c);

			Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize((mapResponsLog.get('result'))));
			System.assertEquals('test', res.get('name'));
			System.assertEquals(9, res.get('connectionId'));
			System.assertEquals('6', res.get('version'));
		Test.stopTest();
	}

	@isTest static void publishDocumentTestFail(){
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);

		Map<String, Object> resMap = DocHubConnectionController.publishDocument('');
		System.assertEquals('error', resMap.get('status'));
		
		Doc_Hub_Link__c log = new Doc_Hub_Link__c(
			Status__c = 'Unlinked',
			Reason__c = 'Test',
			Connection_Id__c = '9',
			Origin_Id__c = '1xRc2xVCMG72uH8EIskmftTNHlvb5ck4JI77CYFMwHhE'
		);
		insert log;

		Test.startTest();
			Map<String, Object> resMap2 = DocHubConnectionController.publishDocument(log.Id);
			System.assertEquals('error', resMap2.get('status'));

			Map<String, Object> resMap3 = DocHubConnectionController.publishDocument('');
			System.assertEquals('Record id is not found',resMap3.get('message'));

		Test.stopTest();
	}

	@isTest static void getConnectionListTest(){    
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);
		Test.startTest();
			String res = DocHubConnectionController.getConnectionList();
			System.assertNotEquals(NULL, res);

			Map<String, Object> mapResponsLog = (Map<String, Object>) JSON.deserializeUntyped(getLog().Response__c);
			System.assertEquals('Success', mapResponsLog.get('status'));
			System.assertEquals('connectionlist', getLog().Method__c);

			Map<String, Object> res2 = ((Map<String, Object>)((List<Object>)mapResponsLog.get('result'))[0]);
			System.assertEquals('test', res2.get('name'));
			System.assertEquals('GoogleDrive', res2.get('origin'));
			System.assertEquals('test@gmail.com', res2.get('email'));

		Test.stopTest();
	}

	@isTest static void getConnectionIdInfoTest(){
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);

		Test.startTest();
			String res = DocHubConnectionController.getConnectionIdInfo('9');
			System.assertNotEquals(NULL, res);

			Map<String, Object> mapResponsLog = (Map<String, Object>) JSON.deserializeUntyped(getLog().Response__c);
			System.assertEquals('Success', mapResponsLog.get('status'));
			System.assertEquals('connectionget', getLog().Method__c);

			Map<String, Object> resMapLog = (Map<String, Object>) mapResponsLog.get('result');
			System.assertEquals('test', resMapLog.get('name'));
			System.assertEquals('GoogleDrive', resMapLog.get('origin'));
			System.assertEquals('test@gmail.com', resMapLog.get('email'));
		Test.stopTest();    
	}

	@isTest static void getConnectionIdInfoTestFail() {
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);
		Date dat = Date.toDay();
		Test.startTest();
			String res = DocHubConnectionController.getConnectionIdInfo('idFail');
			Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res);
			System.assertEquals('Error', resMap.get('status'));
			System.assertEquals('invalid input syntax for integer: idFail', (((Map<String, Object>)resMap.get('error')).get('message')));

			Map<String, Object> mapResponsLog = (Map<String, Object>) JSON.deserializeUntyped(getLog().Response__c);
			System.assertEquals('Error', mapResponsLog.get('status'));

			System.assertEquals(dat,getLog().Date__c);
			System.assertEquals('connectionget', getLog().Method__c);
		Test.stopTest();
	}

	@isTest static void getDocumentInfoTest(){
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);
		Date dat = Date.toDay();
		Test.startTest();
			String res = DocHubConnectionController.getDocumentInfo('9', '1xRc2xVCMG72uH8EIskmftTNHlvb5ck4JI77CYFMwHhE');
			System.assertNotEquals(NULL, res);
			System.assertEquals(dat,getLog().Date__c);

			Map<String, Object> mapResponsLog = (Map<String, Object>) JSON.deserializeUntyped(getLog().Response__c);
			System.assertEquals('Success', mapResponsLog.get('status'));
			System.assertEquals('documentget', getLog().Method__c);
			
			Map<String, Object> res2 =((Map<String, Object>)((List<Object>)(((Map<String, Object>)mapResponsLog.get('result')).get('files')))[0]);
			System.assertEquals('test', res2.get('name'));
			System.assertEquals('2019-11-03T17:14:04.872Z', res2.get('createdTime'));
		Test.stopTest();
	}

	@isTest static void getDocumentInfoFail(){
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);
		Date dat = Date.toDay();
		Test.startTest();
			String res = DocHubConnectionController.getDocumentInfo('idFail', 'idFail');
			System.assertEquals(dat,getLog().Date__c);

			
			Map<String, Object> mapResponsLog = (Map<String, Object>) JSON.deserializeUntyped(getLog().Response__c);
			System.assertEquals('Error', mapResponsLog.get('status'));
			System.assertEquals('invalid input syntax for integer: idFail', (((Map<String, Object>)mapResponsLog.get('error')).get('message')));
			System.assertEquals('documentget', getLog().Method__c);
		Test.stopTest();    
	}

	@isTest static void DocumentFetchTest(){
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);
		Test.startTest();
			Map<String, Object> res = DocHubConnectionController.DocumentFetch(new Map<String, Object>{
				'autoPublish' => 'true',
				'connectionId' => 9,
				'documentId' => '1xRc2xVCMG72uH8EIskmftTNHlvb5ck4JI77CYFMwHhE'
			});
			System.assertEquals('Success', res.get('status'));

			Map<String, Object> mapResponsLog = (Map<String, Object>) JSON.deserializeUntyped(getLog().Response__c);
			System.assertEquals('Success', mapResponsLog.get('status'));
			System.assertEquals('d9cc6b5a-9b04-4981-aa11-e9fecee56afb', mapResponsLog.get('result'));
			System.assertEquals('documentfetch', getLog().Method__c);
		Test.stopTest();    
	}

	@isTest static void getConnectionDocumentListTest(){
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);
		Date dat = Date.toDay();
		Test.startTest();
			Map<String, Object> res = DocHubConnectionController.getConnectionDocumentList(new Map<String, Object>{
				'connectionId' => '9'
			});
			System.assertNotEquals(NULL, res);
			System.assertEquals(dat,getLog().Date__c);

			Map<String, Object> mapResponsLog = (Map<String, Object>) JSON.deserializeUntyped(getLog().Response__c);
			System.assertEquals('Success', mapResponsLog.get('status'));
			System.assertEquals('documentlist', getLog().Method__c);

			Map<String, Object> res2 =((Map<String, Object>)((List<Object>)(((Map<String, Object>)mapResponsLog.get('result')).get('files')))[0]);
			System.assertEquals('test', res2.get('name'));
			System.assertEquals('2019-11-03T17:14:04.872Z', res2.get('createdTime'));
		Test.stopTest();
	}

	@isTest static void getConnectionDocumentListFailTest() {
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);
		
		Date dat = Date.toDay();
		Test.startTest();
		Map<String, Object> resMap = DocHubConnectionController.getConnectionDocumentList(new Map<String, Object>{
			'connectionId' => 'idFail'
		});
		System.assertEquals(dat,getLog().Date__c);

		Map<String, Object> mapResponsLog = (Map<String, Object>) JSON.deserializeUntyped(getLog().Response__c);
		System.assertEquals('Error', mapResponsLog.get('status'));
		System.assertEquals('invalid input syntax for integer: idFail', (((Map<String, Object>)resMap.get('error')).get('message')));
		System.assertEquals('documentlist', getLog().Method__c);
		Test.stopTest();
	}

	// @isTest static void readJsonFileForGoogleServiceAccountTest() {
	//     insert new ContentVersion(
	//         VersionData = EncodingUtil.base64Decode('Test'),
	//         Title = 'Test',
	//         PathOnClient = 'Test',
	//         ContentDocumentId = '0692w000003vyCOAAY'
	//     );
	//     Test.startTest();
	//         String res = DocHubConnectionController.readJsonFileForGoogleServiceAccount('0692w000003vyCOAAY');
	//         System.assertNotEquals(NULL, res);
	//         System.assertEquals('eyJjbGllbnRfeDUwOV9jZXJ0X3VybCI6Imh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL3JvYm90L3YxL21ldGFkYXRhL3g1MDkvdGVzdC0xNSU0MHNhZ2Utc2VudHJ5LTI4NDIxMC5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIsImF1dGhfcHJvdmlkZXJfeDUwOV9jZXJ0X3VybCI6Imh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL29hdXRoMi92MS9jZXJ0cyIsInRva2VuX3VyaSI6Imh0dHBzOi8vb2F1dGgyLmdvb2dsZWFwaXMuY29tL3Rva2VuIiwiYXV0aF91cmkiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20vby9vYXV0aDIvYXV0aCIsImNsaWVudF9pZCI6IjExODE2NjIyOTY2NDIxNzUyNTI0NSIsImNsaWVudF9lbWFpbCI6InRlc3QtMTVAc2FnZS1zZW50cnktMjg0MjEwLmlhbS5nc2VydmljZWFjY291bnQuY29tIiwicHJpdmF0ZV9rZXkiOiItLS0tLUJFR0lOIFBSSVZBVEUgS0VZLS0tLS1cbk1JSUV2QUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktZd2dnU2lBZ0VBQW9JQkFRQzQrZGh1cEFtYzE0K1dcblYwelRKZktxOHp6WEFTV1hQMHBWTFM0c3VOdktpV2JqbXZtaFNOUzJsVldqTnViWWJuOTl5cUdURXBoS0xkZkFcbjJDTWY1RUhNWGw4YzZOU1dIL1diRlExdHhJNW82VG5VYUVpOUJjeUVuS3FlUG13QTRoOFlrUjl0bG1wZ3dVT3ZcblF3ampKYmc2VmpWSzhjUTlkRXg1dEE5eityTnZmdDlNQW82MTdSN0xLRmhZU3g4cFhEeCszTUFCdWlHYmJUQVZcbkpOWHo1ZXhKV2hqOStpTzR4VnZCNUY4WGY0TmUwbWU5QlFtWEJJYlZQaE5jeklmV0RqM1VBdHRjcExhYXNxOWRcblpna3kvU0dtcXNoS0I5MnI5TXB4UURQd2tNTHRxV2hXQUQ2Um14WVdPMDcyekF1cllTYTZUVHJrckdzNlVjcGlcbmpiS2ZxWXJoQWdNQkFBRUNnZ0VBV0tFeDhGVjkyNTQzaVFBY2FlRjVaQ3EyNElnR3BIRXBZeVdLUmRodlM1ekpcblpVNG94UHc2RzUvekVBaXExRklobVRyQmIxQk9FdURqUzEza2VvL3FiUXRjeEdQVkZIZU12WGw1WFRwOFI4MVVcbkxhK29CcFhrT0RnKzBpS3pxanF1VHAyZWN1cEszMEJLOTR1Rmt4ek1LSHVNL25OWUpWLzNrcXJSYXE5WlVaYWxcblI1VURnOGlUb2MrOWhVYjVQelpZTTB4VXdkMEgzVjl6bW9FaWVGWjhQdFRlZUZpRXpUQUpXRG13OTk1WUFZdnpcbmNuekl5MldvZXFxaldKSmhaM0lBUTdMdzgvUU1wcEJkUEMyU014Slp4cC9GN1I4bWxxZm02SFZLOU10VVQ0eTdcbmNzQnd5dEdyTWg5akN1RTVhN2ZxakYzTkI4UzRyOEdscDIzbjl4Y1ZSd0tCZ1FEMWVXME0ycFQ3bWZZZ1ZyRGdcblpGMDVvTDl6dlFjd3p2V3hkNXRFRlU1OWRYQ0pkbFoyMkJsQmtPS2VOK1FXRWI2MmZVL01rNFZ4WTgvSk1UTGFcblluRCtxSVR2bmhKWmR6N0F2UHFxeWY3OFV2MjRDV20xa0ZhYzNNVHpBMVdNVk9QcUgvTHEvdzBiNVFkcEFlODlcbkt4cWNsUGlSeWNmNlB2TG9DK2xqSWdtdFh3S0JnUURBNkZRTzhmcVl2VlNEZHljemliZis1VzVZWnRmaHQ2ZXVcbkZGZHJpRjhOeFJ4UHV4c2xBc2FBKzk5dkdYeTN0Sjh6b2NXd0QxZWtvV3RlL0dkZFh3clFlRWhQRjJPTkxBVmZcbnU5ZURMQ3pFV1dvN3I0TGdkQWtnTS9OT3hOVmRENmFJdEJreEtLUmJFZDBxc3poK3Z2RGQvZUxjYVg4Wko4eUdcbkFMd1FTTnR2dndLQmdGUUlQRmVSSUQwOVNHOXJuZU5ER0ZMWS81RThYWkRNMkhqbkxBVFRrbW9LWVByOXdyMnVcblhuNytmVVdTZG9kRGpkams3d05tWU9FZlBRdHZ4eXZSVlVNb0oxSHI5L1llaHlIdHo1WFZ6bTlNYmNTcG5FRm1cblp2QU45M0lGYXl5K0JzT29LajFlRUh2REhKVks3ejR1V2s3T0JJWEw0S1IvRmlKdnFYYWhPVlRiQW9HQUNSQWhcbk90NkZmbjJPcGVxSUxmU3ZiMHRLSnQ4V0QyVzRmQVk2b1RPeis0cWlMT0RHZ3JPaHJkZW5oS20yNFU2Y0dDbm1cbmhzSUJ4UnRNVnhjV3FCMVovYmRZOWxaTCtBcjBhYTRDandnWlJsUkpHR3JEaEZZUFE3TU5JRXRCRnZFd1NzWGpcblZScnF0ZGllQW02UEhlMU1sYkZpNGlZV3NaRGNIQU9XMGxFSjlqTUNnWUF0SmdTSzJscEJHWHJxSmdpUkxYem1cbjdtbUZhZlJjUitKa1NER0lJbzJHNmd5akVUNVhQZzJLYldwQWc4cjRyQitqUnBZYnpubmlqa1V3UDNmd2gzMi9cbkxEY1hTSUVuVkxEdU5OMno3bnRrUUNhUjg3R0ZoSFV4cXhEZXRRNDBvQ2RLbUNnT25HRTRBNnduWGxDUGJiLytcbmRZcDdWc25GSFBaVUl2QmdEa1pnRHc9PVxuLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLVxuIiwicHJpdmF0ZV9rZXlfaWQiOiI5M2VhOTEwYTAxN2Q5YmU5Yjg5YWY5YWMyNWY4ZmI5NWRiNmNiN2I5IiwicHJvamVjdF9pZCI6InNhZ2Utc2VudHJ5LTI4NDIxMCIsInR5cGUiOiJzZXJ2aWNlX2FjY291bnQifQ==', res);
	//     Test.stopTest();
	// }

}