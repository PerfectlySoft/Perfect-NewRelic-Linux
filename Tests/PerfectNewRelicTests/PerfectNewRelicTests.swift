//
//  PerfectNewRelicTests.swift
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

import XCTest
import SwiftGlibc
@testable import PerfectNewRelic

class PerfectNewRelicTests: XCTestCase {
    func testExample() {
       do {
         let nr = try NewRelic()
         try nr.register(license: "my-lic", appName: "my-app")
         nr.setStatus { code in
           print(code)
         }
         let s = nr.obfuscator(raw: "SELECT * FROM table WHERE ssn=‘000-00-0000’") ?? ""
         print(s)
         nr.enableInstrumentation(false)
         nr.registerMessageHandler { param -> UnsafeRawPointer in
           return param
         }
         try nr.recordMetric(name: "my-var", value: 0.1)
         try nr.recordCPU(timeSeconds: 5.0, usagePercent: 1.2)
         try nr.recordMemory(megabytes: 32)
         let t = try Transaction(nr)
         try t.setType(web: true)
         try t.setType(web: false)
         try t.setCategory("my-class-1")
         try t.setErrorNotice(exceptionType: "my-panic-type-1", errorMessage: "my-notice", stackTrace: "my-stack", stackFrameDelimiter: "<frame>")
         try t.add(attributes: ["tom": "jerry", "pros":"cons", "muddy":"puddels"])
         try t.setName("my-transaction-name")
         try t.setMaxTraceSegements()
         let s0 = try t.segBeginGeneric(parentSegmentId: 100, name: "my-segment")
         try t.segEnd(s0)
         let s1 = try t.segBeginDataStore(parentSegmentId: 100, table: "my-table", operation: "my-op", sql: "SELECT * FROM table", sqlTraceRollupName: "my-rollback") {
           obfused in
           print(obfused)
           return obfused
         }//end
         try t.segEnd(s1)
         let s2 = try t.segBeginExternal(parentSegmentId: 100, host: "perfect.org", name: "my-seg")
         try t.segEnd(s2)
         try nr.shutdown(reason: "no reason")
       }catch (let err) {
         switch err {
         case NewRelic.Exception.FUN(let code):
          XCTAssertEqual(code, NewRelic.RCODE.DISABLED)
         default:
              XCTFail("\(err)")
         }
       }
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}