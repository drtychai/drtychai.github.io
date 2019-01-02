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

Our content is within `<pre>` tags.


## Solution
