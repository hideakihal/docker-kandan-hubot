docker-kandan-hubot
===================
Dockerfile to build image which is installed Kandan and hubot.

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
