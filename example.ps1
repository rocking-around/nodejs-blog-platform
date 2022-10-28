[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$tokenurl = "https://login.salesforce.com/services/oauth2/token"
$postParams = [ordered]@{
    grant_type="password";
    client_id="<client_id>";
    client_secret="<client_secret>";
    username="<username>";
    password="<passwordToken>";
}
 
$access_token=(Invoke-RestMethod -Uri $tokenurl -Method POST -Body $postParams).access_token
 
$url = "https://<salesforce base url>/services/apexrest/gdsi_imanage/IManageCsv?objectName=...&separator=<separator>&startDate=<startDate>"
$result = Invoke-RestMethod -Uri $url -Headers @{Authorization = "Bearer " + $access_token}
$result | Out-File -FilePath "<result file name>.csv"