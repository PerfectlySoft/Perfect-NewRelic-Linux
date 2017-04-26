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

### Running in Embedded-mode

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
try nr.register(license: "my-lic", appName: "my-app")
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
=>| **Note**: If you are running a web server that spawns off new processes per transaction, you may need to call this for every transaction.
Shut down the agent in embedded-mode|`try nr.shutdown(reason: "some reasons")`
Shut down the agent in daemon mode | Stop the `newrelic-collector-client-daemon` process.
Configure the number of trace segments collected in a transaction trace|`let t = try Transaction(nr, maxTraceSegments: 50)` // // Only collect up to 50 trace segments
=>| **Note**: If you are running a web server that spawns off new processes per transaction, you may need to call this for every transaction.

## Using the Agent SDK - Perfect NewRelic

Base on [New Relic's Document of Using the Agent SDK](https://docs.newrelic.com/docs/agents/agent-sdk/using-agent-sdk/using-agent-sdk), Perfect NewRelic library provides identically the same functions of New Relic Agent SDK in Swift:

### Recording and viewing custom metrics

Custom metrics give you a way to record arbitrary metrics about your application. You can also instrument your code, which will report performance metrics automatically whenever that code is executed. With a custom metric, you provide the value to be recorded for a specified metric name; for example:

``` swift
try nr.recordMetric(name: "ActiveUsers", value: 25)
```
 
## API Quick Help

### NewRelic Class Methods

Function| `init()`
----|------
Demo|`let nr = try NewRelic(mode: .EMBEDDED)`
Description| NewRelic Class Constructor
Parameters|- libraryPath: default is `/usr/local/lib`, customize if need <br> - mode: UsageMode, `.DAEMON` (by default) or `.EMBEDDED.` 
Returns| Instance of NewRelic Class

Function |`register()`
----|------
Demo|`try nr.register(license: "my-lic", appName: "my-app")`
Description| Start the CollectorClient and the harvester thread that sends application performance data to New Relic once a minute.
Parameters|- license:  New Relic account license key <br> - appName:  name of instrumented application <br> - language:  name of application programming language, default is "Swift" <br> - version:  application programming language version, "3.1" by default

Function |`registerStatus()`
---|---
Demo|See [Running in Embedded-mode](### Running in Embedded-mode)
Description|Register a function to be called whenever the status of the CollectorClient changes.
Parameters|  - callback: status callback function to register

Function | `enableInstrumentation()`
---|---
Description| See [Limiting or disabling Agent SDK settings](## Limiting or disabling Agent SDK settings)

Function | `recordMetric()`
---|---
Demo|`try nr.recordMetric(name: "ActiveUsers", value: 25)`
Description|Record a custom metric.
Parameters| - name: name of the metric. <br> - value: value of the metric.

Function | `recordCPU()`
---|---
Demo|`try nr.recordCPU(timeSeconds: 5.0, usagePercent: 1.2)`
Description|Record CPU user time in seconds and as a percentage of CPU capacity.
Parameters| - timeSeconds: Double, number of seconds CPU spent processing user-level code <br> - usagePercent: Double, CPU user time as a percentage of CPU capacity

Function | `recordMemory()`
---|---
Demo|`try nr.recordMemory(megabytes: 32)`
Description|Record the current amount of memory being used.
Parameters| - megabytes: Double, amount of memory currently being used

Function | `shutdown()`
---|---
Demo|try nr.shutdown(reason: "no reason")
Description| Tell the CollectorClient to shutdown and stop reporting application performance data to New Relic.
Parameters|- reason: String, reasons for shutdown request

### Transaction

Transaction in Perfect NewRelic has been defined as a class, with construction as below:

``` swift
public init(_ instance: NewRelic,
    webType: Bool? = nil,
    category: String? = nil,
    name: String? = nil,
    url: String? = nil,
    attributes: [String: String],
    maxTraceSegments: Int? = nil
  ) throws
```

#### Constructor parameters:

- instance: NewRelic instance, **required**.
- webType: **optional**. true for WebTransaction and false for other. default is true.
- category: **optional**. name of the transaction category, default is 'Uri'
- name: **optional**. transaction name
- url: **optional**. request url for a web transaction
- attributes: **optional**. transaction attributes, pair of "name: value"
- maxTraceSegments: **optional**. Set the maximum number of trace segments allowed in a transaction trace. By default, the maximum is set to 2000, which means the first 2000 segments in a transaction will create trace segments if the transaction exceeds the trace threshold (4 x apdex_t).

#### Demo of Transaction Class Initialization:

``` swift
let nr = NewRelic()
let t = try Transaction(nr, webType: false,
	category: "my-class-1", name: "my-transaction-name",
	url: "http://localhost",
	attributes: ["tom": "jerry", "pros":"cons", "muddy":"puddels"],
	maxTraceSegments: 2000)
```

#### Error Notice

Perfect NewRelic provides `setErrorNotice()` function for transactions:

``` swift
try t.setErrorNotice(
	exceptionType: "my-panic-type-1", 
	errorMessage: "my-notice", 
	stackTrace: "my-stack", 
	stackFrameDelimiter: "<frame>")
```

Parameters of `setErrorNotice()`:

- exceptionType: type of exception that occurred
- errorMessage: error message
- stackTrace: stacktrace when error occurred
- stackFrameDelimiter:  delimiter to split stack trace into frames

#### Segments

Segments in a transaction can be either Generic, DataStore or External, see demo below:

``` swift
// assume that t is a transaction
let root = try t.segBeginGeneric(name: "my-segment")
	// note: using default SQL Obfuscation method and default SQL trace rollup
	let sub = try t.segBeginDataStore(parentSegmentId: root, table: "my-table", operation: .INSERT, sql: "INSERT INTO table(field) value('000-000-0000')")
		let s2 = try t.segBeginExternal(parentSegmentId: sub, host: "perfect.org", name: "my-seg")
		try t.segEnd(s2)
	try t.segEnd(sub)
try t.segEnd(root)
```


Parameters:

- parentSegmentId: id of parent segment, root segment by default, i.e., ` NewRelic.ROOT_SEGMENT`.
- name: name to represent segment

## Issues

We are transitioning to using JIRA for all bugs and support related issues, therefore the GitHub issues has been disabled.

If you find a mistake, bug, or any other helpful suggestion you'd like to make on the docs please head over to [http://jira.perfect.org:8080/servicedesk/customer/portal/1](http://jira.perfect.org:8080/servicedesk/customer/portal/1) and raise it.

A comprehensive list of open issues can be found at [http://jira.perfect.org:8080/projects/ISS/issues](http://jira.perfect.org:8080/projects/ISS/issues)

## Further Information
For more information on the Perfect project, please visit [perfect.org](http://perfect.org).
