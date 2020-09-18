public class DocHubHelper {
    public static final String ORGANIZATION_ID =  UserInfo.getOrganizationId();
	public static final String PROXY_TENANT = '/proxy/tenant/' + ORGANIZATION_ID;
    public static final String API_URL = 'callout:' + getNamespacePrefix() + 'DocHubUrl';
    
    public static String getNamespacePrefix() {
		String namespacePrefix;
		String[] classNameParts = String.valueOf(DocHubConnectionController.class).split('\\.', 2);
		if(classNameParts.size() > 1) {
			Type classType = Type.forName(classNameParts[0], classNameParts[1]);
			if(classType == DocHubConnectionController.class) {
				namespacePrefix = classNameParts[0] + '__';
			} else {
				namespacePrefix = '';
			}
		} else {
			namespacePrefix = '';
		}
		System.debug('getNamespacePrefix namespacePrefix ' + namespacePrefix);
		return namespacePrefix; 
    }
    
    public static void createLog(Map<String,String> logs) {
		insert new Doc_Hub_Log__c (
			Date__c = Date.today(),
			Method__c = String.valueOf(logs.get('method')),
			Request__c = String.valueOf(logs.get('request')),
			Response__c = String.valueOf(logs.get('response')),
			Response_Code__c = String.valueOf(logs.get('responseCode'))
		);
    } 
    
    public static String createSignature(List<String> args, String key) {

		String stringToSign = '';
		String signature = '';
		String signKey = key;

		for (String param : args) {
			stringToSign += param + '-';
		}
		
		stringToSign = stringToSign.left(stringToSign.length()-1);
		
		if (String.isBlank(signKey)) {
			OrgSignatureKey__c orgSignatureKey = OrgSignatureKey__c.getOrgDefaults();
			signKey = !String.isBlank(orgSignatureKey.key__c) ? orgSignatureKey.key__c : '';
		}

		Blob sig = Crypto.generateMac('HmacSHA1', Blob.valueOf(stringToSign), Blob.valueOf(signKey));
		signature = EncodingUtil.base64Encode(sig);
		return signature;
    }
    
    // public static String getOriginUrl() {
	// 	String prefix = URL.getSalesforceBaseURL().toExternalForm().replace('https://', '').split('\\.')[0];
	//  	prefix = prefix.removeEnd('--c');
	// 	return 'https://' + prefix.toLowerCase() + '.lightning.force.com';
	// }
}
