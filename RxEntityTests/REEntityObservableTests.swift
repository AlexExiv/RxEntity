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

protocol TestEntityBackProtocol: REBackEntityProtocol
{
    var id: String { get }
    var value: String { get }
    
    init( entity: TestEntityBackProtocol )
}

extension TestEntityBackProtocol
{
    var _key: REEntityKey { return REEntityKey( id ) }
    
    init( entity: REBackEntityProtocol )
    {
        self.init( entity: entity as! TestEntityBackProtocol )
    }
}

struct TestEntityBack: TestEntityBackProtocol
{
    let id: String
    let value: String
    
    init( id: String, value: String )
    {
        self.id = id
        self.value = value
    }
    
    init( entity: TestEntityBackProtocol )
    {
        id = entity.id
        value = entity.value
    }
}

struct TestEntity: REEntity
{
    var _key: REEntityKey { return REEntityKey( id ) }
    
    let id: String
    let value: String
    
    init( entity: REBackEntityProtocol )
    {
        self.init( entity: entity as! TestEntityBackProtocol )
    }
    
    init( entity: TestEntityBackProtocol )
    {
        id = entity.id
        value = entity.value
    }
    
    init( id: String, value: String )
    {
        self.id = id
        self.value = value
    }
    
    func Modified( value: String ) -> TestEntity
    {
        return TestEntity( id: id, value: value )
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
        let collection = REEntityObservableCollection<TestEntity>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ) )
        let single = collection.CreateSingleBack { _ in Single.just( TestEntityBack( id: "1", value: "2" ) ) }
        let f = try! single
            .toBlocking()
            .first()!
        /*
        let kp = \TestEntity.id
        let p = f[keyPath: kp]
        f[keyPath: kp] = "23"
        let m = Mirror( reflecting: f )
        print( "\(m.children)" )
        m.children.forEach( { print( "\($0.label) \($0.value)" ) } )
        */
        XCTAssertEqual( f.id, "1" )
        XCTAssertEqual( f.value, "2" )
        
        let pages = collection.CreatePaginatorBack { _ in Single.just( [TestEntityBack( id: "1", value: "3" ), TestEntityBack( id: "2", value: "4" )] ) }
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
            .RxUpdate( entity: TestEntity( id: "1", value: "25" ) )
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
        let collection = REEntityObservableCollection<TestEntity>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ) )
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
            
            return Single.just( TestEntity( id: "1", value: "2" ) )
            
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
            
            return Single.just( [TestEntity( id: "1", value: "3" ), TestEntity( id: "2", value: "4" )] )
            
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
        let collection = REEntityObservableCollectionExtra<TestEntity, ExtraCollectionParams>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ), collectionExtra: ExtraCollectionParams( test: "test" ) )
        let single = collection.CreateSingleBackExtra( extra: ExtraParams( test: "test" ) )
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
            
            return Single.just( TestEntityBack( id: "1", value: "2" ) )
            
        }
        
        _ = try! single
            .toBlocking()
            .first()!

        let pages = collection.CreatePaginatorBackExtra( extra: ExtraParams( test: "test" ) )
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
            
            return Single.just( [TestEntityBack( id: "1", value: "3" ), TestEntityBack( id: "2", value: "4" )] )
            
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
        let collection = REEntityObservableCollectionExtra<TestEntity, ExtraCollectionParams>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ), collectionExtra: ExtraCollectionParams( test: "test" ) )
        collection.singleFetchBackCallback =
        {
            if $0.first
            {
                XCTAssertEqual( $0.collectionExtra!.test, "test" )
            }
            else
            {
                XCTAssertEqual( $0.refreshing, true )
            }
            
            return Single.just( TestEntityBack( id: $0.lastEntity!.id, value: $0.collectionExtra!.test + (i == 0 ? "sr" : "") + $0.lastEntity!.id ) )
            
        }
        
        let pages = collection.CreatePaginatorBackExtra( extra: ExtraParams( test: "test" ) )
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
            
            return Single.just( [TestEntityBack( id: "1", value: $0.collectionExtra!.test + "1" ), TestEntityBack( id: "2", value: $0.collectionExtra!.test + "2" )] )
            
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
    
    func testArrayInitial()
    {
        let collection = REEntityObservableCollectionExtra<TestEntity, ExtraCollectionParams>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ), collectionExtra: ExtraCollectionParams( test: "test" ) )
        collection.arrayFetchBackCallback =
        {
            pp in Single.just( pp.keys.map { TestEntityBack( id: $0.stringKey, value: pp.collectionExtra!.test + $0.stringKey ) } )
        }
        
        let array = collection.CreateArray( initial: [TestEntity( id: "1", value: "3" ), TestEntity( id: "2", value: "4" )] )
        
        var s = try! array
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s[0].id, "1" )
        XCTAssertEqual( s[0].value, "3" )
        XCTAssertEqual( s[1].id, "2" )
        XCTAssertEqual( s[1].value, "4" )
        
        collection.Refresh()
        Thread.sleep( forTimeInterval: 0.5 )
        
        s = try! array
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s[0].id, "1" )
        XCTAssertEqual( s[0].value, "test1" )
        XCTAssertEqual( s[1].id, "2" )
        XCTAssertEqual( s[1].value, "test2" )
        
        collection.Refresh( collectionExtra: ExtraCollectionParams( test: "test2" ) )
        Thread.sleep( forTimeInterval: 0.5 )
        
        s = try! array
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s[0].id, "1" )
        XCTAssertEqual( s[0].value, "test21" )
        XCTAssertEqual( s[1].id, "2" )
        XCTAssertEqual( s[1].value, "test22" )
    }
    
    func testMergeWithSingle()
    {
        let collection = REEntityObservableCollectionExtra<TestEntity, ExtraCollectionParams>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ) )
        let rxObs = BehaviorSubject( value: "2" )
        let rxObs1 = BehaviorSubject( value: "3" )
        collection.combineLatest( rxObs, rxObs1 ) { $0.Modified( value: $1 + $2 ) }
        collection.combineLatest( rxObs ) { $0.Modified( value: $1 ) }
        collection.combineLatest( rxObs1 ) { $0.Modified( value: $1 ) }
        let single0 = collection.CreateSingleBack( key: "1" ) { _ in Single.just( TestEntityBack( id: "1", value: "1" ) ) }

        var s = try! single0
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s.id, "1" )
        XCTAssertEqual( s.value, "3" )

        rxObs.onNext( "4" )
        rxObs1.onNext( "4" )
        Thread.sleep( forTimeInterval: 0.5 )
        
        s = try! single0
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s.id, "1" )
        XCTAssertEqual( s.value, "4" )

        rxObs1.onNext( "5" )
        Thread.sleep( forTimeInterval: 0.5 )
        
        s = try! single0
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s.id, "1" )
        XCTAssertEqual( s.value, "5" )
    }
    
    func testMergeWithPaginator()
    {
        let collection = REEntityObservableCollectionExtra<TestEntity, ExtraCollectionParams>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ) )
        let rxObs = BehaviorSubject( value: "2" )
        let rxObs1 = BehaviorSubject( value: "3" )
        collection.combineLatest( rxObs ) { $0.Modified( value: "\($0.id)\($1)" ) }
        collection.combineLatest( rxObs1 ) { $0.Modified( value: "\($0.id)\($1)" ) }
        let pager = collection.CreatePaginatorBack( perPage: 2 ) {
            if ($0.page == 0)
            {
                return Single.just([TestEntityBack(id: "1", value: "1"), TestEntityBack(id: "2", value: "1")])
            }
            else
            {
                return Single.just([TestEntityBack(id: "3", value: "1"), TestEntityBack(id: "4", value: "1")])
            }
        }
        
        var s =  try! pager
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s.count, 2 )
        XCTAssertEqual( s[0].id, "1" )
        XCTAssertEqual( s[0].value, "13" )

        rxObs.onNext( "4" )
        rxObs1.onNext( "4" )
        Thread.sleep( forTimeInterval: 0.5 )
        
        s = try! pager
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s[0].id, "1" )
        XCTAssertEqual( s[0].value, "14" )

        rxObs1.onNext( "5" )
        Thread.sleep( forTimeInterval: 0.5 )
        
        s = try! pager
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s[0].id, "1" )
        XCTAssertEqual( s[0].value, "15" )

        pager.Next()
        Thread.sleep( forTimeInterval: 0.5 )
        
        s = try! pager
            .toBlocking()
            .first()!

        XCTAssertEqual( s.count, 4 )
        XCTAssertEqual( s[2].id, "3" )
        XCTAssertEqual( s[2].value, "35" )
    }
    
    func testArrayInitialMerge()
    {
        var i = 0
        let collection = REEntityObservableCollectionExtra<TestEntity, ExtraCollectionParams>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ), collectionExtra: ExtraCollectionParams( test: "2" ) )

        let rxObs = BehaviorSubject( value: "2" )
        let rxObs1 = BehaviorSubject( value: "3" )
        collection.combineLatest( rxObs ) { $0.Modified( value: "\($0.id)\($1)" ) }
        collection.combineLatest( rxObs1 ) { $0.Modified( value: "\($0.id)\($1)" ) }

        collection.arrayFetchCallback = { pp in
            Single.just( [] )
        }

        let array = collection.CreateArray( initial: [TestEntity( id: "1", value: "2" ), TestEntity( id: "2", value: "3" ) ] )
        
        var s = try! array
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s.count, 2 )
        XCTAssertEqual( s[0].id, "1" )
        XCTAssertEqual( s[0].value, "13" )

        rxObs.onNext("4")
        rxObs1.onNext("4")
        Thread.sleep( forTimeInterval: 0.5 )
        
        s = try! array
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s[0].id, "1" )
        XCTAssertEqual( s[0].value, "14" )

        rxObs1.onNext("5")
        Thread.sleep( forTimeInterval: 0.5 )
        
        s = try! array
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s[0].id, "1" )
        XCTAssertEqual( s[0].value, "15" )
    }
    
    func testSingleStateAndLoading()
    {
        let collection = REEntityObservableCollectionExtra<TestEntity, ExtraCollectionParams>( queue: OperationQueueScheduler( operationQueue: OperationQueue() ), collectionExtra: ExtraCollectionParams( test: "2" ) )
        let single = collection.CreateSingle( start: false )
        {
            $0.first ? Single.just( nil ) : Single.just( TestEntity( id: "1", value: "2" ) )
        }

        var s = try! single
            .rxState
            .toBlocking()
            .first()!
        
        var l = try! single
            .rxLoader
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s, RESingleObservableExtra.State.initializing )
        XCTAssertEqual( l, REEntityObservable.Loading.none )
        
        single.Refresh()
        
        l = try! single
            .rxLoader
            .filter { $0 == .firstLoading }
            .toBlocking()
            .first()!
        
        XCTAssertEqual( l, REEntityObservable.Loading.firstLoading )
        
        Thread.sleep( forTimeInterval: 0.5 )
        
        s = try! single
            .rxState
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s, RESingleObservableExtra.State.notFound )
        
        single.Refresh()
        
        l = try! single
            .rxLoader
            .filter { $0 == .loading }
            .toBlocking()
            .first()!
        
        XCTAssertEqual( l, REEntityObservable.Loading.loading )
        
        
        Thread.sleep( forTimeInterval: 0.5 )
        
        s = try! single
            .rxState
            .toBlocking()
            .first()!
        
        XCTAssertEqual( s, RESingleObservableExtra.State.ready )
    }
}
