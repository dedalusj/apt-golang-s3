# apt-golang-s3

_An s3 transport method for the `apt` package management system_

The apt-golang-s3 project provides support for hosting private
[apt](https://en.wikipedia.org/wiki/APT_(Debian)) repositories in
[Amazon S3](https://aws.amazon.com/s3/). This is useful if you have private
packages, vendored public packages, or forks of public packages that your
software or business depend on. There are several opensource projects that
solve this problem, but they come with some limitations.

1. They are unmaintained.
1. They don't support the S3v4 request signature method.
1. They are written in a language that requires a runtime or other dependencies.

This project is an attempt to address those limitations.

## TL;DR
1. Build the binary `$ make build`
1. Install the binary `$ sudo cp s3 /usr/lib/apt/methods/s3`
1. Add your s3 based source to a package list `$ echo "deb s3://access-key:access-secret@s3.amazonaws.com/private-repo-bucket stable main" > /etc/apt/sources.list.d/private-repo.list`
1. Update and install packages `$ sudo apt-get update && sudo apt-get install your-private-package`

## Building the go program

There is an included Dockerfile to set up an environment for building the binary
in a sandbox environment:

```
$ ls
Dockerfile  main.go  method  README.md

$ docker build -t apt-golang-s3 .
...

$ docker run -it --rm -v $(pwd):/app apt-golang-s3 bash

root@83823fffd369:/app#make build
...

root@83823fffd369:/app# ls
Dockerfile  README.md  s3  go.mod  go.sum  main.go  method

root@83823fffd369:/app# exit
exit

$ ls
s3  Dockerfile  go.mod  go.sum  main.go  method  README.md
```

## Building a debian package

For convenience, there is a make target that can build
the binary and package it as a .deb.

```
$ ls
Makefile  Dockerfile  go.mod  go.sum  main.go  method  README.md

$ docker build -t apt-golang-s3 .

$ docker run -it --rm -v $(pwd):/app apt-golang-s3 make build_debian

$ ls
s3  apt-golang-s3-<version>.deb  Dockerfile  go.mod  go.sum  main.go  method  README.md
```

## Installing in production

The `s3` binary is an executable. To install it copy it to
`/usr/lib/apt/methods/s3` on your computer. The .deb file produced by
`make build_debian` will install the method in the correct place.


## Configuration
### APT Repository Source Configuration

We recommend issuing a separate set of API keys, with read-only access, to the
S3 bucket that hosts your repository. The keys are specified in the apt sources
list configuration as follows:

```
$ cat /etc/apt/sources.list.d/my-private-repo.list
deb s3://aws-access-key-id:aws-secret-access-key@s3.amazonaws.com/my-private-repo-bucket stable main
```

### APT Method Configuration

The current default AWS region is set to `us-east-1`, but can be overridden by
adding an option in your apt configuration, e.g.

```plain
echo "Acquire::s3::region us-east-1;" > /etc/apt/apt.conf.d/s3
```

Alternatively, you may specify an IAM role to assume before connecting to S3.
The role will be assumed using the default credential chain; this option is
mutually exclusive with static credentials in the S3 URL.

```plain
echo "Acquire::s3::role arn:aws:iam::123456789012:role/s3-apt-reader;" > /etc/apt/apt.conf.d/s3
```

Additional configuration options may be added in the future.

## How it works

Apt creates a child process using the `/usr/lib/apt/methods/s3` binary and
writes to that processes standard input using a specific protocol. The method
interprets the input, downloads the requested files, and communicates back to
apt by writing to its standard output. The protocol spec is available here
[http://www.fifi.org/doc/libapt-pkg-doc/method.html/ch2.html](http://www.fifi.org/doc/libapt-pkg-doc/method.html/ch2.html).

## Similar Projects
* [https://github.com/kyleshank/apt-transport-s3](https://github.com/kyleshank/apt-transport-s3)
* [https://github.com/brianm/apt-s3](https://github.com/brianm/apt-s3)
* [https://github.com/BashtonLtd/apt-transport-s3](https://github.com/BashtonLtd/apt-transport-s3)
* [https://github.com/lucidsoftware/apt-boto-s3/](https://github.com/lucidsoftware/apt-boto-s3/)

## Disclaimer
This is not an officially supported Google product.
