---
layout: post
title: daring
category: hxp-2018
---
# Description
I could only play hxpCTF during my downtime at Hushcon, but found the challenges to be addicting.

# daring
>We encrypted our flag, but we lost the keys. Can you help?

Unpacking the given tarball gave us four files, `aes.enc`,`rsa.enc`, `pubkey.txt`, and the following python script, `vuln.py`:

```python
#!/usr/bin/env python3
import os
from Crypto.Cipher import AES
from Crypto.Hash import SHA256
from Crypto.Util import Counter
from Crypto.PublicKey import RSA

flag = open('flag.txt', 'rb').read().strip()

key = RSA.generate(1024, e=3)
open('pubkey.txt', 'w').write(key.publickey().exportKey('PEM').decode() + '\n')
open('rsa.enc', 'wb').write(pow(int.from_bytes(flag.ljust(128, b'\0'), 'big'), key.e, key.n).to_bytes(128, 'big'))

key = SHA256.new(key.exportKey('DER')).digest()
open('aes.enc', 'wb').write(AES.new(key, AES.MODE_CTR, counter=Counter.new(128)).encrypt(flag))
```
Immediately we notice that the flag is encrypted in two independent ways; one via AES CTR and the other via RSA with null byte padding.

Analyzing the script more carefully revealed both the use of weak padding and a small public key exponent. More specifically:
<br>&nbsp;&nbsp;&nbsp;&nbsp; 1. The flag is padded with a null byte,`\x00` to make the plaintext 128 bytes.
<br>&nbsp;&nbsp;&nbsp;&nbsp; 2. The padded flag is then encrypted with a small public key exponent, `e=3`.
<br>&nbsp;&nbsp;&nbsp;&nbsp; 3. The flag is also encrypted vis AES CTR. Recall: CTR mode requires the ciphertext to have &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;the exact same size as the plaintext.

Due to `1`, we notice that we cannot perform an attack on the small public key exponent. This is a common attack and only works if the cube of the plaintext is strictly less than the modulus. With

```bash
n: 131439155143175043265322066353951646221438306790938190998522265782952062884373948320963990364387806423377384374007937468177671276323489634193305141101111897782540226757793029784559400156340831524038843044706502635279773784856499312207447550053071060656400930280068219967242645499076062394053507154455753332851
```
it's clear to see that a number 128 bytes in length will be longer than the modulus above.

From `3` we know that the size of the ciphertext from the AES encryption will be the length of the flag, i.e. 43 bytes. Thus:

```
pt = flag + ''\x00'*(128-43)
ct = (flag * 2^680)^3 mod n

==> (ct * ((2^(-1) mod n)^(680*3) mod n)) mod n = [flag^3 * 2^(680*3) * 2^(-680*3)] mod n = flag^3 mod n
```

This yields, `flag^3 = x + k*n` for integers `x,k`. So by adding multiples of `n` to `x` and checking if the resultant is a perfect cube, we get out flag! The following does the above using `gmpy2`.

```python
#!/usr/bin/env python3
import os
from Crypto.Cipher import AES
from Crypto.Hash import SHA256
from Crypto.Util import Counter
from Crypto.Util.number import *
from Crypto.PublicKey import RSA
import gmpy2

pubkey = RSA.importKey(open("pubkey.txt").read())
e = pubkey.e
n = pubkey.n
rsa_enc = int.from_bytes(open("rsa.enc","rb").read(), 'big')

assert GCD(2, n) == 1
inv = pow(inverse(2, n), 680*3, n)
aes_enc = open("aes.enc","rb").read()

assert len(aes_enc) == 43
print(int.from_bytes(b"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa".ljust(128,b'\0'), 'big') == int.from_bytes(b"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 'big') << 680)

rsa_enc = rsa_enc*inv % n
for i in range(1000):
    ans = gmpy2.iroot(rsa_enc + i*n, 3)[1]
    if ans == True:
        print("[+] Success", i)
        pt = int(gmpy2.iroot(rsa_enc + i*n, 3)[0])
        print(pt.to_bytes(43, 'big'))
        break
```

```bash
hxp{DARINGPADS_1s_4n_4n4gr4m_0f_RSAPADDING}
```
