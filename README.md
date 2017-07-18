# Passenger Binary Build Automation System

This is a system for building portable Linux and macOS binaries for [the Passenger web app server](https://www.phusionpassenger.com/) -- binaries that work on a wide range of Linux distributions and macOS versions. This is achieved as follows:

 * By statically linking any non-system dependencies.
 * On Linux: by compiling against an older glibc. See [Holy Build Box](https://github.com/phusion/holy-build-box#problem-introduction) for more information.
 * On macOS: by compiling against a sufficiently old deployment target version.

Phusion uses this system to build Passenger binaries, immediately following a source release, in a completely automated manner.

**Table of contents**

 * [Overview](#overview)
   - [Overview of binaries](#overview-of-binaries)
   - [How the system works](#how-the-system-works)
 * [Building binaries](#building-binaries)
   - [For Linux](#for-linux)
   - [For macOS](#for-macos)
 * [Maintenance](#maintenance)
   - [Upgrading Ruby](#upgrading-ruby)
   - [Upgrading Nginx](#upgrading-nginx)
   - [Upgrading libraries](#upgrading-libraries)
   - [Updating the Docker container and runtime](#updating-the-docker-container-and-runtime)
   - [Updating the `passenger_binary_build_automation` version lock in Passenger](#updating-the-passenger_binary_build_automation-version-lock-in-passenger)
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

### How the system works

Learn more at: [How it works](HOW-IT-WORKS.md)

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
 * `-c`: a directory which the script can use for caching data, in order to make subsequent builds faster.
 * `-o`: a directory to store the built binaries in.
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
 * GPG.
 * [RVM](https://rvm.io).
 * All Ruby versions specified in the `shared/definitions/ruby_versions` file.

Once these prerequisites are installed, you must build a runtime using the `macos/setup-runtime` script. A runtime is a directory containing further tools and libraries that `passenger_binary_build_automation` needs for building binaries. The runtime needs to be setup the first time you use `passenger_binary_build_automation`, and every time the list of libraries that we link into Passenger or Nginx changes.

Here is an example invocation:

    $ cd macos
    $ ./setup-runtime -c cache -o runtime-output

The `setup-runtime` script expects at least the following arguments:

 * `-c`: a directory which the script can use for caching data, in order to make subsequent runtime builds faster.
 * `-o`: a directory to store the runtime in.

#### Building

Use the `macos/build` script to build binaries for macOS. Here is an example:

    $ cd macos
    $ ./build \
        -r runtime-output \
        -p /path-to-passenger-source \
        -c cache \
        -o output \
        passenger nginx

The `build` script expects at least the following arguments:

 * `-r`: path to the directory in which the runtime is stored.
 * `-p`: path to the Passenger source code that you want to build.
 * `-c`: a directory which the script can use for caching data, in order to make subsequent builds faster.
 * `-o`: a directory to store the built binaries in.
 * And finally, a list of things that the script should build (_tasks_). In this example we specified two tasks, `passenger` and `nginx`. The passenger task builds the Passenger agent and all Ruby extensions, while the nginx task builds Nginx.

More command line options are available. Run `./build -h` to learn more. You can also run `./build -T` to learn which tasks are available.

When the above example build is finished, the output directory will contain these files:

    support-binaries/nginx-1.10.1
    support-binaries/PassengerAgent

The macOS build script does not build Ruby native extensions because we haven't yet figured out a way to do that in a portable manner.

## Maintenance

### Upgrading Ruby

`passenger_binary_build_automation` builds native extensions for a select number of Ruby versions. If a new version of Ruby has been released then we should re-evaluate which Ruby versions to build extensions for.

The policy is to build native extensions for the latest patchlevel version of all minor Ruby versions that are somewhat widespread in use. For example, as of 1 December 2016, the list is: 1.9.3, 2.0.0, 2.1.9, 2.2.5, 2.3.3. Suppose that Ruby 2.3.4 is released one day later, then we should build against 1.9.3, 2.0.0, 2.1.9, 2.2.5, 2.3.4 (dropping 2.3.3). Suppose a year later, 2.4.0 is released and we believe that 1.9 is no longer in widespread use. Then we can change the list to: 2.0.0, 2.1.9, 2.2.5, 2.3.4, 2.4.0.

The procedure for updating the list of Ruby versions to build against, is as follows:

 1. Change the file `shared/definitions/ruby_versions` accordingly. One Ruby version number per line.
 2. [Update the Docker container and the macOS runtime](#update-container-and-runtime).
 3. [Update the `passenger_binary_build_automation` version lock in Passenger](#update-passenger-lock).
 4. Either release a new Passenger version; or rebuild binaries against the current Passenger version and republish them through the Phusion Jenkins interface.

### Upgrading Nginx

`passenger_binary_build_automation` does not control which Nginx version to build. `passenger_binary_build_automation` builds the Nginx version set the `PREFERRED_NGINX_VERSION` constant in the Passenger source code. So if you want to upgrade Nginx then change that constant in the Passenger source code.

### Upgrading libraries

`passenger_binary_build_automation` statically links a number of libraries into the Passenger agent and Nginx. These libraries need to be updated once in a while, e.g. when important bugs or security vulnerabilities have been fixed. The procedure for doing that is as follows.

 1. Change the relevant library version numbers in `shared/definitions`.
 2. [Update the Docker container and the macOS runtime](#update-container-and-runtime).
 3. [Update the `passenger_binary_build_automation` version lock in Passenger](#update-passenger-lock).
 4. Either release a new Passenger version; or rebuild binaries against the current Passenger version and republish them through the Phusion Jenkins interface.

<a name="update-container-and-runtime"></a>

### Updating the Docker container and macOS runtime

As described in [How it works](HOW-IT-WORKS.md), `passenger_binary_build_automation` works through a Docker container (Linux) or a runtime environment (macOS). Sometimes you may want to update this container or runtime, e.g. because you want to update libraries and depencies. The procedure for updating the Docker container (rebuilding and republishing it), and for rebuilding the macOS runtime, is as follows:

 1. Bump the version number in `shared/definitions/docker_image_version`.
 2. Rebuild the Docker container and the macOS runtime:

    - On Linux: run `./linux/setup-docker-image-32` and `./linux/setup-docker-image-64`.
    - On macOS: remove the runtime directory and rebuild the runtime (see [Building binaries / For macOS / Preparation](#preparation-macos)). During a release the runtime directory is hardcoded to the `~/.passenger_binary_build_automation/` dir.

 4. On Linux: publish the new Docker container to the Docker Hub: run `./linux/publish-docker-images`
 5. Git commit and push.

<a name="update-passenger-lock"></a>

### Updating the `passenger_binary_build_automation` version lock in Passenger

As described in [How it works](HOW-IT-WORKS.md), the Passenger Git repository locks down to a specific version of `passenger_binary_build_automation` using the Git submodule system. Any changes in `passenger_binary_build_automation` does not take effect until you update the lock inside Passenger by bumping the submodule pointer. The procedure for doing that is as follows:

 1. In the Passenger Git repository, update the `packaging/binaries` submodule to the `passenger_binary_build_automation` commit you want.
 2. Git commit and push Passenger.

## Related projects

 * https://github.com/phusion/passenger_apt_automation
 * https://github.com/phusion/passenger_rpm_automation
