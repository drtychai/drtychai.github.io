---
layout: post
title: filemanager
category: 35c3ctf
---

# Description
We'll be doing a post-mortem for this challenge. Unfortunately, we weren't able to solve it in time, but that doesn't mean we didn't learn a lot about client-side attacks and browser protections! We'll start with how we approached the problem, our ideas, and finally, the solution.

Note: This post is still in progress. Sorry for the delay!

# filemanager
>Check out my web-based filemanager running at https://filemanager.appspot.com.  
>The admin is using it to store a flag, can you get it? You can reach the admin's chrome-headless at: nc 35.246.157.192 1

Before diving into the webapp, let's make sure we understand everything we're given.
- There's a "filemanager" application hosted at `https://filemanager.appspot.com`.
- We also have access to a headless chrome browser that retains the admins session.


## Admin's Headless Chrome
Headless Chrome is a way to run a Chrome browser without the full browser UI. Let's connect to the instance and see what we can do with it.

```bash
$ nc 35.246.157.192 1
Please solve a proof-of work with difficulty 22 and prefix 96bb using https://www.npmjs.com/package/proof-of-work
```

Immediately upon connection, we are required to solve a proof-of-work. These are typically in place to deter DoS, similar to a captcha. It appeared that we needed to solve a different proof-of-work for every connection made, so we automated it.

```python
#!/usr/bin/env python2
from pwn import *
import re

HOST = "35.246.157.192"
PORT = "1"

def proof_of_work(difficulty, prefix):
    log.info("Solving proof-of-work...")
    solver = process(["node", "./solver.js", difficulty, prefix])
    p_of_w = solver.recvline().strip()
    solver.close()
    return p_of_w

def exploit(r):
    # Get the challenge difficulty and prefix
    challenge = r.recvline()
    matches = re.match(".+ difficulty (\d+) and prefix (.+) using", challenge)
    difficulty, prefix = matches.groups()
    log.info("Difficulty : {}, Prefix : {}".format(difficulty, prefix))

    # Solve proof-of-work and start interactive shell
    p_of_w = proof_of_work(difficulty, prefix)
    r.sendline(p_of_w)
    r.interactive()
    return

if __name__ == "__main__":
    r = remote(HOST,PORT)
    exploit(r)
```

```js
// solver.js
const pow = require('proof-of-work');
const solver = new pow.Solver();
args = process.argv
var complexity = Number(args[2])

const prefix = Buffer.from(args[3], 'hex');
const nonce = solver.solve(complexity, /* optional */ prefix);
console.log(nonce.toString('hex'));
```


```bash
$ ./xpl.py
[+] Opening connection to 35.246.157.192 on port 1: Done
[*] Difficulty : 22, Prefix : 96bb
[*] Solving proof-of-work...
[+] Starting local process '/usr/local/bin/node': pid 6681
[*] Stopped process '/usr/local/bin/node' (pid 6681)
[*] Switching to interactive mode
Proof-of-work verified.
Please send me a URL to open.
$
```

Let's see what happens if we try to connect to our VPS.

```bash
$ nc -lvp 8080
Listening on [0.0.0.0] (family 0, port 1337)
Connection from 158.83.234.35.bc.googleusercontent.com 50606 received!
GET / HTTP/1.1
Host: 18.216.16.73:8080
Connection: keep-alive
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/72.0.3617.0 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8
Accept-Encoding: gzip, deflate
```

Great! So now we know that _any_ URL can be fed to the instance and we have the User-Agent.


## WebApp
Upon visiting the webpage, we are redirected to a signup page.  
![signup](https://drtychai.github.io/assets/img/35c3/filemanager-signup.png)

By creating a user, we are directed to the user homepage.   
Note: it appears user's access controls are handled by a session cookie.  
![home](https://drtychai.github.io/assets/img/35c3/filemanager-home.png)

Let's create a file, paying close attentions to the how the request is sent to the server and how it's displayed back to us.  
![home2](https://drtychai.github.io/assets/img/35c3/filemanager-home-with-file.png)

Visiting this file:  
![readfile](https://drtychai.github.io/assets/img/35c3/filemanager-file-contents.png)

It looks like the file is just being displayed directly back to us, but wait:  
![sourcecode](https://drtychai.github.io/assets/img/35c3/filemanager-read-sourcecode.png)

Our content is within `<pre>` tags. Let's pause for a moment and create a site map.

```
Backend:
- Server : Google Frontend (GCP App)
- Language : HTML, JS

WebApp Description:
- The app is a file managing system. One can upload files via form data, read their own files, and search via the content of their own files.

Site Map:
- /signup (GET/POST)
- /create (POST)
  - `multipart/form-data` is sent via POST (2 parts)
    - "filename"
    - "content"
- /read (GET)
  - /read?filename=testfile (GET)
- /search (GET)
  - /search?q=test (GET)

Interesting Headers:
- POST /create
  - `xsrf: 1`
  - as per JS code found in source code of / page

Places for User Input:
- /signup
  - username input only allows lowercase ascii characters
- /create
  - form-data allows any input (including JS code)
- /read
  - allows any input to query string param
- /search
  - allows any input to query string param
```

Two segments of JS stand out as important. The code for the `/create` page:
```JS
<script>
  function doSubmit(e) {
    e.preventDefault();
    document.getElementById('submit-button').disabled = true;
    let filename = document.getElementById('filename').value;
    const data = new FormData(e.target);
    fetch('/create', {method: 'POST', body: data, headers: {XSRF: '1'}}).then(r=>{
      document.getElementById('submit-button').disabled = false;
      if (r.ok) {
        let li = document.createElement('li');
        let a = document.createElement('a');
        li.appendChild(a);
        a.innerText = filename;
        a.href = `/read?filename=${filename}`;
        document.getElementById('file-list').appendChild(li);
      } else {
        console.log('error creating file');
      }
    }).catch((e)=>{
      console.log('error creating file '+e);
      document.getElementById('submit-button').disabled = false;
    });
    return false;
  }

  var form = document.getElementById('create-form');
  form.addEventListener("submit", doSubmit);
</script>
```

and the code for the `/search` function:
```JS
<script>
  (()=>{
    for (let pre of document.getElementsByTagName('pre')) {
      let text = pre.innerHTML;
      let q = 'content';
      let idx = text.indexOf(q);
      pre.innerHTML = `${text.substr(0, idx)}<mark>${q}</mark>${text.substr(idx+q.length)}`;
    }
  })();
</script>
```
both found in the HTML source.

## Our Approach
With all our enumeration complete, we came up with the following plan:
1. Make admin visit a page on a VPS
2. Do CSRF to upload XSS file
3. Redirect to search page
4. Profit

We were able to successfully find a stored self-XXS by hex encoding and uploading the following:

```HTML
<img src=x onerror=alert(document.cookie)>
```
![xss](https://drtychai.github.io/assets/img/35c3/filemanager-xss.png)

The one caveat of our plan - we couldn't find a way around was the `XSRF : 1` HTTP Header in the POST request to `/create`.


## Solution
