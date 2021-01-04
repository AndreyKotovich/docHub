// @isTest(SeeAllData=true)
@isTest
public class DocumentViewPageControllerTest {
	@TestSetup
	static void makeData(){
		insert new OrgSignatureKey__c(key__c = '345678');
	}
	@isTest static void loadDocumentTest(){
		DocumentViewPageController doc = new DocumentViewPageController();
		
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);

		
		doc.loadDocument();
		System.assertEquals('Sorry, something went wrong', doc.errorMessage);

		Doc_Hub_Link__c dhl = new Doc_Hub_Link__c(
			Connection_Id__c = NULL,
			Origin_Id__c = '1xRc2xVCMG72uH8EIskmftTNHlvb5ck4JI77CYFMwHhE',
			Auto_Publish__c = true
		);
		insert dhl;

		ApexPages.currentPage().getParameters().put('Id', dhl.Id);
		doc.loadDocument();
		System.assertEquals('Sorry, something went wrong', doc.errorMessage);

		dhl.Connection_Id__c = '9';
		update dhl;
		Date toDay = Date.toDay();
		Test.startTest();
			doc.loadDocument();
			List<Doc_Hub_Log__c> listLog = [SELECT Date__c, Method__c, Request__c, Response__c, Response_Code__c
											FROM Doc_Hub_Log__c LIMIT 1];
			Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(listLog[0].Response__c);
			System.assertEquals('Success', resMap.get('status'));
			System.assertEquals(toDay, listLog[0].Date__c);
			System.assertEquals('documentfetch', listLog[0].Method__c);
			System.assertEquals('d9cc6b5a-9b04-4981-aa11-e9fecee56afb', resMap.get('result'));
		Test.stopTest();
	
	}

	@isTest static void loadDocumentTestFail(){
		DocumentViewPageController doc = new DocumentViewPageController();
		
		DocHubMockForConnectionController mock = new DocHubMockForConnectionController();
		Test.setMock(HTTPCalloutMock.class, mock);
		Doc_Hub_Link__c dhl = new Doc_Hub_Link__c(
			Connection_Id__c = 'testConnectionId',
			Origin_Id__c = 'testOriginIdc',
			Auto_Publish__c = true
		);
		insert dhl;
		ApexPages.currentPage().getParameters().put('Id', dhl.Id);
		
		Date toDay = Date.toDay();
		Test.startTest();
			doc.loadDocument();
			List<Doc_Hub_Log__c> log = [SELECT Date__c, Method__c, Response__c, Response_Code__c FROM Doc_Hub_Log__c];
			Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(log[0].Response__c);
			System.assertEquals(toDay, log[0].Date__c);
			System.assertEquals('Error', res.get('status'));
			System.assertEquals('{message=invalid input syntax for integer: testConnectionId}', String.valueOf(res.get('error')));
		Test.stopTest();
	}
}