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

import SwiftGlibc

/// NewRelic Swift Agent SDK
public class NewRelic {

  public enum Status: Int32 {
  case SHUTDOWN = 0, STARTING = 1, STOPPING = 2, STARTED = 3
  }//end enum

  /// Agent SDK Transaction Return Code
  public enum RCODE: Int32 {
  case OK = 0, OTHER = -0x10001, DISABLED = -0x20001,
    INVALID_PARAM = -0x30001, INVALID_ID = -0x30002,
    NOT_STARTED = -0x40001, IN_PROGRESS = -0x40002, NOT_NAMED = -0x40003
  }//end enum

  /// Errors
  public enum Exception: Error {
  case
    /// DLL Opening Errors
    DLL(reason: String),
    /// DLL Loading Errors
    SYM(reason: String),
    /// DLL Calling Errors
    FUN(code: RCODE)
  }//end enum

  public let AUTOSCOPE = 1
  public let ROOT_SEGMENT = 0
  public let SELECT = "select"
  public let INSERT = "insert"
  public let UPDATE = "update"
  public let DELETE = "delete"

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

  typealias funcL2S4CL = @convention(c) (Int32, Int32, UnsafePointer<Int8>, UnsafePointer<Int8>, UnsafePointer<Int8>, UnsafePointer<Int8>, funcSS ) -> Int32
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

  internal func asError(_ code: Int32) -> Exception {
    return Exception.FUN(code: NewRelic.RCODE(rawValue: code) ?? NewRelic.RCODE.OTHER)
  }

  /// Constructor
  /// - parameters:
  ///   - libraryPath: default is /usr/local/lib, customize if need
  public init(_ libraryPath: String = "/usr/local/lib") throws {
    guard
    let lib1 = dlopen("\(libraryPath)/\(libClientDLL)", RTLD_LAZY),
    let lib2 = dlopen("\(libraryPath)/\(libCommonDLL)", RTLD_LAZY),
    let lib3 = dlopen("\(libraryPath)/\(libTransactionDLL)", RTLD_LAZY)
    else {
      let e = String(cString: dlerror())
      throw Exception.DLL(reason: e)
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
      throw Exception.SYM(reason: e)
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
  }

  /// Record the current amount of memory being used.
  /// - parameters:
  ///   - megabytes: Double, amount of memory currently being used
  /// - throws:
  ///   Exception
  public func recordMemory(megabytes: Double) throws {
    let r = newrelic_record_memory_usage(megabytes)
    guard r == 0 else { throw asError(r) }
  }//end func

  /// Record CPU user time in seconds and as a percentage of CPU capacity.
  /// - parameters:
  ///   - timeSeconds: Double, number of seconds CPU spent processing user-level code
  ///   - usagePercent: Double, CPU user time as a percentage of CPU capacity
  /// - throws:
  ///   Exception
  public func recordCPU(timeSeconds: Double, usagePercent: Double) throws {
    let r = newrelic_record_cpu_usage(timeSeconds, usagePercent)
    guard r == 0 else { throw asError(r) }
  }//end func

  /// Record a custom metric.
  /// - parameters:
  ///   - name: name of the metric.
  ///   - value: value of the metric.
  /// - throws:
  ///   Exception
  public func recordMetric(name: String, value: Double) throws {
    let r = newrelic_record_metric(name, value)
    guard r == 0 else { throw asError(r) }
  }//end func

  /// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  /// * Embedded-mode only
  /// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  /// *
  /// * Register a function to handle messages carrying application performance data
  /// * between the instrumented app and CollectorClient. By default, a daemon-mode
  /// * message handler is registered.
  /// *
  /// * If you register the embedded-mode message handler, newrelic_message_handler
  /// * (declared in newrelic_collector_client.h), messages will be passed directly
  /// * to the CollectorClient. Otherwise, the daemon-mode message handler will send
  /// * messages to the CollectorClient via domain sockets.
  /// *
  /// * Note: Register newrelic_message_handler before calling newrelic_init.
  /// - parameters:
  ///   - handler: message handler for embedded-mode
  /// - throws:
  ///   Exception
  public func registerMessageHandler(handler: @escaping (UnsafeRawPointer)->UnsafeRawPointer) {
    newrelic_register_message_handler(handler)
  }//end func

  /// Disable/enable instrumentation. By default, instrumentation is enabled.
  /// All Transaction library functions used for instrumentation will immediately
  /// return when you disable.
  /// - parameters:
  ///   - enabled: true for enabled and false for disabled
  /// - throws:
  ///   Exception
  public func enableInstrumentation(_ enabled: Bool) {
    newrelic_enable_instrumentation(enabled ? 1 :  0)
  }//end func

  /// - parameters:
  /// - throws:
  ///   Exception
  public func obfuscator(raw: String) -> String? {
    return String(validatingUTF8: newrelic_basic_literal_replacement_obfuscator(raw))
  }//end func

  /// - parameters:
  /// - throws:
  ///   Exception
  public func messageHandler(raw: UnsafeRawPointer) -> UnsafeRawPointer {
    return newrelic_message_handler(raw)
  }//end func

  /// - parameters:
  /// - throws:
  ///   Exception
  public func setStatus(callback: @escaping (Int32) -> Void ) {
    newrelic_register_status_callback(callback)
  }//end func

  /// - parameters:
  /// - throws:
  ///   Exception
  public func register(license: String, appName: String, language: String = "Swift", version: String = "3.1") throws {
    let r = newrelic_init(license, appName, language, version)
    guard r == 0 else { throw asError(r) }
  }//end func

  /// - parameters:
  /// - throws:
  ///   Exception
  public func shutdown(reason: String) throws {
    let r = newrelic_request_shutdown(reason)
    guard r == 0 else { throw asError(r) }
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

  public typealias StringCallBack = (String) -> String
  public static var SQLObfuscator: StringCallBack = { $0 }

  /// - parameters:
  /// - throws:
  ///   Exception
  public init(_ instance: NewRelic) throws {
    parent = instance
    id = parent.newrelic_transaction_begin()
    guard id > 0 else { throw parent.asError(id) }
  }

  /// - parameters:
  /// - throws:
  ///   Exception
  public func setType(web: Bool) throws {
    let r = web ?
      parent.newrelic_transaction_set_type_web( id ) :
      parent.newrelic_transaction_set_type_other ( id )
    guard r == 0 else { throw parent.asError(r) }
  }

  /// - parameters:
  /// - throws:
  ///   Exception
  public func setCategory(_ category: String) throws {
    let r = parent.newrelic_transaction_set_category(id, category)
    guard r == 0 else { throw parent.asError(r) }
  }

  /// - parameters:
  /// - throws:
  ///   Exception
  public func setErrorNotice(exceptionType: String, errorMessage: String, stackTrace: String, stackFrameDelimiter: String) throws {
    let r = parent.newrelic_transaction_notice_error(id, exceptionType, errorMessage, stackTrace, stackFrameDelimiter)
    guard r == 0 else { throw parent.asError(r) }
  }

  /// - parameters:
  /// - throws:
  ///   Exception
  public func setName(_ name: String) throws {
    let r = parent.newrelic_transaction_set_name(id, name)
    guard r == 0 else { throw parent.asError(r) }
  }

  /// - parameters:
  /// - throws:
  ///   Exception
  public func setRequest(url: String) throws {
    let r = parent.newrelic_transaction_set_request_url(id, url)
    guard r == 0 else { throw parent.asError(r) }
  }
  /// - parameters:
  /// - throws:
  ///   Exception
  public func add(attributes: [String: String]) throws {
    for (name, value) in attributes {
      let r = parent.newrelic_transaction_add_attribute(id, name, value)
      guard r == 0 else { throw parent.asError(r) }
    }//next
  }

  /// - parameters:
  /// - throws:
  ///   Exception
  public func setMaxTraceSegements(_ maxTraceSegments: Int = 2000) throws {
    let r = parent.newrelic_transaction_set_max_trace_segments(id, Int32(maxTraceSegments))
    guard r == 0 else { throw parent.asError(r) }
  }

  /// - parameters:
  /// - throws:
  ///   Exception
  public func segBeginGeneric(parentSegmentId: Int, name: String) throws -> Int {
    let r = parent.newrelic_segment_generic_begin(id, Int32(parentSegmentId), name)
    guard r > 0 else { throw parent.asError(r) }
    return Int(r)
  }

  /// - parameters:
  /// - throws:
  ///   Exception
  public func segBeginDataStore(parentSegmentId: Int, table: String, operation: String, sql: String, sqlTraceRollupName: String, sqlObfuscator: @escaping StringCallBack ) throws -> Int {
    Transaction.SQLObfuscator = sqlObfuscator
    let r = parent.newrelic_segment_datastore_begin(id, Int32(parentSegmentId), table, operation, sql, sqlTraceRollupName, {
      pstring in
      let r = Transaction.SQLObfuscator(String(cString: pstring))
      return unsafeBitCast(strdup(r), to: UnsafePointer<Int8>.self)
    })
    guard r > 0 else { throw parent.asError(r) }
    return Int(r)
  }

  /// - parameters:
  /// - throws:
  ///   Exception
  public func segBeginExternal(parentSegmentId: Int, host: String, name: String) throws -> Int {
    let r = parent.newrelic_segment_external_begin(id, Int32(parentSegmentId), host, name)
    guard r > 0 else { throw parent.asError(r) }
    return Int(r)
  }

  /// - parameters:
  /// - throws:
  ///   Exception
  public func segEnd(_ segId: Int) throws {
    let r = parent.newrelic_segment_end(id, Int32(segId))
    guard r == 0 else { throw parent.asError(r) }
  }

  deinit {
    _ = parent.newrelic_transaction_end(id)
  }
}
