#! /bin/sh

# Convert the output of 
#  ssh-keygen -E md5 -lf ssh_host_ecdsa_key.pub
#   256 MD5:cb:67:e6:ee:86:90:c0:60:99:c8:11:db:7f:8d:91:f5 no comment (ECDSA)
#  to
#   MD5:cb:67:e6:ee:86:90:c0:60:99:c8:11:db:7f:8d:91:f5
#
# REF:
#  https://unix.stackexchange.com/questions/321525/how-to-confirm-ssh-fingerprint
#  http://www.phcomp.co.uk/Tutorials/Unix-And-Linux/ssh-check-server-fingerprint.html
#  https://serverfault.com/questions/132970/can-i-automatically-add-a-new-host-to-known-hosts
#
# See also:
#  https://www.google.com/search?q=ssh-keyscan+add+to+known_hosts
#  https://unix.stackexchange.com/questions/126908/get-ssh-server-key-fingerprint
#   contains these examples:
#     ssh-keyscan 192.168.1.13 2>/dev/null | ssh-keygen -E md5 -lf -
#    and
#     ssh-keygen -E md5 -lf <(ssh-keyscan 192.168.1.13 2>/dev/null)
#    which outputs:
#     2048 MD5:46:be:94:9e:b7:00:5f:f1:fd:91:6f:a2:a1:96:8e:dd 192.168.1.13 (RSA)
#     256 MD5:cb:67:e6:ee:86:90:c0:60:99:c8:11:db:7f:8d:91:f5 192.168.1.13 (ECDSA)
#     256 MD5:ca:f0:7c:e0:bb:be:bd:51:24:65:78:f3:f0:f6:aa:64 192.168.1.13 (ED25519)

ssh-keygen -E md5 -lf ssh_host_ecdsa_key.pub | sed 's/^[0-9]* //' | sed 's/ .*$//'

