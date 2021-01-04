global class PostInstallClass implements InstallHandler {
	global void onInstall(InstallContext context) {
		NamespaceSetting__c setting = NamespaceSetting__c.getOrgDefaults();
		if (String.isBlank(setting.Prefix__c)) { 
			setting.Prefix__c = PostInstallClass.class.getName().substringBefore('PostInstallClass').substringBefore('.');
			setting.Prefix__c += !String.isBlank(setting.Prefix__c) ? '__' : '';
			upsert setting;
		}
		
		OrgSignatureKey__c orgSignatureKey = OrgSignatureKey__c.getOrgDefaults();
		if (String.isBlank(orgSignatureKey.key__c)) { registerOrg(); }
	}

	@future(callout=true)
	public static void registerOrg(){
		Map<String,Object> res = DocHubRegisterController.registerOrg();
	}
}