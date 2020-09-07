global class PostInstallClass implements InstallHandler {
	global void onInstall(InstallContext context) {
		OrgSignatureKey__c orgSignatureKey = OrgSignatureKey__c.getOrgDefaults();
		if (orgSignatureKey == null) {
			Map<String,Object> res = DocHubRegisterController.registerOrg();
		}
	}
}