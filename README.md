# GSM IP Gateway
There are two parts:  
1) Asterisk as main server placed on cloud server based on Ubuntu x86/arm64
2) Asterisk as remote SIP wrapper for GSM-dongle placed on OpenWRT based box or Ubuntu x86 net top. 
##  Install main server
From root gsm-ip-gateway do
```shell
scp install_asterisk_main.sh,server-main root@IP:/tmp  
ssh root@IP
```
Execute appropriate install script.

Let's say we have IP=192.168.10.100
Then:
```shell
scp -O install_asterisk_main.sh,server-main root@192.168.10.100:/tmp`  
ssh root@192.168.110.100`
cd /tmp
chmod +x install_asterisk_main.sh  
./install_asterisk_main.sh
```

##  Install remote part (OpenWRT)

```shell
scp -O install_asterisk_client.sh,server-client root@IP:/tmp  
ssh root@IP
```  
Let's say we have IP=192.168.1.100
Then:
```shell
scp -O install_asterisk_client.sh,server-client root@192.168.1.100:/tmp`  
ssh root@192.168.1.100`
cd /tmp  
chmod +x install_asterisk_client.sh  
./install_asterisk_client.sh
```

To issue SSL certificate manually you should install certbot and do:  
`certbot certonly --standalone -d hostname`

To be able to send voice records by telegram and email you have to fill [extensions_tokens.conf](server-main%2Fextensions_tokens.conf)
And launch [install_asterisk_main_update_configs.sh](install_asterisk_main_update_configs.sh)

It uses Mutt as email smtp client and it is tricky. If Mutt doesn't send emails and says nothing in logs then probably the matter is SSL certificate that must be accepted once and stored. Just try:  
1. Fill /etc/Muttrc
2. `sudo -u asterisk -s mutt -s 'message test' <email_to>`

Some hints:  
`pjsip show endpoints`  
`core show translation` - show transcode matrix  
`core show channel` - show active channel details (codec etc)  
`core show translation paths gsm`