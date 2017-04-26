# Perfect New Relic Library for Linux

<p align="center">
    <a href="http://perfect.org/get-involved.html" target="_blank">
        <img src="http://perfect.org/assets/github/perfect_github_2_0_0.jpg" alt="Get Involed with Perfect!" width="854" />
    </a>
</p>

<p align="center">
    <a href="https://github.com/PerfectlySoft/Perfect" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_1_Star.jpg" alt="Star Perfect On Github" />
    </a>  
    <a href="http://stackoverflow.com/questions/tagged/perfect" target="_blank">
        <img src="http://www.perfect.org/github/perfect_gh_button_2_SO.jpg" alt="Stack Overflow" />
    </a>  
    <a href="https://twitter.com/perfectlysoft" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_3_twit.jpg" alt="Follow Perfect on Twitter" />
    </a>  
    <a href="http://perfect.ly" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_4_slack.jpg" alt="Join the Perfect Slack" />
    </a>
</p>

<p align="center">
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat" alt="Swift 3.0">
    </a>
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Platforms-OS%20X%20%7C%20Linux%20-lightgray.svg?style=flat" alt="Platforms OS X | Linux">
    </a>
    <a href="http://perfect.org/licensing.html" target="_blank">
        <img src="https://img.shields.io/badge/License-Apache-lightgrey.svg?style=flat" alt="License Apache">
    </a>
    <a href="http://twitter.com/PerfectlySoft" target="_blank">
        <img src="https://img.shields.io/badge/Twitter-@PerfectlySoft-blue.svg?style=flat" alt="PerfectlySoft Twitter">
    </a>
    <a href="http://perfect.ly" target="_blank">
        <img src="http://perfect.ly/badge.svg" alt="Slack Status">
    </a>
</p>

This project provides a system level module for New Relic Agent SDK.

This package builds with Swift Package Manager and is part of the [Perfect](https://github.com/PerfectlySoft/Perfect) project and should not be used as an independent module.

## Release Note

This project is only compatible with Ubuntu 16.04 and Swift 3.1 Tool Chain.

## Quick Start

Please use PA to import this project, otherwise an install script is available for Ubuntu 16.04:

```
$ git clone https://github.com/PerfectlySoft/Perfect-NewRelic-linux.git
$ cd Perfect-libNewRelic-linux
$ sudo ./install.sh
```

Configure Package.swift:

``` swift
.Package(url: "https://github.com/PerfectlySoft/Perfect-NewRelic-linux.git", majorVersion: 1)
```

Import library into your code:

``` swift
import PerfectNewRelic
```

Aside of Swift - C conversion, document can be found on [New Relic Agent SDK](https://docs.newrelic.com/docs/agents/agent-sdk/using-agent-sdk/using-agent-sdk)

## Configuration

Post Installation & Configuration can be found on [New Relic - Configuring the Agent SDK](https://docs.newrelic.com/docs/agents/agent-sdk/installation-configuration/configuring-agent-sdk), equivalent Swift codes listed below:

### Running in embedded-mode

- To setup NewRelic instance in embedded-mode properly, program must explicitly declare the usage mode as `.EMBEDDED`, which means to send data to New Relic when transactions are completed, equivalent to `newrelic_register_message_handler(newrelic_message_handler);` defined in the original documentation:

``` swift
let nr = try NewRelic(mode: .EMBEDDED)
```

- Create a function to receive status change notifications:

``` swift
nr.registerStatus { code in
	guard let status = NewRelic.Status(rawValue: code) else {
		// something wrong here
	}//end guard
	switch status {
		case .STARTING: // it is starting
		case .STARTED: // it is started
		case .STOPPING: // it is stopping
		default: // shutdown already
   }//end case
}//end callback
```

- Once created the NewRelic instance, please register the license key and application name like this:

``` swift
try nr.register(license: "my-lic", appName: "my-app", language: "Swift", version: "3.1")
```

language and version can be skipped if you are using Swift 3.1:

``` swift
try nr.register(license: "my-lic", appName: "my-app"
```

- Optional: Shut down the connection to New Relic:

``` swift 
try nr.shutdown(reason: "no reason")
```

## Limiting or disabling Agent SDK settings

According to [New Relic Limiting or disabling Agent SDK Settings](https://docs.newrelic.com/docs/agents/agent-sdk/installation-configuration/limiting-or-disabling-agent-sdk-settings), the following settings are available in Perfect NewRelic:

If you want to ... | Use this setting ...
-------------------|---------------------
Disable data collection during a transaction|`nr.enableInstrumentation(false)`
 | **Note**: If you are running a web server that spawns off new processes per transaction, you may need to call this for every transaction.
Shut down the agent in embedded-mode|`try nr.shutdown(reason: "some reasons")`
Shut down the agent in daemon mode | Stop the `newrelic-collector-client-daemon` process.
Configure the number of trace segments collected in a transaction trace|`let t = try Transaction(nr, maxTraceSegments: 50)` // // Only collect up to 50 trace segments
 | **Note**: If you are running a web server that spawns off new processes per transaction, you may need to call this for every transaction.
 
## Issues

We are transitioning to using JIRA for all bugs and support related issues, therefore the GitHub issues has been disabled.

If you find a mistake, bug, or any other helpful suggestion you'd like to make on the docs please head over to [http://jira.perfect.org:8080/servicedesk/customer/portal/1](http://jira.perfect.org:8080/servicedesk/customer/portal/1) and raise it.

A comprehensive list of open issues can be found at [http://jira.perfect.org:8080/projects/ISS/issues](http://jira.perfect.org:8080/projects/ISS/issues)

## Further Information
For more information on the Perfect project, please visit [perfect.org](http://perfect.org).
