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
    func testDisabled() {
       do {
         let nr = try NewRelic(mode: .EMBEDDED)
         try nr.register(license: "my-lic", appName: "my-app")
         nr.registerStatus { code in
            guard let status = NewRelic.Status(rawValue: code) else {
         		   XCTFail("Bad Status: \(code)")
               return
         	  }//end guard
         	  switch status {
            case .STARTING: print("starting")
            case .STARTED: print("started")
            case .STOPPING: print("stopping")
            default: print("shutdown")
            }
         }

         nr.enableInstrumentation(false)
         try nr.recordMetric(name: "my-var", value: 0.1)
         try nr.recordCPU(timeSeconds: 5.0, usagePercent: 1.2)
         try nr.recordMemory(megabytes: 32)
         let t = try Transaction(nr, webType: false,
            category: "my-class-1", name: "my-transaction-name",
            url: "http://localhost",
            attributes: ["tom": "jerry", "pros":"cons", "muddy":"puddels"],
            maxTraceSegments: 2000)
         try t.setErrorNotice(exceptionType: "my-panic-type-1", errorMessage: "my-notice", stackTrace: "my-stack", stackFrameDelimiter: "<frame>")
         let root = try t.segBeginGeneric(name: "my-segment")
         let sub = try t.segBeginDataStore(parentSegmentId: root, table: "my-table", operation: .INSERT, sql: "INSERT INTO table(field) value('000-000-0000')")
         let s2 = try t.segBeginExternal(parentSegmentId: sub, host: "perfect.org", name: "my-seg")
         try t.segEnd(s2)
         try t.segEnd(sub)
         try t.segEnd(root)
         try nr.shutdown(reason: "no reason")
       }catch (let err) {
         switch err {
         case NewRelic.Exception.DISABLED: ()
         default:
           print(err)
           XCTFail("\(err)")
         }
       }
    }

    static var allTests = [
        ("testDisabled", testDisabled)
    ]
}
