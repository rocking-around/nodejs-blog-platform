#### Log in to the [DevHub](https://gdsi-litify-dev-ed.develop.my.salesforce.com)

```
sfdx auth:web:login --setdefaultusername --setalias DevHub
```

#### Create a Scratch Org

```
sfdx force:org:create --setdefaultusername --definitionfile config/project-scratch-def.json --durationdays 7 --setalias iManageIntegrationPckg -u im.pckg.vers@gdsi-litify.com
```

### Push your changes to the Scratch Org

```
sfdx force:source:push
```

### Run tests

```
sfdx force:apex:test:run -r human --codecoverage --detailedcoverage --verbose
```

### Create Package Version

☝ <span style="color:orange">Change the major or minor version of the package in the `sfdx-project.json` file (versionNumber field).</span>

```
sfdx force:package:version:create --package "iManage Integration" --path "force-app" --targetdevhubusername eugene.bilobik@gdsi-litify.com --definitionfile config/project-scratch-def.json  --language en_US --wait 60 --codecoverage --postinstallscript iManagePostInstallClass --installationkey """wml6Qq&3r!D*2K4vfovu0"""
```

> The result of the operation looks like this.
>
> ```
> Version create.... Create version status: Success
> Successfully created the package version [08cDn000000fy17IAA]. Subscriber Package >Version Id: 04tDn000000Vtp6IAC
> Package Installation URL: https://login.salesforce.com/packaging/installPackage.apexp?>p0=04tDn000000Vtp6IAC
> As an alternative, you can use the "sfdx force:package:install" command.
> ```

### Promote the package

[read more](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_dev2gp_create_pkg_ver_promote.htm)

You can obtain the version number by executing the ["List of package versions"](#list_of_pckg_versions) commands.

```
sfdx force:package:version:promote --noprompt --package <The ID (starts with 04t) or alias of the package version to promote.>  --targetdevhubusername eugene.bilobik@gdsi-litify.com
```

<span style="color:green">Voila!!! 🎈🥳🎉</span>

---

## Other useful commands

#### <a id="list_of_pckg_versions" name="list_of_pckg_versions"></a>List of package versions

`sfdx force:package:version:list -p "Docrio iManage Integration" --targetdevhubusername eugene.bilobik@gdsi-litify.com --verbose`

#### List all packages in the Dev Hub org.

`sfdx force:package:list -v eugene.bilobik@gdsi-litify.com --json`

#### List the org’s installed packages.

`sfdx force:package:beta:installed:list -u SCRATCH_ORG_USER_NAME`
