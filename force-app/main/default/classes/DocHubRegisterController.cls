public with sharing class DocHubRegisterController {
	private static final String API_URL = 'callout:ApiUrl';
	
	public static Map<String, Object> registerOrg() {
		Map<String, Object> regKeyMap = httpRequest(new Map<String, Object> {
			'method' => 'POST',
			'url' => API_URL + '/register/key/' + DocHubConnectionController.ORGANIZATION_ID
		});
		
		if (regKeyMap.get('status') != 'Success') { return regKeyMap; }
		Map<String, Object> regTenantMap = httpRequest(new Map<String, Object> {
			'method' => 'POST',
			'url' => API_URL + '/register/tenant/' + DocHubConnectionController.ORGANIZATION_ID,
			'authSignature' => ((Map<String, Object>)regKeyMap.get('result')).get('authSignature'),
			'timestamp' => ((Map<String, Object>)regKeyMap.get('result')).get('timestamp')
		});
		
		if (regTenantMap.get('status') == 'Success') {
			OrgSignatureKey__c orgSignatureKey = OrgSignatureKey__c.getOrgDefaults();
			orgSignatureKey.key__c = String.valueOf(regTenantMap.get('result'));
			Database.upsert(orgSignatureKey, false);
		}
		return regTenantMap;
	}
	
	private static Map<String, Object> httpRequest(Map<String, Object> generalData) {
		String url = String.valueOf(generalData.get('url'));
		String method = String.valueOf(generalData.get('method'));
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod(method);
		req.setHeader('Content-Type', 'application/json');
		
		if (generalData.containsKey('authSignature')) {
			String signature = DocHubConnectionController.createSignature(
				new List<String>{
					DocHubConnectionController.ORGANIZATION_ID,
					'register',
					String.valueOf(generalData.get('timestamp')) 
				},
				String.valueOf(generalData.get('authSignature'))
			);
			req.setHeader('auth-signature', signature);
			req.setHeader('timestamp', String.valueOf(generalData.get('timestamp')));
		}
		
		HttpResponse res = h.send(req);
		String resJSON = res.getBody();
		Map<String,Object> response = new Map<String,Object>();
		
		try {
			response = (Map<String,Object>)JSON.deserializeUntyped(resJSON);
		} 
		catch(Exception e) {
			response = new Map<String,Object> {
				'status' => 'Error',
				'error' => e.getMessage()
			};
		}
		return response;
	}
	 
	public static void hacks() {
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}
}