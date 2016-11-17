# Passenger Binary Build Automation System

This is a system for building portable Linux and macOS binaries for [the Passenger web app server](https://www.phusionpassenger.com/) -- binaries that work on a wide range of Linux distributions and macOS versions. This is achieved as follows:

 * By statically linking any non-system dependencies.
 * On Linux: by compiling against an older glibc. See [Holy Build Box](https://github.com/phusion/holy-build-box#problem-introduction) for more information.
 * On macOS: by compiling against a sufficiently old deployment target version.

Phusion uses this system to build Passenger binaries, immediately following a source release, in a completely automated manner.

**Table of contents**

 * [Overview](#overview)
   - [Overview of binaries](#overview-of-binaries)
   - [How the system works: the build environment](#how-the-system-works-the-build-environment)
 * [Building binaries](#building-binaries)
   - [For Linux](#for-linux)
   - [For macOS](#for-macos)
 * [Maintenance](#maintenance)
   - [Upgrading libraries](#upgrading-libraries)
 * [Related projects](#related-projects)

## Overview

### Overview of binaries

This system builds the following binaries:

 * The Passenger agent.
 * Passenger Ruby native support extensions, for multiple Ruby versions.
 * Nginx.

The Nginx version that will be compiled is the version preferred by the Passenger codebase, but you can override the exact version that is to be built. The Nginx binary includes the following modules:

 * `http_ssl_module`
 * `http_v2_module`
 * `http_gzip_static_module`
 * `http_proxy_module`
 * `http_fastcgi_module`
 * `http_scgi_module`
 * `http_uwsgi_module`
 * `http_status_stub_module`
 * `http_addition_module`
 * `http_geoip_module`
 * `http_realip_module`

### How the system works: the build environment

`passenger_binary_build_automation` works by building Passenger and Nginx inside (semi-)controlled build environments.

On Linux, the build environment is a Docker container. The container is based [Holy Build Box](http://phusion.github.io/holy-build-box/) and contains an old glibc as well as a bunch of static libraries. Because Docker fully isolates a container from its host, this build environment is fully controlled: a build always succeeds no matter how the host is set up.

On macOS, the build environment consists of a directory containing select tools and static libraries (the runtime), plus bunch of environment variables that try to make sure the compiler only compiles against our selected static libraries. This is a semi-controlled build environment: building *usually* works, but *may* fail if the host is set up in such a way that it interferes with the build. However we've found in practice that it's good enough.

## Building binaries

### For Linux

Use the `linux/build` script to build binaries for Linux. [Docker](http://www.docker.com/) is required. Here is an example:

    $ cd linux
    $ ./build \
        -p /path-to-passenger-source \
        -c cache \
        -o output \
        -a x86_64 \
        passenger nginx

The `build` script expects at least the following arguments:

 * `-p`: path to the Passenger source code that you want to build.
 * `-c`: a directory which the script can use for caching data, in order to make subsequent builds faster. If this directory does not exist, then it will be created.
 * `-o`: a directory to store the built binaries in. If this directory does not exist, then it will be created.
 * `-a`: the architecture to build for. Either `x86` or `x86_64`.
 * And finally, a list of things that the script should build (_tasks_). In this example we specified two tasks, `passenger` and `nginx`. The passenger task builds the Passenger agent and all Ruby extensions, while the nginx task builds Nginx.

More command line options are available. Run `./build -h` to learn more. You can also run `./build -T` to learn which tasks are available.

When the above example build is finished, the output directory will contain these files:

    ruby-extensions/ruby-1.9.3-x86-linux/passenger_native_support.so
    ruby-extensions/ruby-2.3.2-x86-linux/passenger_native_support.so
    ruby-extensions/ruby-2.0.0-x86-linux/passenger_native_support.so
    ruby-extensions/ruby-2.1.9-x86-linux/passenger_native_support.so
    ruby-extensions/ruby-2.2.5-x86-linux/passenger_native_support.so
    support-binaries/PassengerAgent
    support-binaries/nginx-1.10.1

### For macOS

<a name="preparation-macos"></a>

#### Preparation

Before you can build binaries for macOS, you must ensure that these prerequities are (manually) installed:

 * Xcode command-line developer tools.
 * [RVM](https://rvm.io).
 * All Ruby versions specified in the `shared/definitions/ruby_versions` file.

Once these prerequisites are installed, you must build a runtime using the `macos/setup-runtime` script. A runtime is a directory containing further tools and libraries that `passenger_binary_build_automation` needs for building binaries. The runtime needs to be setup the first time you use `passenger_binary_build_automation`, and every time the list of libraries that we link into Passenger or Nginx changes.

Here is an example invocation:

    $ cd macos
    $ ./setup-runtime -c cache -o runtime-output

The `setup-runtime` script expects at least the following arguments:

 * `-c`: a directory which the script can use for caching data, in order to make subsequent runtime builds faster. If this directory does not exist, then it will be created.
 * `-o`: a directory to store the runtime in. If this directory does not exist, then it will be created.

#### Building

Use the `macos/build` script to build binaries for macOS. Here is an example:

    $ cd macos
    $ ./build \
        -p /path-to-passenger-source \
        -c cache \
        -o output \
        passenger nginx

The `build` script expects at least the following arguments:

 * `-p`: path to the Passenger source code that you want to build.
 * `-c`: a directory which the script can use for caching data, in order to make subsequent builds faster. If this directory does not exist, then it will be created.
 * `-o`: a directory to store the built binaries in. If this directory does not exist, then it will be created.
 * And finally, a list of things that the script should build (_tasks_). In this example we specified two tasks, `passenger` and `nginx`. The passenger task builds the Passenger agent and all Ruby extensions, while the nginx task builds Nginx.

More command line options are available. Run `./build -h` to learn more. You can also run `./build -T` to learn which tasks are available.

When the above example build is finished, the output directory will contain these files:

    support-binaries/nginx-1.10.1
    support-binaries/PassengerAgent

The macOS build script does not build Ruby native extensions because we haven't yet figured out a way to do that in a portable manner.

## Maintenance

### Upgrading libraries

`passenger_binary_build_automation` statically links a number of libraries into the Passenger agent and Nginx. These libraries need to be updated once in a while, e.g. when important bugs or security vulnerabilities have been fixed. The procedure for doing that is as follows.

 1. Change the relevant library version numbers in `shared/definitions`.
 2. Bump the version numbers in `shared/definitions/docker_image_version` and `shared/definitions/docker_image_major_version`.
 3. Rebuild the Docker container and the macOS runtime:

    - On Linux: run `./linux/setup-docker-image-32` and `./linux/setup-docker-image-64`.
    - On macOS: remove the runtime directory and rebuild the runtime (see [Building binaries / For macOS / Preparation](#preparation-macos)).

 4. On Linux: publish the new Docker container to the Docker Hub: run `./linux/publish-docker-images`
 5. Git commit and push.
 6. In the Passenger Git repository, update the `packaging/binaries` submodule to this commit.
 7. Either release a new Passenger version, or rebuild binaries against the current Passenger version and rebpulish them.

## Related projects

 * https://github.com/phusion/passenger_apt_automation
 * https://github.com/phusion/passenger_rpm_automation
