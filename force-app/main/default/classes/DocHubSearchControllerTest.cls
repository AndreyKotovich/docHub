@isTest
public class DocHubSearchControllerTest { 
	
	@isTest static void searchDocumentsFailTest() {
		DocHubMockForSearchController mock = new DocHubMockForSearchController();
		Test.setMock(HTTPCalloutMock.class, mock);

		OrgSignatureKey__c orgKey = new OrgSignatureKey__c(key__c = '345678');
		insert orgKey;

		Test.startTest();
		mock.temp = false;
		Map<String, Object> res = DocHubSearchController.searchDocuments('test');
		System.assertEquals('Error', res.get('status'));
		Test.stopTest();
	}

	@isTest static void searchDocumentsTest() {
		DocHubMockForSearchController mock = new DocHubMockForSearchController();
		Test.setMock(HTTPCalloutMock.class, mock);

		insert new Doc_Hub_Link__c (
			Origin_Id__c = '12345qwerty',
			Origin__c = 'GoogleDrive',
			Status__c = 'Linked',
			Document_Name__c = 'test',
			Hub_Document_Id__c = '3'
		);

		OrgSignatureKey__c orgKey = new OrgSignatureKey__c(key__c = '345678');
		insert orgKey;

		Test.startTest();
			Map<String, Object> res = DocHubSearchController.searchDocuments('testKey');
			System.assertEquals('Success', res.get('status'));
			List<DocHubSearchController.SearchResultWrapper> docList = (List<DocHubSearchController.SearchResultWrapper>)JSON.deserialize(String.valueOf(res.get('result')), List<DocHubSearchController.SearchResultWrapper>.class);

			DocHubSearchController.SearchResultWrapper wrapper = docList[0];
			System.assertEquals('12345qwerty', wrapper.documentId);
			System.assertEquals('test', wrapper.originalName);
			System.assertEquals('GoogleDrive', wrapper.origin);

		Test.stopTest();

	}   

}