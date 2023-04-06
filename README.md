# GSM IP Gateway
There are two parts:  
1) Asterisk as main server placed on cloud server based on Ubuntu x86/arm64
2) Asterisk as remote SIP wrapper for GSM-dongle placed on OpenWRT based box or Ubuntu x86 net top. 
##  Install main server
From root gsm-ip-gateway do
```shell
scp * root@IP:/tmp  
ssh root@IP
```
Execute appropriate install script.

Let's say we have IP=192.168.10.100
Then:
```shell
scp -O * root@192.168.10.100:/tmp`  
ssh root@192.168.110.100`
cd /tmp  
./install_asterisk_modem.sh
```

##  Install remote part (OpenWRT)

```shell
scp -O * root@IP:/tmp  
ssh root@IP
```  
Let's say we have IP=192.168.1.100
Then:
```shell
scp -O * root@192.168.1.100:/tmp`  
ssh root@192.168.1.100`
cd /tmp  
./install_asterisk_standalone.sh
```

To issue SSL certificate manually you should install certbot and do:  
`certbot certonly --standalone -d hostname`

Some hints:  
`pjsip show endpoints`  
`core show translation` - show transcode matrix  
`core show channel` - show active channel details (codec etc)  
`core show translation paths gsm`