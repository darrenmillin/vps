# OVHcloud baremetal migration instructions

This markdown document is for developers and IT technicians.

Dear Valued OVHcloud Customer,

Regarding your account for **md1205261-ovh**,

This document represents all the personal templates you have defined under the **[`/me/installationTemplate` section](https://eu.api.ovh.com/console/?section=%2Fme&branch=v1#get-/me/installationTemplate)** for nic **md1205261-ovh** at the following date: `2025-05-19 13:45:50`.

Starting from the **17th of June 2025 (2025-06-17)**, API calls under the [`/me/installationTemplate` section](https://eu.api.ovh.com/console/?section=%2Fme&branch=v1#get-/me/installationTemplate) will be removed. This will prevent you from creating or altering your personal templates (all `POST` and `PUT` routes will be removed).

Starting from the **7th of October 2025 (2025-10-07)**, API call [`POST /dedicated/server/{serviceName}/install/start`](https://eu.api.ovh.com/console/?section=%2Fdedicated%2Fserver&branch=v1#post-/dedicated/server/-serviceName-/install/start) as well as all API calls managing your personal templates under the [`/me/installationTemplate` section](https://eu.api.ovh.com/console/?section=%2Fme&branch=v1#get-/me/installationTemplate) will be removed. This basically means that all your personal templates defined under the [`/me/installationTemplate` section](https://eu.api.ovh.com/console/?section=%2Fme&branch=v1#get-/me/installationTemplate) will be removed as well.

More details about this migration can be found [here](https://help.ovhcloud.com/csm/en-gb-dedicated-servers-end-of-life-for-personal-installation-templates?id=kb_article_view&sysparm_article=KB0067551).

**You can save this document for later use. Keep in mind that after the 7th of October 2025 (2025-10-07), you will no longer be able to use the API calls you used to display details about your personal templates. So this document will be the only place where all your personal templates data remains. OVHcloud takes no responsibility for the data in that document. We strongly recommend backing up this file before editing it.**

This document will help you migrate from the [`POST /dedicated/server/{serviceName}/install/start`](https://eu.api.ovh.com/console/?section=%2Fdedicated%2Fserver&branch=v1#post-/dedicated/server/-serviceName-/install/start) API call with personal templates defined under the [`/me/installationTemplate` section](https://eu.api.ovh.com/console/?section=%2Fme&branch=v1#get-/me/installationTemplate) to the **new [`POST /dedicated/server/{serviceName}/reinstall`](https://eu.api.ovh.com/console/?section=%2Fdedicated%2Fserver&branch=v1#post-/dedicated/server/-serviceName-/reinstall) API call in order to install/reinstall an OS on a dedicated server**.

## ⚠ WARNING ⚠

> **Performing a [`POST /dedicated/server/{serviceName}/install/start`](https://eu.api.ovh.com/console/?section=%2Fdedicated%2Fserver&branch=v1#post-/dedicated/server/-serviceName-/install/start) or [`POST /dedicated/server/{serviceName}/reinstall`](https://eu.api.ovh.com/console/?section=%2Fdedicated%2Fserver&branch=v1#post-/dedicated/server/-serviceName-/reinstall) on a dedicated server will erase all the data in that server. PLEASE BE CAREFUL WHILE USING THOSE API CALLS.**

## 1. Template(s) export

Here is the personal template with its 1 equivalent payload for your account md1205261-ovh. This payload may be used with the new **[`POST /dedicated/server/{serviceName}/reinstall`](https://eu.api.ovh.com/console/?section=%2Fdedicated%2Fserver&branch=v1#post-/dedicated/server/-serviceName-/reinstall)** API call.
If you need to edit the API payload(s), in order to specify `sshKey`, `diskGroupId`, etc., you will find more details in the [public documentation](https://help.ovhcloud.com/csm/en-gb-dedicated-servers-api-os-installation?id=kb_article_view&sysparm_article=KB0061945#create-an-os-reinstallation-task).

ℹ Note that some payloads might not work on all dedicated servers, this depends on the server OS compatibility, licensing (if applicable), etc.

### 1.1. debian-bookworm-docker-r5-v8 (debian12_64 OS installation)

[`POST /dedicated/server/{serviceName}/reinstall`](https://eu.api.ovh.com/console/?section=%2Fdedicated%2Fserver&branch=v1#post-/dedicated/server/-serviceName-/reinstall)

```json
{
  "operatingSystem": "debian12_64",
  "customizations": {
    "hostname": "smaug"
  },
  "storage": [
    {
      "partitioning": {
        "layout": [
          {
            "mountPoint": "/boot",
            "raidLevel": 5,
            "fileSystem": "ext4",
            "size": 1024
          },
          {
            "mountPoint": "/",
            "raidLevel": 5,
            "fileSystem": "ext4",
            "size": 200000
          },
          {
            "mountPoint": "swap",
            "fileSystem": "swap",
            "size": 512
          },
          {
            "mountPoint": "/data",
            "raidLevel": 5,
            "fileSystem": "ext4",
            "size": 2439829
          },
          {
            "mountPoint": "/home",
            "raidLevel": 5,
            "fileSystem": "ext4",
            "size": 250000
          },
          {
            "mountPoint": "/media",
            "raidLevel": 5,
            "fileSystem": "ext4",
            "size": 2579657
          },
          {
            "mountPoint": "/var/lib/docker",
            "raidLevel": 5,
            "fileSystem": "ext4",
            "size": 250000
          }
        ]
      }
    }
  ]
}
```

## 2. Template(s) removal

Once you have migrated to the new [`POST /dedicated/server/{serviceName}/reinstall`](https://eu.api.ovh.com/console/?section=%2Fdedicated%2Fserver&branch=v1#post-/dedicated/server/-serviceName-/reinstall) route and no longer need personal templates, we we kindly ask you to remove them with the [`DELETE /me/installationTemplate/{templateName}`](https://eu.api.ovh.com/console/?section=%2Fme&branch=v1#delete-/me/installationTemplate/-templateName-) API call, for example:

[`DELETE /me/installationTemplate/debian-bookworm-docker-r5-v8`](https://eu.api.ovh.com/console/?section=%2Fme&branch=v1#delete-/me/installationTemplate/-templateName-)

We appreciate your patience and cooperation throughout the project. Thank you for being a loyal OVHcloud customer.

The OVHcloud Bare Metal Team.

Original document creation date: `2025-05-19 13:45:50`.
