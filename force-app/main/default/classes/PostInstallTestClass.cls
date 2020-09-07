@isTest
public with sharing class PostInstallTestClass {
	@isTest
	static void testInstallScript() {
	PostInstallClass postinstall = new PostInstallClass();
		Test.testInstall(postinstall, null);
	}
}
