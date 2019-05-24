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
   - [Publishing binaries](#publishing-binaries)
 * [Maintainers' FAQ](#maintainers-faq)
   - [Where is the runtime directory? (macOS)](#where-is-the-runtime-directory-macos)
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

    ruby-extensions/ruby-2.1.10-x86-linux/passenger_native_support.so
    ruby-extensions/ruby-2.2.10-x86-linux/passenger_native_support.so
    ruby-extensions/ruby-2.3.8-x86-linux/passenger_native_support.so
    ruby-extensions/ruby-2.4.5-x86-linux/passenger_native_support.so
    ruby-extensions/ruby-2.5.5-x86-linux/passenger_native_support.so
    ruby-extensions/ruby-2.6.2-x86-linux/passenger_native_support.so
    support-binaries/PassengerAgent
    support-binaries/nginx-1.15.8

### For macOS

<a name="preparation-macos"></a>

#### Preparation

Before you can build binaries for macOS, you must ensure that these prerequities are (manually) installed:

 * Xcode command-line developer tools.
 * GPG.
 * [RVM](https://rvm.io).
   - Not using RVM, and instead using rbenv or something? For the sake of simplicity, `passenger_binary_build_automation` only supports RVM. We recommend that you create a new account on your Mac that uses RVM only, and to develop `passenger_binary_build_automation` on that account.
 * All Ruby versions specified in the `shared/definitions/ruby_versions` file.

Once these prerequisites are installed, you must build a **runtime** using the `macos/setup-runtime` script. A runtime is a directory containing further tools and libraries that `passenger_binary_build_automation` needs for building binaries (see also [How it works](HOW-IT-WORKS.md) section "The build environment"). The runtime needs to be setup the first time you use `passenger_binary_build_automation`, every time the list of libraries that we link into Passenger changes, and every time Nginx changes.

Here is an example invocation:

    $ cd macos
    $ ./setup-runtime -c cache -o runtime-output

The `setup-runtime` script expects at least the following arguments:

 * `-c`: a directory which the script can use for caching data, in order to make subsequent runtime builds faster.
 * `-o`: a directory to store the runtime in. When testing things locally, this can be any arbitrary directory of your chosing but may not contain spaces (but see also [Where is the runtime directory? (macOS)](#where-is-the-runtime-directory-macos) to find out where it is on the CI server).

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

 * `-r`: path to the directory in which the runtime is stored. This must be the same path that you passed to `macos/setup-runtime` through `-o`.
 * `-p`: path to the Passenger source code that you want to build.
 * `-c`: a directory which the script can use for caching data, in order to make subsequent builds faster.
 * `-o`: a directory to store the built binaries in.
 * And finally, a list of things that the script should build (_tasks_). In this example we specified two tasks, `passenger` and `nginx`. The passenger task builds the Passenger agent and all Ruby extensions, while the nginx task builds Nginx.

More command line options are available. Run `./build -h` to learn more. You can also run `./build -T` to learn which tasks are available.

When the above example build is finished, the output directory will contain these files:

    support-binaries/nginx-1.15.8
    support-binaries/PassengerAgent

The macOS build script does not build Ruby native extensions because we haven't yet figured out a way to do that in a portable manner.

## Maintenance

### Upgrading Ruby

`passenger_binary_build_automation` builds native extensions for a select number of Ruby versions. If a new version of Ruby has been released then we should re-evaluate which Ruby versions to build extensions for.

The policy is to build native extensions for the latest patchlevel version of all minor Ruby versions that are somewhat widespread in use. For example, as of 15 Mar 2019, the list is: 2.1.10, 2.2.10, 2.3.8, 2.4.5, 2.5.5, 2.6.2. Suppose that Ruby 2.5.6 is released one day later (just look what happened with 2.5.5), then we should build against 2.1.10, 2.2.10, 2.3.8, 2.4.5, 2.5.6 (dropping 2.5.5), and 2.6.2. Suppose a year later, 2.7.0 is released and we believe that 2.1 is no longer in widespread use. Then we can change the list to: 2.2.10, 2.3.8, 2.4.5, 2.5.5, 2.6.2, 2.7.0.

The procedure for updating the list of Ruby versions to build against, is as follows:

 1. Change the file `shared/definitions/ruby_versions` accordingly. One Ruby version number per line.
 2. [Update the Docker container and the macOS runtime](#update-container-and-runtime).
 3. Build the binaries locally to test whether everything works as expected.
 4. [Update the `passenger_binary_build_automation` version lock in Passenger to the current `passenger_binary_build_automation` commit](#update-passenger-lock).
 5. [Publish binaries](#publishing-binaries).

### Upgrading Nginx

`passenger_binary_build_automation` does not control which Nginx version to build. `passenger_binary_build_automation` builds the Nginx version set the `PREFERRED_NGINX_VERSION` constant in the Passenger source code. So if you want to upgrade Nginx then change that constant in the Passenger source code.

### Upgrading libraries

`passenger_binary_build_automation` statically links a number of libraries into the Passenger agent and Nginx. These libraries need to be updated once in a while, e.g. when important bugs or security vulnerabilities have been fixed. The procedure for doing that is as follows.

 1. Change the relevant library version numbers in `shared/definitions` (there's a handy script at `./update.sh`).
 2. [Update the Docker container and the macOS runtime](#update-container-and-runtime).
 3. Build the binaries locally to test whether everything works as expected.
 4. [Update the `passenger_binary_build_automation` version lock in Passenger to the current `passenger_binary_build_automation` commit](#update-passenger-lock).
 5. [Publish binaries](#publishing-binaries).

<a name="update-container-and-runtime"></a>

### Updating the Docker container and macOS runtime

As described in [How it works](HOW-IT-WORKS.md), `passenger_binary_build_automation` works through a Docker container (Linux) or a runtime environment (macOS). Sometimes you may want to update this container or runtime, e.g. because you want to update libraries and depencies. The procedure for updating the Docker container (rebuilding and republishing it), and for rebuilding the macOS runtime, is as follows:

 1. Bump the version number in `shared/definitions/docker_image_version`.
 2. If you changed anything in the macOS runtime **besides** bumping Ruby version numbers (e.g. you updated OpenSSL or something), then also bump the version number in `shared/definitions/macos_runtime_version`.
 3. Rebuild the Docker container. On a Linux machine:

     - Run `./linux/setup-docker-image-32`
     - Run `./linux/setup-docker-image-64`
     - Publish the new Docker container to the Docker Hub: run `./linux/publish-docker-images`

 4. If you changed the ruby versions at all, then you need to update the [versions in the ansible playbook for the passenger ci cluster](https://gitlab.phusion.nl/provisioning/ansible_playbooks/blob/master/playbooks/passenger-ci-cluster/vars/macos-slave.yml), and then deploy to production: `./run production --ask-vault-pass -l macos-slave-vm`.
 5. If you bumped `shared/definitions/macos_runtime_version`, then (locally) rebuild the runtime (see [Building binaries / For macOS / Preparation](#preparation-macos)) to see whether it works.


    Note: there is no need to manually rebuild the runtime (or to manually remove the runtime) on the Passenger CI server. The CI job will automatically build a new runtime whenever it detects that `macos_runtime_version` has changed. This is because the runtime directory on the CI server contains the runtime version in its path. See also [Where is the runtime directory? (macOS)](#where-is-the-runtime-directory-macos).

 6. Git commit and push.

<a name="update-passenger-lock"></a>

### Updating the `passenger_binary_build_automation` version lock in Passenger

As described in [How it works](HOW-IT-WORKS.md), the Passenger Git repository locks down to a specific version of `passenger_binary_build_automation` using the Git submodule system. Any changes in `passenger_binary_build_automation` does not take effect until you update the lock inside Passenger by bumping the submodule pointer. The procedure for doing that is as follows:

 1. In the Passenger Git repository, switch to the branch that is eligible for the next release (`stable-5.1` at the time of writing).
 2. On that branch, update the `packaging/binaries` submodule to the `passenger_binary_build_automation` commit you want.
 3. Git commit and push Passenger.
 4. In the Passenger Enterprise Git repository, switch to the branch that is eligible for the next release (`stable-5.1` at the time of writing).
 5. Merge the open source Passenger branch that you committed to, into the current Passenger Enterprise branch (e.g. `git merge oss/stable-5.1`), so that Passenger Enterprise is also locked down against this `passenger_binary_build_automation` commit.
 6. Git commit and push Passenger Enterprise.

<a name="publishing-binaries"></a>

### Publishing binaries

If you have made a modification to `passenger_binary_build_automation`, then building and publishing new binaries involves running the Passenger Release Process CI job. There are two variants of this process that you can choose from:

 1. Release a new Passenger version. This is the process variant that you will usually be interested in. Or:
 2. Update the binaries for an existing Passenger version. One reason for choosing this process variant is: you've found out that the binaries you built for an existing Passenger version contains vulnerabilities (e.g. statically linked to an old OpenSSL) and you just want to update the binaries without releasing a new Passenger version.

     - Note that some users may already have downloaded old binaries. Releasing a new version automatically signals to those users that they should upgrade, but if you choose this latter process variant then there is no such signal to those users. You will need to think about how to communicate to those users to update their binaries.

#### Releasing a new Passenger version

 1. Commit and push any changes in `passenger_binary_build_automation`.
 2. Go the Passenger Git repository. Switch to the branch that is eligible for the next release. On that branch, [update the `passenger_binary_build_automation` version lock in Passenger to the current `passenger_binary_build_automation` commit](#update-passenger-lock) if you haven't already. Do the same thing for Passenger Enterprise.
 3. Release a new Passenger version per the usual Passenger release procedure.

#### Update the binaries for an existing Passenger version

First update open source:

 1. Commit and push any changes in `passenger_binary_build_automation`.
 2. Go to the Passenger Git repository. Checkout the Git tag associated with the Passenger version for which you want to update binaries. For example: `git checkout release-5.1.11`
 3. Create a branch and give it an appropriate name. For example: `git branch hotfix-5.1.11-oss-binaries-update`
 4. On this branch, update the `packaging/binaries` submodule to the current `passenger_binary_build_automation` commit.
 5. Git commit and push this branch.

Then update Enterprise:

 6. Go to the Passenger Enterprise Git repository. Checkout the Git tag associated with the Passenger Enterprise version for which you want to update binaries. For example: `git checkout enterprise-5.1.11`
 7. Create a branch and give it an appropriate name. For example: `git branch hotfix-5.1.11-enterprise-binaries-update`
 8. Merge with the open source branch you created in step 3. For example: `git merge oss/hotfix-5.1.11-oss-binaries-update`
 9. Git commit and push this branch.

Finally, update and run the release process:

 10. Go to the passenger-release Git repository. Checkout the Git tag associated with the Passenger version for which you want to update binaries. For example: `git checkout release-5.1.11`
 11. Create a branch and give it an appropriate name. For example: `git branch hotfix-5.1.11-binaries-update`
 12. On this branch, update the `components/passenger` and `components/passenger-enterprise` submodules to the branches that you published in steps 5 and 9, respectively.
 13. Git commit and push.
 14. On the Phusion Jenkins interface, go to the Passenger Release Process job and click on Configure.
 15. Scroll down. Update the `Pipeline -> SCM: Git -> Branches to build` field to the passenger-release branch you just published. For example: `*/hotfix-5.1.11-binaries-update`.
 16. Run the Passenger Release Process job. Settings:

      - Testing: checked.
      - CleanSlate: unchecked if your last run was against the the same Passenger version; checked otherwise or if you are unsure.
      - ForceRepublish: checked.

 17. If step 16 succeeded, rerun it with Testing unchecked.
 18. Go to the Passenger Release Process job and click on Configure. Revert the `Pipeline -> SCM: Git -> Branches to build` field to the original value, which should be `*/master`.

<a name="maintainers-faq"></a>

## Maintainers' FAQ

<a name="where-is-the-runtime-directory-macos"></a>

### Where is the runtime directory? (macOS)

`passenger_binary_build_automation` supports placing the runtime at any arbitrary location on the filesystem (scripts such as `macos/setup-runtime` and `macos/build` requires a parameter that specifies where the runtime is). Thus, the location of the runtime is not dictated by `passenger_binary_build_automation`, but by the person or the system using `passenger_binary_build_automation`.

During local development, the path is entirely chosen by the developer.

During the Passenger release process CI job, the runtime is located on the macOS CI server at `/data/jenkins/cache/Passenger-Release-Process/generic-macos-binaries/{passenger,passenger-enterprise}/runtime-$MACOS_RUNTIME_VERSION`. This location is passed to the `passenger_binary_build_automation` scripts in the `passenger-release` project, as follows:

 * `stages/build-artifacts/build-generic-macos-binaries/jenkinsfile_helper.groovy` sets a `CACHE_DIR` environment variable.
 * `jenkinsfile_helper.groovy` calls `./stages/build-artifacts/build-generic-macos-binaries/{initialize.sh,build.sh}`
 * These two scripts call `passenger_binary_build_automation`'s `macos/{setup-runtime,build}`, respectively, telling them through parameters that the runtime can be found in `$CACHE_DIR/runtime`.

## Related projects

 * https://github.com/phusion/passenger_apt_automation
 * https://github.com/phusion/passenger_rpm_automation
