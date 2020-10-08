//
//  RxEntityTests.swift
//  RxEntityTests
//
//  Created by ALEXEY ABDULIN on 10/02/2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import XCTest
import RxSwift
@testable import RxEntity

struct TestStruct
{
    var i: Int
}

class RxEntityTests: XCTestCase {

    let dispBag = DisposeBag()
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func get( t: [Int] ) -> [Int]
    {
        return t
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        var t = [1]
        var t0 = [1]
        print( "T - \(t)" )
        if t == t0
        {
            print( "equal" )
        }
        t0.append( 2 )
        
        let scheduler0 = SerialDispatchQueueScheduler( internalSerialQueueName: "TEST - 1" )
        let scheduler1 = SerialDispatchQueueScheduler( internalSerialQueueName: "TEST - 2" )
        var obs1 = Observable<Int>.timer( .milliseconds( 400 ), scheduler: scheduler0 ).map { "MESSAGE1 - \($0)" }
        var obs2 = Observable<Int>.timer( .milliseconds( 100 ), scheduler: scheduler1 ).map { "MESSAGE2 - \($0)" }
        Observable
            .combineLatest( obs1.observeOn( scheduler1 ), obs2.observeOn( scheduler1 ), resultSelector: {
                
                return "\($0) \($1)"
            } )
        .observeOn( scheduler1 )
            .subscribe( onNext: { t in
                print( "MESSAGE - \(t)" )
            } )
        .disposed( by: dispBag )
        
        Thread.sleep( forTimeInterval: 1.5 )
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
