
### USERS(
# base file: default-users.ks

#  The line below is a GREP TARGET
#### ROOT USER
rootpw              --iscrypted $6$XUlNdPVaba7zFwIk$q8bUKlj.IW9ioptgwwbstfcc5iLRmgiM9jTDk.mfRKEDhfiDXc2xNvz1iKbcJJ1K1c/Akd35F4TKHYjJju8MX.

#### Fixer Group
group --name=fixer

#### Other User(s)
user --name=autoFxr --iscrypted --password=$6$zjQbd2k.NVvornMW$m3kNQ715LFXVa/xo5XatlpCrNAsgFc7BLxf7nzIQ7QX8VLI4mvBlPFTvEY80JKeA.hzWVaL4ICkmRJdNQDPrG/ --groups=fixer,wheel --gecos "fixer,gitter" 

user --name=manuFxr --iscrypted --password=$6$root$VFi1MZra5QDHdPj0DtPgd/jr9pbtI4efEQYtu1pk2Dlkd0qUc1y/.OErWsYBGccYQAQ7xwoEUrRiglyhqSPg01             --groups=fixer,wheel --gecos "fixer,gitter"
### )

