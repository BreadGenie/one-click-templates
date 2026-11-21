---
title: Runway Cache
description: Install the regional cache on a privileged VM for Runway.
---

# Runway Cache

This app is for regional operators. Create one privileged tenant-0 VM per
region through Atlas. The normal Apps launch creates an unprivileged Team VM
and cannot run this service.

## Build the image

Set the HTTPS release URL and SHA-256 in
`runway-cache/src/etc/one-click/runway-release.env` before Cargo builds the
template. Use an archive created by Runway's
`scripts/build-cache-service-release.sh`. For a local build, serve that
archive over HTTPS using a CA trusted by the builder. The build installs the
Runway binary and its two units. It creates no keys or credentials.

## Start the cache

Follow the [regional cache operator runbook](https://github.com/BreadGenie/runway-controller/blob/main/docs/regional-cache-operator.md).
Pass the Runway HTTPS origin, region and one-use token in
`/etc/one-click/inputs.env`. The boot script enrols the VM and writes
`/var/lib/one-click/ready` when the units have started. Check the Runway Region
record for its mesh endpoint. Cache objects live in each Team's Cargo bucket.
