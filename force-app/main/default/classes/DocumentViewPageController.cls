public with sharing class DocumentViewPageController {
	public String fileLink { get; set; }
	
	public DocumentViewPageController() {
		String recordId = ApexPages.CurrentPage().getparameters().get('Id');
		if (String.isBlank(recordId)) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Sorry, something went wrong'));
		}
		Doc_Hub_Link__c dhl = [
			SELECT 
				Id, Connection_Id__c, Origin_Id__c, Auto_Publish__c
			FROM Doc_Hub_Link__c 
			WHERE Id = :recordId
		];

		if (String.isBlank(dhl.Connection_Id__c) || String.isBlank(dhl.Origin_Id__c)) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Sorry, something went wrong'));
		}
	   
		this.fileLink = DocHubConnectionController.DocumentFetch(
			new Map<String, Object> {
				'connectionId' => dhl.Connection_Id__c,
				'originId' => dhl.Origin_Id__c,
				'autoPublish' => dhl.Auto_Publish__c
			});
		List<NamedCredential> urlNameCred = [SELECT DeveloperName, Endpoint FROM NamedCredential WHERE DeveloperName = 'ApiUrl'];
		if (urlNameCred.size() != 0) {
			String state = EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(new Map<String, Object>{ 'createdBy' => UserInfo.getName() })));
			this.fileLink = urlNameCred[0].Endpoint + '/api/document/open/' + this.fileLink + '?state=' + state;
			this.fileLink = System.EncodingUtil.urlEncode(this.fileLink, 'UTF-8');
		}
		if (String.isBlank(this.fileLink)) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Sorry, something went wrong'));
		}
	}
}
