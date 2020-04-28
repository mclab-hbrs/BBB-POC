# BBB LFI Writeup
TL;DR: The patch for CVE-2020-12112 was insufficient. Lukas2511 found a bypass for it, so update to v2.2.6 asap.

## CVE-2020-12112
BigBlueButton had a rather trivial LFI. It is described [here](https://github.com/tchenu/CVE-2020-12112).

Essentially it was possible to change the `presFilename` URL parameter to download aritraty files, instead of the presentiation.
Example request downloading `/etc/passwd`:

```
curl https://test.bigbluebutton.org/bigbluebutton/presentation/download/ffc98830dbfbac3dcc80cc4c5f30711ebd1c23e8-1586764259489/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1586764259500?presFilename=../../../../../etc/passwd
```

## The Patch
The BigBlueButton maintainters rolled out an [emergency fix](https://github.com/bigbluebutton/bigbluebutton/commit/5ebdf5ca7718fc8bb3c08867edd150278e6a724c#diff-c7d77969a4547b5349e55c5466948a27R45) with version 2.2.5.

Instead of fixing the LFI in the service, they added a check to the NGINX reverse proxy config:

```
location ~ "^/bigbluebutton/presentation/download\/[0-9a-f]+-[0-9]+/[0-9a-f]+-[0-9]+$" {
			if ($arg_presFilename !~ "^[0-9a-f]+-[0-9]+\.[0-9a-zA-Z]+$") {
				return 404;
			}
			proxy_pass         http://127.0.0.1:8090$uri$is_args$args;
			proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
			# Workaround IE refusal to set cookies in iframe
			add_header P3P 'CP="No P3P policy available"';
}
```

With this check at the reverse proxy, the `pregFilename` parameter can only consist of characters, digits and a single dot. Therefore, directory traversal via `../` should not be possible.

Unfortunately, this patch has (at least) two problems:

1. The vulnerable java service is, by default, exposed to the outer world via port 8090. So the LFI is directly accessible in case a BBB admin did not set a corresponding firewall rule. The [documentation](https://docs.bigbluebutton.org/2.2/configure-firewall.html#configure-your-firewall) does explain what ports are needed  for the service, but this is still a very bad default.
2. Even with restrictive firewall rules, the LFI can still be exploited through the reverse proxy.

## Exploit via Reverse Proxy
![Reverse Proxy Go Brrr](https://redrocket.club/reverse_proxy_go_brrr.png)

As it turns out, the `$arg_VARNAME` variable in NGINX is case-insensitive. 
This makes it possible to desynchronize the reverse proxy and the vulnerable backend service.

Appending two parameters to the URL of the form:

`?presfilename=ff-1337.pdf&presFilename=../../../../../../../../etc/passwd`

triggers the LFI. 

NGINX checks `presfilename` for validity, but the Java backend interprets the `presFilename` parameter. Therefore the requested file will be returned by the backend.

## Impact
Using the LFI an attacker can for example download the file `/usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties` which contains the `securitySalt` value in cleartext. With this `securitySalt` the attacker has access to the API, effectively gaining administrator privileges.

## Take Aways
The key takeaways here are:

1. Always use failsafe defaults. Exposing an internal service to the outer world is probably not a good idea.
2. Instead of mitigating, always fix the **root of cause**, the actual vulnerability .

But of course this is easy for me to say. I don't have to fix anything.

BigBlueButton is a great open source tool with a very active developer community. They fixed the reported bugs very fast (I assume in their spare time). So maybe consider supporting BBB by [contributing to the project](http://docs.bigbluebutton.org/support/faq.html#how-can-i-contribute).

