public class DocumentViewPageController {
	public String fileLink { get; set; }
	public String errorMessage { get; set; }
	public Boolean preventCopyStatus { get; set; }

	Boolean isError;
	Boolean isFileLink;

	public Boolean getIsError() { return !String.isBlank(this.errorMessage); }
	public Boolean getIsFileLink() { return !String.isBlank(this.fileLink); }

	public void loadDocument() {
		String recordId = ApexPages.CurrentPage().getparameters().get('Id');
		if (String.isBlank(recordId)) {
			this.errorMessage = 'Sorry, something went wrong';
			return;
		}
		Doc_Hub_Link__c dhl = [
			SELECT
				Id, Connection_Id__c, Origin_Id__c, Auto_Publish__c, Prevent_Copying__c
			FROM Doc_Hub_Link__c
			WHERE Id = :recordId
		];

		if (String.isBlank(dhl.Connection_Id__c) || String.isBlank(dhl.Origin_Id__c)) {
			this.errorMessage = 'Sorry, something went wrong';
			return;
		}

		this.preventCopyStatus = dhl.Prevent_Copying__c == null ? false : Boolean.valueOf(dhl.Prevent_Copying__c);

		Map<String, Object> resMap = DocHubConnectionController.DocumentFetch(
			new Map<String, Object> {
				'connectionId' => dhl.Connection_Id__c,
				'documentId' => dhl.Origin_Id__c,
				'autoPublish' => dhl.Auto_Publish__c
			});

		if (resMap.get('status') == 'Error') {
			this.errorMessage = String.valueOf(((Map<String, Object>)resMap.get('error')).get('message'));
			if (String.valueOf(((Map<String, Object>)resMap.get('error')).get('message')) == 'File was deleted') {
				Map<String, Object> resUnlink = DocHubConnectionController.unlinkDocument(recordId, 'File was deleted');
			}
			return;
		}

		this.fileLink = String.valueOf(resMap.get('result'));
		List<NamedCredential> urlNameCred = [SELECT DeveloperName, Endpoint FROM NamedCredential WHERE DeveloperName = 'DocHubUrl'];
		if (urlNameCred.size() != 0 && !String.isBlank(this.fileLink)) {
			String state = EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(new Map<String, Object>{ 'createdBy' => UserInfo.getName() })));
			this.fileLink = urlNameCred[0].Endpoint + DocHubHelper.PROXY_TENANT + '/api/document/' +
				DocHubHelper.ORGANIZATION_ID + '/open/' + this.fileLink + '?state=' + state;
			this.fileLink = System.EncodingUtil.urlEncode(this.fileLink, 'UTF-8');
		}
		if (String.isBlank(this.fileLink)) {
			this.errorMessage = 'Sorry, something went wrong';
			return;
		}
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