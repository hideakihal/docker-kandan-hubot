docker-kandan-hubot
===================
Dockerfile to build image which is installed Kandan and hubot.
blog: http://hidemium.hatenablog.com/entry/2014/11/03/022453

## Usage

Building

```
$ git clone https://github.com/hideakihal/docker-kandan-hubot
$ sudo docker build -t kandan-hubot docker-kandan-hubot
```

Running

```
$ sudo docker run -d -p 22 -p 3000:3000 kandan-hubot
```

## Contents

The image contains:

- Kandan 1.2
- hubot 2.4.7
- hubot-kandan adapter 1.0

## References

  * https://github.com/github/hubot
  * https://github.com/kandanapp/kandan
  * https://github.com/kandanapp/hubot-kandan
