# profile_slingshot

This profile is to configure a Slingshot Fabric manager and manage any changes
required on Slingshot clients.  

## Table of Contents

1. [Description](#description)

## Description

This profile is to configure a Slingshot Fabric manager (2.0.1) and manage any changes
required on Slingshot clients.

The slingshot::fm module configures and the Slingshot fabric manager.

* It configures nginx dnf modules to the correct version
* Installs the fabric manager and various components
* Places certificates
* Opens ports
* Starts Nginx

## History of breaking changes

v0.3.0 - fabric_mgr_ips changes to fabric_mgr_hosts (data for host resources).
