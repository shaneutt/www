---
title: "The Git Package Manager"
date: "2020-07-26T06:55:00-04:00"
---

The Git Package Manager
===

One of the most common things I do manually on my workstation is either _install_ tools from Github by going to the releases, downloading the latest release and installing it _or_ doing the same thing to update to a newer version of that tool.

Recently I decided that I should take a shot at automating this bit of monotony in my life, because if nothing else automating the things that are automatable is something engineers do best.

As such I present https://git-pkg.dev and the Github Org https://github.com/git-pkg, the purpose of which are to develop and provide tooling for automating the problem of managing "packages" that are based on Github releases.

In the long term, I would also like to cover any other kind of Git repository by (hopefully) creating a standard way to express how to install your releases from the release artifacts.

The https://github.com/git-pkg/cli repo is where I'm starting a CLI for doing this and will continue to blog about things over the months as they come up. If you're interested feel free to catch me on the `git-pkg` [Gitter page](https://gitter.im/git-pkg/community).

For now I'm gonna be heads down working on the prototype in my free time. Happy coding!
