---
layout: post
title: flaglab
category: Real-World-CTF-2018
---

Note: This post is still in progress. Sorry for the delay!

# flaglab
>You might need a 0day.  
>http://100.100.0.100  
>download

In the download, we're given `docker-compose.yml`:

```bash
web:
  image: 'gitlab/gitlab-ce:11.4.7-ce.0'
  restart: always
  hostname: 'gitlab.example.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://gitlab.example.com'
      redis['bind']='127.0.0.1'
      redis['port']=6379
      gitlab_rails['initial_root_password']=File.read('/steg0_initial_root_password')
  ports:
    - '5080:80'
    - '50443:443'
    - '5022:22'
  volumes:
    - '/srv/gitlab/config:/etc/gitlab'
    - '/srv/gitlab/logs:/var/log/gitlab'
    - '/srv/gitlab/data:/var/opt/gitlab'
    - './steg0_initial_root_password:/steg0_initial_root_password'
    - './flag:/flag:ro'
```

and `reset.sh`:

```bash
#!/bin/sh
echo -n `head -n1337 /dev/urandom | sha512sum | cut -d' ' -f1` > steg0_initial_root_password
```

After speaking with the organizers, we're told that the goal of this challenge is to achieve RCE on the dockerized GitLab container.
