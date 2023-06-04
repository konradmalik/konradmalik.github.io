---
title: "Git Sign"
date: 2023-06-04T22:30:08+02:00
draft: true
toc: false
images:
tags:
    - tips
    - git
---

-   gpg
    -   older way
    -   autodetect via email
    -   include if
-   ssh
    -   key directly
    -   key file (pub)
    -   include if
    -   defaultKeyCommand

```bash
#!/usr/bin/env bash

set -e

allKeys=$(curl https://gitlab.com/konradmalik.keys | cut -d " " -f -2 | sort)

agentKeys=$(ssh-add -L | cut -d " " -f -2 | sort)

agentFoundKey=$(comm -12 <(echo "$allKeys") <(echo "$agentKeys"))
if [ -z "$agentFoundKey" ]
then
  agentFoundKey=$(cat /Users/konrad/.ssh/personal.pub)
fi

echo "key::$agentFoundKey"
```
