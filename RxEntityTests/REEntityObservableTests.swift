//
//  REEntityObservableTests.swift
//  BaseMVVMTests
//
//  Created by ALEXEY ABDULIN on 22/01/2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import XCTest

import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import RxEntity

struct TestEnity: REEntity
{
    var key: REEntityKey { return REEntityKey( id ) }
    
    let id: String
    let value: String
    
    func Modified( value: String ) -> TestEnity
    {
        return TestEnity( id: id, value: value )
    }
}

struct ExtraParams
{
    let test: String
}

struct ExtraCollectionParams
{
    let test: String
}


class REEntityObservableTests: XCTestCase
{
    func test()
    {
        let collection = REEntityObservableCollection<TestEnity>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ) )
        let single = collection.CreateSingle { _ in Single.just( TestEnity( id: "1", value: "2" ) ) }
        let f = try! single
            .toBlocking()
            .first()!
        /*
        let kp = \TestEnity.id
        let p = f[keyPath: kp]
        f[keyPath: kp] = "23"
        let m = Mirror( reflecting: f )
        print( "\(m.children)" )
        m.children.forEach( { print( "\($0.label) \($0.value)" ) } )
        */
        XCTAssertEqual( f.id, "1" )
        XCTAssertEqual( f.value, "2" )
        
        let pages = collection.CreatePaginator { _ in Single.just( [TestEnity( id: "1", value: "3" ), TestEnity( id: "2", value: "4" )] ) }
        let arr = try! pages
            .toBlocking()
            .first()!
        
        XCTAssertEqual( pages.page, PAGINATOR_END )
        
        XCTAssertEqual( arr[0].id, "1" )
        XCTAssertEqual( arr[0].value, "3" )
        XCTAssertEqual( arr[1].id, "2" )
        XCTAssertEqual( arr[1].value, "4" )
        
        let f0 = try! single
            .toBlocking()
            .first()!
        
        XCTAssertEqual( f0.id, "1" )
        XCTAssertEqual( f0.value, "3" )
        
        _ = try! collection
            .RxRequestForUpdate( key: REEntityKey( "1" ) ) { $0.Modified( value: "10" ) }
            .toBlocking()
            .first()!
        
        let f1 = try! single
            .toBlocking()
            .first()!
        
        XCTAssertEqual( f1.id, "1" )
        XCTAssertEqual( f1.value, "10" )
        
        let arr1 = try! pages
            .toBlocking()
            .first()!
        
        XCTAssertEqual( arr1[0].id, "1" )
        XCTAssertEqual( arr1[0].value, "10" )
        XCTAssertEqual( arr1[1].id, "2" )
        XCTAssertEqual( arr1[1].value, "4" )
        
        _ = try! collection
            .RxRequestForUpdate( keys: [REEntityKey( "1" ), REEntityKey( "2" )] ) { $0.Modified( value: "1\($0.id)" ) }
            .toBlocking()
            .first()!
        
        let f2 = try! single
            .toBlocking()
            .first()!
        
        XCTAssertEqual( f2.id, "1" )
        XCTAssertEqual( f2.value, "1\(f2.id)" )
        
        let arr2 = try! pages
            .toBlocking()
            .first()!
        
        XCTAssertEqual( arr2[0].id, "1" )
        XCTAssertEqual( arr2[0].value, "1\(arr2[0].id)" )
        XCTAssertEqual( arr2[1].id, "2" )
        XCTAssertEqual( arr2[1].value, "1\(arr2[1].id)" )
        
        let f3_ = try! collection
            .RxUpdate( entity: TestEnity( id: "1", value: "25" ) )
            .toBlocking()
            .first()!
        
        let f3 = try! single
            .toBlocking()
            .first()!
        
        XCTAssertEqual( f3.id, "1" )
        XCTAssertEqual( f3.value, "25" )
        XCTAssertEqual( f3.id, f3_.id )
        XCTAssertEqual( f3.value, f3_.value )
        
        single.Refresh()
        Thread.sleep( forTimeInterval: 0.5 )
        
        let f4 = try! single
            .toBlocking()
            .first()!
        
        XCTAssertEqual( f4.id, "1" )
        XCTAssertEqual( f4.value, "2" )
        
        pages.Refresh()
        Thread.sleep( forTimeInterval: 0.5 )
        
        let f5 = try! single
            .toBlocking()
            .first()!
        
        XCTAssertEqual( f5.id, "1" )
        XCTAssertEqual( f5.value, "3" )
    }
    
    func testExtra()
    {
        let collection = REEntityObservableCollection<TestEnity>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ) )
        let single = collection.CreateSingleExtra( extra: ExtraParams( test: "test" ) )
        {
            if $0.first
            {
                XCTAssertEqual( $0.extra!.test, "test" )
            }
            else
            {
                XCTAssertEqual( $0.extra!.test, "test2" )
                XCTAssertEqual( $0.refreshing, true )
            }
            
            return Single.just( TestEnity( id: "1", value: "2" ) )
            
        }
        
        _ = try! single
            .toBlocking()
            .first()!
        
        single.Refresh( extra: ExtraParams( test: "test2" ) )
        
        _ = try! single
            .toBlocking()
            .first()!
        
        
        let pages = collection.CreatePaginatorExtra( extra: ExtraParams( test: "test" ) )
        {
            if $0.first
            {
                XCTAssertEqual( $0.extra!.test, "test" )
            }
            else
            {
                XCTAssertEqual( $0.extra!.test, "test2" )
                XCTAssertEqual( $0.refreshing, true )
                XCTAssertEqual( $0.page, 0 )
            }
            
            return Single.just( [TestEnity( id: "1", value: "3" ), TestEnity( id: "2", value: "4" )] )
            
        }
        
        _ = try! pages
            .toBlocking()
            .first()!
        
        pages.Refresh( extra: ExtraParams( test: "test2" ) )
        
        _ = try! pages
            .toBlocking()
            .first()!
        
        Thread.sleep( forTimeInterval: 0.5 )
    }
    
    func testCollectionExtra()
    {
        let collection = REEntityObservableCollectionExtra<TestEnity, ExtraCollectionParams>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ), collectionExtra: ExtraCollectionParams( test: "test" ) )
        let single = collection.CreateSingleExtra( extra: ExtraParams( test: "test" ) )
        {
            if $0.first
            {
                XCTAssertEqual( $0.collectionExtra!.test, "test" )
            }
            else
            {
                XCTAssertEqual( $0.extra!.test, "test" )
                XCTAssertEqual( $0.collectionExtra!.test, "test2" )
                XCTAssertEqual( $0.refreshing, true )
            }
            
            return Single.just( TestEnity( id: "1", value: "2" ) )
            
        }
        
        _ = try! single
            .toBlocking()
            .first()!

        let pages = collection.CreatePaginatorExtra( extra: ExtraParams( test: "test" ) )
        {
            if $0.first
            {
                XCTAssertEqual( $0.collectionExtra!.test, "test" )
            }
            else
            {
                XCTAssertEqual( $0.extra!.test, "test" )
                XCTAssertEqual( $0.collectionExtra!.test, "test2" )
                XCTAssertEqual( $0.refreshing, true )
                XCTAssertEqual( $0.page, 0 )
            }
            
            return Single.just( [TestEnity( id: "1", value: "3" ), TestEnity( id: "2", value: "4" )] )
            
        }
        
        _ = try! pages
            .toBlocking()
            .first()!
        
        collection.Refresh( collectionExtra: ExtraCollectionParams( test: "test2" ) )

        Thread.sleep( forTimeInterval: 0.5 )
        
        _ = try! single
            .toBlocking()
            .first()!

        _ = try! pages
            .toBlocking()
            .first()!
    }
    
    func testArrayGetSingle()
    {
        var i = 0
        let collection = REEntityObservableCollectionExtra<TestEnity, ExtraCollectionParams>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ), collectionExtra: ExtraCollectionParams( test: "test" ) )
        collection.singleFetchCallback =
        {
            if $0.first
            {
                XCTAssertEqual( $0.collectionExtra!.test, "test" )
            }
            else
            {
                XCTAssertEqual( $0.refreshing, true )
            }
            
            return Single.just( TestEnity( id: $0.lastEntity!.id, value: $0.collectionExtra!.test + (i == 0 ? "sr" : "") + $0.lastEntity!.id ) )
            
        }
        
        let pages = collection.CreatePaginatorExtra( extra: ExtraParams( test: "test" ) )
        {
            if $0.first
            {
                XCTAssertEqual( $0.collectionExtra!.test, "test" )
            }
            else
            {
                XCTAssertEqual( $0.extra!.test, "test" )
                XCTAssertEqual( $0.collectionExtra!.test, "test2" )
                XCTAssertEqual( $0.refreshing, true )
                XCTAssertEqual( $0.page, 0 )
            }
            
            return Single.just( [TestEnity( id: "1", value: $0.collectionExtra!.test + "1" ), TestEnity( id: "2", value: $0.collectionExtra!.test + "2" )] )
            
        }
        
        _ = try! pages
            .toBlocking()
            .first()!
        
        let single0 = pages[0]
        let single1 = pages[1]
        
        var s0 = try! single0
            .toBlocking()
            .first()!
        
        var s1 = try! single1
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s0.id, "1" )
        XCTAssertEqual( s0.value, "test1" )
        XCTAssertEqual( s1.id, "2" )
        XCTAssertEqual( s1.value, "test2" )
        
        single0.Refresh()
        single1.Refresh()
        
        Thread.sleep( forTimeInterval: 0.5 )
        
        s0 = try! single0
            .toBlocking()
            .first()!
        
        s1 = try! single1
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s0.id, "1" )
        XCTAssertEqual( s0.value, "testsr1" )
        XCTAssertEqual( s1.id, "2" )
        XCTAssertEqual( s1.value, "testsr2" )
        
        i = 1
        collection.Refresh( collectionExtra: ExtraCollectionParams( test: "test2" ) )

        Thread.sleep( forTimeInterval: 0.5 )
        
        s0 = try! single0
            .toBlocking()
            .first()!
        
        s1 = try! single1
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s0.id, "1" )
        XCTAssertEqual( s0.value, "test21" )
        XCTAssertEqual( s1.id, "2" )
        XCTAssertEqual( s1.value, "test22" )
    }
}
