@isTest
public class DocHubConfigControllerTest {
	@isTest static void getRegisterStatusTest() {
		System.assertEquals(false, DocHubConfigController.getRegisterStatus());

		OrgSignatureKey__c  orgSignatureKey = new OrgSignatureKey__c(key__c = 'test');
		insert orgSignatureKey;

		System.assertEquals(true, DocHubConfigController.getRegisterStatus());
	}    

	@isTest static void registerOrgTest(){
		
		DocHubMockForConfigController mock = new DocHubMockForConfigController();
		Test.setMock(HTTPCalloutMock.class, mock);
		
		Test.startTest(); 
			Map<String, Object> resMap = DocHubConfigController.registerOrg();
			System.assertEquals('Success', resMap.get('status'));
			System.assertEquals('734ca0d0-e3e5-4b80-b666-6f9ca3b5e7b0', resMap.get('result'));

			List<OrgSignatureKey__c> orgSig = [SELECT key__c FROM OrgSignatureKey__c];
			System.assertEquals('734ca0d0-e3e5-4b80-b666-6f9ca3b5e7b0', orgSig[0].key__c);
		Test.stopTest();

	}
}