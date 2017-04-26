//
//  PerfectNewRelic.swift
//  Perfect-NewRelic-Linux
//
//  Created by Rockford Wei on 2017-04-25.
//  Copyright © 2017 PerfectlySoft. All rights reserved.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2017 - 2018 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

#if os(Linux)
import SwiftGlibc
#else
import Darwin
#endif

/// NewRelic Swift Agent SDK
public class NewRelic {

  public enum Status: Int32 {
  case SHUTDOWN = 0, STARTING = 1, STOPPING = 2, STARTED = 3
  }//end enum

  /// Agent SDK Transaction Return Code
  public enum Exception: Int32, Error {
  case OTHER = -0x10001, DISABLED = -0x20001,
    INVALID_PARAM = -0x30001, INVALID_ID = -0x30002,
    NOT_STARTED = -0x40001, IN_PROGRESS = -0x40002, NOT_NAMED = -0x40003
  }//end enum

  public enum UsageMode {
  case DAEMON, EMBEDDED
  }//end usage mode

  /// Errors
  public enum Panic: Error {
  case
    /// DLL Opening Errors
    DLL(reason: String),
    /// DLL Loading Errors
    SYM(reason: String)
  }//end enum

  public static let AUTOSCOPE = 1
  public static let ROOT_SEGMENT = 0

  internal let libClientDLL = "libnewrelic-collector-client.so"
  internal let libCommonDLL = "libnewrelic-common.so"
  internal let libTransactionDLL = "libnewrelic-transaction.so"

  internal var libClient: UnsafeMutableRawPointer
  internal var libCommon: UnsafeMutableRawPointer
  internal var libTransaction: UnsafeMutableRawPointer

  typealias funcL = @convention(c) () -> Int32
  internal var newrelic_transaction_begin: funcL

  typealias funcLL = @convention(c) (Int32) -> Int32
  internal var newrelic_transaction_set_type_web: funcLL
  internal var newrelic_transaction_set_type_other: funcLL
  internal var newrelic_transaction_end: funcLL

  typealias funcLSL = @convention(c) (Int32, UnsafePointer<Int8>) -> Int32
  internal var newrelic_transaction_set_category: funcLSL
  internal var newrelic_transaction_set_name: funcLSL
  internal var newrelic_transaction_set_request_url: funcLSL

  typealias funcLS4L = @convention(c) (Int32, UnsafePointer<Int8>, UnsafePointer<Int8>, UnsafePointer<Int8>, UnsafePointer<Int8>) -> Int32
  internal var newrelic_transaction_notice_error : funcLS4L

  typealias funcLS2L = @convention(c) (Int32, UnsafePointer<Int8>, UnsafePointer<Int8>) -> Int32
  internal var newrelic_transaction_add_attribute: funcLS2L

  typealias funcLL2L = @convention(c) (Int32, Int32) -> Int32
  internal var newrelic_transaction_set_max_trace_segments: funcLL2L
  internal var newrelic_segment_end: funcLL2L

  typealias funcLLSL = @convention(c) (Int32, Int32, UnsafePointer<Int8>) -> Int32
  internal var newrelic_segment_generic_begin: funcLLSL

  typealias funcL2S4CL = @convention(c) (Int32, Int32, UnsafePointer<Int8>, UnsafePointer<Int8>, UnsafePointer<Int8>, UnsafePointer<Int8>?, funcSS ) -> Int32
  internal var newrelic_segment_datastore_begin: funcL2S4CL

  typealias funcL2S2L = @convention(c) (Int32, Int32, UnsafePointer<Int8>, UnsafePointer<Int8>) -> Int32
  internal var newrelic_segment_external_begin: funcL2S2L

  typealias funcDI = @convention(c) (Double) ->Int32
  internal var newrelic_record_memory_usage: funcDI

  typealias funcDDI = @convention(c) (Double, Double) -> Int32
  internal var newrelic_record_cpu_usage: funcDDI

  typealias funcSDI = @convention(c) (UnsafePointer<Int8>, Double) -> Int32
  internal var newrelic_record_metric: funcSDI

  typealias funcCVIV = @convention(c) ( ( (UnsafeRawPointer) -> UnsafeRawPointer)! ) -> Void
  internal var newrelic_register_message_handler: funcCVIV

  typealias funcIV = @convention(c) (Int32) -> Void
  internal var newrelic_enable_instrumentation: funcIV

  typealias funcSS = @convention(c) (UnsafePointer<Int8>) -> UnsafePointer<Int8>
  internal var newrelic_basic_literal_replacement_obfuscator: funcSS

  typealias funcVPV = @convention(c) (UnsafeRawPointer) -> UnsafeRawPointer
  internal var newrelic_message_handler: funcVPV

  typealias funcVC = @convention(c) ( ((Int32) -> Void)! ) -> Void
  internal var newrelic_register_status_callback: funcVC

  typealias funcS4 = @convention(c) (UnsafePointer<Int8>,UnsafePointer<Int8>,UnsafePointer<Int8>,UnsafePointer<Int8>) -> CInt
  internal var newrelic_init: funcS4

  typealias funcS1 = @convention(c) (UnsafePointer<Int8>) -> CInt
  internal var newrelic_request_shutdown: funcS1

  /// Constructor
  /// - parameters:
  ///   - libraryPath: default is /usr/local/lib, customize if need
  ///   - mode: UsageMode, .DAEMON (default) or .EMBEDDED.
  public init(_ libraryPath: String = "/usr/local/lib", mode: UsageMode = .DAEMON) throws {
    guard
    let lib1 = dlopen("\(libraryPath)/\(libClientDLL)", RTLD_LAZY),
    let lib2 = dlopen("\(libraryPath)/\(libCommonDLL)", RTLD_LAZY),
    let lib3 = dlopen("\(libraryPath)/\(libTransactionDLL)", RTLD_LAZY)
    else {
      let e = String(cString: dlerror())
      throw Panic.DLL(reason: e)
    }
    libClient = lib1
    libCommon = lib2
    libTransaction = lib3

    guard
    let f1 = dlsym(libClient, "newrelic_request_shutdown"),
    let f4 = dlsym(libClient, "newrelic_init"),
    let fv = dlsym(libClient, "newrelic_register_status_callback"),
    let fvv = dlsym(libClient, "newrelic_message_handler"),
    let fss = dlsym(libCommon, "newrelic_basic_literal_replacement_obfuscator"),
    let fiv = dlsym(libTransaction, "newrelic_enable_instrumentation"),
    let fcviv = dlsym(libTransaction, "newrelic_register_message_handler"),
    let fsdi = dlsym(libTransaction, "newrelic_record_metric"),
    let fddi = dlsym(libTransaction, "newrelic_record_cpu_usage"),
    let fdi = dlsym(libTransaction, "newrelic_record_memory_usage"),
    let fl = dlsym(libTransaction, "newrelic_transaction_begin"),
    let fll = dlsym(libTransaction, "newrelic_transaction_set_type_web"),
    let fll2 = dlsym(libTransaction, "newrelic_transaction_set_type_other"),
    let flsl = dlsym(libTransaction, "newrelic_transaction_set_category"),
    let flsl1 = dlsym(libTransaction, "newrelic_transaction_set_name"),
    let flsl2 = dlsym(libTransaction, "newrelic_transaction_set_request_url"),
    let fls4l = dlsym(libTransaction, "newrelic_transaction_notice_error"),
    let fls2l = dlsym(libTransaction, "newrelic_transaction_add_attribute"),
    let fll2l = dlsym(libTransaction, "newrelic_transaction_set_max_trace_segments"),
    let fll2l2 = dlsym(libTransaction, "newrelic_segment_end"),
    let fllsl = dlsym(libTransaction, "newrelic_segment_generic_begin"),
    let fl2s4cl = dlsym(libTransaction, "newrelic_segment_datastore_begin"),
    let fl2s2l = dlsym(libTransaction, "newrelic_segment_external_begin"),
    let fll1 = dlsym(libTransaction, "newrelic_transaction_end")
    else {
      let e = String(cString: dlerror())
      throw Panic.SYM(reason: e)
    }
    newrelic_request_shutdown = unsafeBitCast(f1, to: funcS1.self)
    newrelic_init = unsafeBitCast(f4, to: funcS4.self)
    newrelic_register_status_callback = unsafeBitCast(fv, to: funcVC.self)
    newrelic_message_handler = unsafeBitCast(fvv, to: funcVPV.self)
    newrelic_basic_literal_replacement_obfuscator = unsafeBitCast(fss, to: funcSS.self)
    newrelic_enable_instrumentation = unsafeBitCast(fiv, to: funcIV.self)
    newrelic_register_message_handler = unsafeBitCast(fcviv, to: funcCVIV.self)
    newrelic_record_metric = unsafeBitCast(fsdi, to: funcSDI.self)
    newrelic_record_cpu_usage = unsafeBitCast(fddi, to: funcDDI.self)
    newrelic_record_memory_usage = unsafeBitCast(fdi, to: funcDI.self)
    newrelic_transaction_begin = unsafeBitCast(fl, to: funcL.self)
    newrelic_transaction_set_type_web = unsafeBitCast(fll, to: funcLL.self)
    newrelic_transaction_set_type_other = unsafeBitCast(fll2, to: funcLL.self)
    newrelic_transaction_end = unsafeBitCast(fll1, to: funcLL.self)
    newrelic_transaction_set_category = unsafeBitCast(flsl, to: funcLSL.self)
    newrelic_transaction_notice_error = unsafeBitCast(fls4l, to: funcLS4L.self)
    newrelic_transaction_add_attribute = unsafeBitCast(fls2l, to: funcLS2L.self)
    newrelic_transaction_set_name = unsafeBitCast(flsl1, to: funcLSL.self)
    newrelic_transaction_set_request_url = unsafeBitCast(flsl2, to: funcLSL.self)
    newrelic_transaction_set_max_trace_segments = unsafeBitCast(fll2l, to: funcLL2L.self)
    newrelic_segment_generic_begin = unsafeBitCast(fllsl, to: funcLLSL.self)
    newrelic_segment_datastore_begin = unsafeBitCast(fl2s4cl, to: funcL2S4CL.self)
    newrelic_segment_external_begin = unsafeBitCast(fl2s2l, to: funcL2S2L.self)
    newrelic_segment_end = unsafeBitCast(fll2l2, to: funcLL2L.self)

    if mode == .EMBEDDED {
      newrelic_register_message_handler(newrelic_message_handler)
    }//end if
  }

  /// Record the current amount of memory being used.
  /// - parameters:
  ///   - megabytes: Double, amount of memory currently being used
  /// - throws:
  ///   Panic
  public func recordMemory(megabytes: Double) throws {
    let r = newrelic_record_memory_usage(megabytes)
    guard r == 0 else { throw Exception(rawValue: r) ?? Exception.OTHER }
  }//end func

  /// Record CPU user time in seconds and as a percentage of CPU capacity.
  /// - parameters:
  ///   - timeSeconds: Double, number of seconds CPU spent processing user-level code
  ///   - usagePercent: Double, CPU user time as a percentage of CPU capacity
  /// - throws:
  ///   Panic
  public func recordCPU(timeSeconds: Double, usagePercent: Double) throws {
    let r = newrelic_record_cpu_usage(timeSeconds, usagePercent)
    guard r == 0 else { throw Exception(rawValue: r) ?? Exception.OTHER }
  }//end func

  /// Record a custom metric.
  /// - parameters:
  ///   - name: name of the metric.
  ///   - value: value of the metric.
  /// - throws:
  ///   Panic
  public func recordMetric(name: String, value: Double) throws {
    let r = newrelic_record_metric(name, value)
    guard r == 0 else { throw Exception(rawValue: r) ?? Exception.OTHER }
  }//end func

  /// Disable/enable instrumentation. By default, instrumentation is enabled.
  /// All Transaction library functions used for instrumentation will immediately
  /// return when you disable.
  /// - parameters:
  ///   - enabled: true for enabled and false for disabled
  /// - throws:
  ///   Panic
  public func enableInstrumentation(_ enabled: Bool) {
    newrelic_enable_instrumentation(enabled ? 1 :  0)
  }//end func

  /// Register a function to be called whenever the status of the CollectorClient changes.
  /// - parameters:
  ///   - callback: status callback function to register
  /// - throws:
  ///   Panic
  public func registerStatus(callback: @escaping (Int32) -> Void ) {
    newrelic_register_status_callback(callback)
  }//end func

  /// Start the CollectorClient and the harvester thread that sends application
  /// performance data to New Relic once a minute.
  /// - parameters:
  ///   - license:  New Relic account license key
  ///   - appName:  name of instrumented application
  ///   - language:  name of application programming language
  ///   - version:  application programming language version
  /// - throws:
  ///   Panic
  public func register(license: String, appName: String, language: String = "Swift", version: String = "3.1") throws {
    let r = newrelic_init(license, appName, language, version)
    guard r == 0 else { throw Exception(rawValue: r) ?? Exception.OTHER }
  }//end func

  /// Tell the CollectorClient to shutdown and stop reporting application
  /// performance data to New Relic.
  /// - parameters:
  ///   - reason: for shutdown request
  /// - throws:
  ///   Panic
  public func shutdown(reason: String) throws {
    let r = newrelic_request_shutdown(reason)
    guard r == 0 else { throw Exception(rawValue: r) ?? Exception.OTHER }
  }//end func

  deinit {
    dlclose(libClient)
    dlclose(libCommon)
    dlclose(libTransaction)
  }
}

public class Transaction {

  public let id: Int32
  internal var parent: NewRelic

  public enum SQLOperations: String {
  case SELECT = "select", INSERT = "insert", UPDATE = "update", DELETE = "delete"
  }//end enum

  // NOTE: using the default obfuscator
  // public typealias StringCallBack = (String) -> String
  // public static var SQLObfuscator: StringCallBack = { $0 }

  /// Constructor of Transaction Class
  /// - parameters:
  ///   - instance: NewRelic instance
  ///   - webType: true for WebTransaction and false for other. default is true.
  ///   - category: name of the transaction category, default is 'Uri'
  ///   - name: transaction name
  ///   - url: request url for a web transaction
  ///   - attributes: transaction attributes, pair of "name: value"
  ///   - maxTraceSegments: Set the maximum number of trace segments allowed in a transaction trace. By default, the maximum is set to 2000, which means the first 2000 segments in a transaction will create trace segments if the transaction exceeds the trace threshold (4 x apdex_t).
  /// - throws:
  ///   Panic
  public init(_ instance: NewRelic,
    webType: Bool? = nil,
    category: String? = nil,
    name: String? = nil,
    url: String? = nil,
    attributes: [String: String],
    maxTraceSegments: Int? = nil
  ) throws {
    parent = instance
    id = parent.newrelic_transaction_begin()
    guard id > 0 else { throw NewRelic.Exception(rawValue: id) ?? NewRelic.Exception.OTHER }
    var r:Int32 = 0
    if let web = webType {
      r = web ?
        parent.newrelic_transaction_set_type_web( id ) :
        parent.newrelic_transaction_set_type_other ( id )
        guard r == 0 else { throw NewRelic.Exception(rawValue: r) ?? NewRelic.Exception.OTHER }
    }//end if
    if let cat = category {
      r = parent.newrelic_transaction_set_category(id, cat)
      guard r == 0 else { throw NewRelic.Exception(rawValue: r) ?? NewRelic.Exception.OTHER }
    }//end if
    if let nm = name {
      r = parent.newrelic_transaction_set_name(id, nm)
      guard r == 0 else { throw NewRelic.Exception(rawValue: r) ?? NewRelic.Exception.OTHER }
    }
    if let uri = url {
      r = parent.newrelic_transaction_set_request_url(id, uri)
      guard r == 0 else { throw NewRelic.Exception(rawValue: r) ?? NewRelic.Exception.OTHER }
    }
    for (key, value) in attributes {
      r = parent.newrelic_transaction_add_attribute(id, key, value)
      guard r == 0 else { throw NewRelic.Exception(rawValue: r) ?? NewRelic.Exception.OTHER }
    }//next
    if let max = maxTraceSegments {
      r = parent.newrelic_transaction_set_max_trace_segments(id, Int32(max))
      guard r == 0 else { throw NewRelic.Exception(rawValue: r) ?? NewRelic.Exception.OTHER }
    }//end if
  }//end init

  /// Identify an error that occurred during the transaction. The first identified
  /// error is sent with each transaction.
  /// - parameters:
  ///   - PanicType: type of Panic that occurred
  ///   - errorMessage: error message
  ///   - stackTrace: stacktrace when error occurred
  ///   - stackFrameDelimiter: delimiter to split stack trace into frames
  /// - throws:
  ///   Panic
  public func setErrorNotice(exceptionType: String, errorMessage: String, stackTrace: String, stackFrameDelimiter: String) throws {
    let r = parent.newrelic_transaction_notice_error(id, exceptionType, errorMessage, stackTrace, stackFrameDelimiter)
    guard r == 0 else { throw NewRelic.Exception(rawValue: r) ?? NewRelic.Exception.OTHER }
  }

  /// Identify the beginning of a segment that performs a generic operation. This
  /// type of segment does not create metrics, but can show up in a transaction
  /// trace if a transaction is slow enough.
  /// - parameters:
  ///   - parentSegmentId: id of parent segment, root segment by default.
  ///   - name: name to represent segment
  /// - throws:
  ///   Panic
  public func segBeginGeneric(parentSegmentId: Int = NewRelic.ROOT_SEGMENT, name: String) throws -> Int {
    let r = parent.newrelic_segment_generic_begin(id, Int32(parentSegmentId), name)
    guard r == 0 else { throw NewRelic.Exception(rawValue: r) ?? NewRelic.Exception.OTHER }
    return Int(r)
  }

  ///
  /// Identify the beginning of a segment that performs a database operation.
  ///
  ///
  /// SQL Obfuscation
  /// ===============
  /// The supplied SQL string will go through our basic literal replacement
  /// obfuscator that strips the SQL string literals
  /// (values between single or double quotes) and numeric
  /// sequences, replacing them with the ? character. For example:
  ///
  /// This SQL:
  ///		SELECT * FROM table WHERE ssn=‘000-00-0000’
  ///
  /// obfuscates to:
  ///		SELECT * FROM table WHERE ssn=?
  ///
  /// Because our default obfuscator just replaces literals, there could be
  /// cases that it does not handle well. For instance, it will not strip out
  /// comments from your SQL string, it will not handle certain database-specific
  /// language features, and it could fail for other complex cases.
  ///
  /// SQL Trace Rollup
  /// ================
  /// The agent aggregates similar SQL statements together using the supplied
  /// sqlTraceRollupName automatically.
  /// - parameters:
  ///   - parentSegmentId: id of parent segment, root segment by default.
  ///   - table: name of the database table
  ///   - operation: name of the sql operation
  ///   - sql: the sql string
  /// - throws:
  ///   Panic
  public func segBeginDataStore(parentSegmentId: Int = NewRelic.ROOT_SEGMENT, table: String, operation: SQLOperations, sql: String) throws -> Int {
    let r = parent.newrelic_segment_datastore_begin(id, Int32(parentSegmentId), table, operation.rawValue, sql, nil, parent.newrelic_basic_literal_replacement_obfuscator)
    guard r == 0 else { throw NewRelic.Exception(rawValue: r) ?? NewRelic.Exception.OTHER }
    return Int(r)
  }

  /// Identify the beginning of a segment that performs an external service.
  /// - parameters:
  ///   - parentSegmentId: id of parent segment, root segment by default.
  ///   - host: name of the host of the external call
  ///   - name:  name of the external transaction
  /// - throws:
  ///   Panic
  public func segBeginExternal(parentSegmentId: Int = NewRelic.ROOT_SEGMENT, host: String, name: String) throws -> Int {
    let r = parent.newrelic_segment_external_begin(id, Int32(parentSegmentId), host, name)
    guard r == 0 else { throw NewRelic.Exception(rawValue: r) ?? NewRelic.Exception.OTHER }
    return Int(r)
  }

  /// Identify the end of a segment
  /// - parameters:
  ///   - segId: id of the segment to end
  /// - throws:
  ///   Panic
  public func segEnd(_ segId: Int) throws {
    let r = parent.newrelic_segment_end(id, Int32(segId))
    guard r == 0 else { throw NewRelic.Exception(rawValue: r) ?? NewRelic.Exception.OTHER }
  }

  deinit {
    _ = parent.newrelic_transaction_end(id)
  }
}
