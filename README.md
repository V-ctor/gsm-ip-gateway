# GSM IP Gateway

## OpenWRT

```shell
scp -O * root@IP:/tmp  
ssh root@IP
```  
Let's say we have IP=192.168.1.100
Then:
```shell
scp -O * root@192.168.1.100:/tmp`  
ssh root@192.168.1.100`
```
In ssh console:
```
cd /tmp  
./install.sh
```

Some hints:  
`pjsip show endpoints`  
`core show translation` - show transcode matrix  
`core show channel` - show active channel details (codec etc)  
`core show translation paths gsm`