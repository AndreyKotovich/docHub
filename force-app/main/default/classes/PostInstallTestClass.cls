@isTest
public with sharing class PostInstallTestClass {
	
	@isTest static void testInstallScript() {
		PostInstallClass postinstall = new PostInstallClass();
		Test.testInstall(postinstall, null);

		DocHubMockForConfigController mock = new DocHubMockForConfigController();
		Test.setMock(HTTPCalloutMock.class, mock);

		Test.startTest();
		Test.stopTest();

		NamespaceSetting__c settings = [SELECT Prefix__c FROM NamespaceSetting__c];
		System.assertNotEquals(NULL, settings);

		OrgSignatureKey__c orgSignatureKey = OrgSignatureKey__c.getOrgDefaults();
		System.assertEquals('734ca0d0-e3e5-4b80-b666-6f9ca3b5e7b0', orgSignatureKey.key__c);
	}

}