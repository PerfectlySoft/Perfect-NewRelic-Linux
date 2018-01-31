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
import Foundation
import Dispatch
import Glibc
@testable import PerfectNewRelic

class PerfectNewRelicTests: XCTestCase {
  // NOTE: use install.sh to install the newrelic-collector-client-daemon service
  // this script depends on this service.
    func testExample() {
       do {
         let nr = try NewRelic()
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
         print("wait for 90 seconds ...")
         nr.enableInstrumentation(true)
         for i in 1 ... 10 {
           let j = Double(i)
           print(j)
           try nr.recordMetric(name: "ActiveUsers", value: 0.1 * j)
           try nr.recordCPU(timeSeconds: 5.0 * j , usagePercent: 1.2 * j)
           try nr.recordMemory(megabytes: 32 * j)
           let t = try Transaction(nr, webType: false,
              category: "my-class-1", name: "my-transaction-name",
              url: "http://localhost",
              attributes: ["tom": "jerry", "pros":"cons", "muddy":"puddels"],
              maxTraceSegments: 20)
              try t.setErrorNotice(exceptionType: "my-panic-type-1", errorMessage: "my-notice", stackTrace: "my-stack", stackFrameDelimiter: "<frame>")
              let root = try t.segBeginGeneric(name: "my-segment")
              print("root", root)
              sleep(1)
              try t.segEnd(root)
              let sub = try t.segBeginDataStore(table: "my-table", operation: .INSERT, sql: "INSERT INTO table(field) value('000-000-0000')")
              print("sub", sub)
              sleep(1)
              try t.segEnd(sub)
              let s2 = try t.segBeginExternal(host: "perfect.org", name: "my-seg")
              print("s2", s2)
              sleep(1)
              try t.segEnd(s2)
         }//next
       }catch (let err) {
          XCTFail("\(err)")
       }
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
