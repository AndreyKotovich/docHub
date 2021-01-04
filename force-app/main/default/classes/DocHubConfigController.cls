public class DocHubConfigController {
	@AuraEnabled
	public static Boolean getRegisterStatus() {
		OrgSignatureKey__c orgSignatureKey = OrgSignatureKey__c.getOrgDefaults();
		return !String.isBlank(orgSignatureKey.key__c);
	}

	@AuraEnabled
	public static Map<String,Object> registerOrg() {
		return DocHubRegisterController.registerOrg();
	}
	
}