@isTest
public class DocHubHelperTest {
	
	// @isTest static void getNamespacePrefixTest() {


	// }

	@isTest static void createLogTest(){

		DocHubHelper.createLog(new Map<String, String>{
			'method' => 'GET',
			'request' => 'TestRequest',
			'response' => 'TestResponse',
			'responseCode' => '200'
		});

		Doc_Hub_Log__c log = [SELECT Date__c, Method__c, Request__c, Response__c, Response_Code__c 
							  FROM Doc_Hub_Log__c];
		
		System.assertNotEquals(NULL, log.Date__c);
		System.assertEquals('GET', log.Method__c);
		System.assertEquals('TestRequest', log.Request__c);
		System.assertEquals('TestResponse', log.Response__c);
		System.assertEquals('200', log.Response_Code__c);

	}

	@isTest static void createSignatureTest(){
		String res = DocHubHelper.createSignature(new List<String>{
			'00D2w00000FaTZZEA3',
			'connectionlist',
			'1604443471527'
		}, 'testKey');

		System.assertEquals('HRSl1uTI9klBI5d/xolh65LKGog=', res);
	}


	@isTest static void createSignatureNotKeyTest(){
		OrgSignatureKey__c orgSignatureKey = new OrgSignatureKey__c(Key__c = '23456789');
		insert orgSignatureKey;

		Test.startTest();
		String res = DocHubHelper.createSignature(new List<String>{
			'00D2w00000FaTZZEA3',
			'documentlist',
			'1604443471527'
		}, NULL);
		System.assertEquals('+gbONw2EYjaTC+8K+MrTbQeju5U=', res);
		Test.stopTest();

	}
}