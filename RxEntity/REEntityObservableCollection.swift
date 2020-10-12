//
//  REEntityObservableCollection.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 25/11/2019.
//  Copyright © 2019 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

public struct REEntityCollectionExtraParamsEmpty
{
    
}

typealias CombineMethod<E> = (E, Array<Any>) -> (E, Bool)

struct RECombineSource<E>
{
    let sources: [Observable<Any>]
    let combine: CombineMethod<E>
}

public class REEntityObservableCollectionExtra<Entity: REEntity, CollectionExtra>: REEntityCollection<Entity>
{
    public typealias SingleFetchBackCallback = RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>.SingleFetchBackCallback
    public typealias SingleExtraFetchBackCallback<Extra> = RESingleObservableCollectionExtra<Entity, Extra, CollectionExtra>.SingleFetchBackCallback
    
    public typealias SingleFetchCallback = RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>.SingleFetchCallback
    public typealias SingleExtraFetchCallback<Extra> = RESingleObservableCollectionExtra<Entity, Extra, CollectionExtra>.SingleFetchCallback
    
    public typealias KeyArrayFetchBackCallback = REKeyArrayObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>.ArrayFetchBackCallback<REEntityExtraParamsEmpty, CollectionExtra>
    public typealias KeyArrayExtraFetchBackCallback<Extra> = REKeyArrayObservableCollectionExtra<Entity, Extra, CollectionExtra>.ArrayFetchBackCallback<Extra, CollectionExtra>
    
    public typealias KeyArrayFetchCallback = REKeyArrayObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>.ArrayFetchCallback<REEntityExtraParamsEmpty, CollectionExtra>
    public typealias KeyArrayExtraFetchCallback<Extra> = REKeyArrayObservableCollectionExtra<Entity, Extra, CollectionExtra>.ArrayFetchCallback<Extra, CollectionExtra>
    
    public typealias PageFetchBackCallback = REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>.PageFetchBackCallback<REEntityExtraParamsEmpty, CollectionExtra>
    public typealias PageExtraFetchBackCallback<Extra> = REPaginatorObservableCollectionExtra<Entity, Extra, CollectionExtra>.PageFetchBackCallback<Extra, CollectionExtra>
    
    public typealias PageFetchCallback = REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>.PageFetchCallback<REEntityExtraParamsEmpty, CollectionExtra>
    public typealias PageExtraFetchCallback<Extra> = REPaginatorObservableCollectionExtra<Entity, Extra, CollectionExtra>.PageFetchCallback<Extra, CollectionExtra>
    
    public var singleFetchBackCallback: SingleFetchBackCallback? = nil
    public var singleFetchCallback: SingleFetchCallback? = nil
    public var arrayFetchBackCallback: KeyArrayFetchBackCallback? = nil
    public var arrayFetchCallback: KeyArrayFetchCallback? = nil
    
    public private(set) var collectionExtra: CollectionExtra? = nil
    private(set) var combineSources = [RECombineSource<Entity>]()
    
    var combineDisp: Disposable? = nil
        
    public convenience init( operationQueue: OperationQueue, collectionExtra: CollectionExtra? = nil )
    {
        self.init( queue: OperationQueueScheduler( operationQueue: operationQueue ), collectionExtra: collectionExtra )
    }
    
    public init( queue: OperationQueueScheduler, collectionExtra: CollectionExtra? = nil )
    {
        self.collectionExtra = collectionExtra
        super.init( queue: queue )
    }
    
    deinit
    {
        combineDisp?.dispose()
    }

    //MARK: - Single Observables
    public func CreateSingleBack( key: REEntityKey? = nil, start: Bool = true, _ fetch: @escaping SingleFetchBackCallback ) -> RESingleObservable<Entity>
    {
        return RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, key: key, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }

    public func CreateSingleBackExtra<Extra>( key: REEntityKey? = nil, extra: Extra? = nil, start: Bool = true, _ fetch: @escaping SingleExtraFetchBackCallback<Extra> ) -> RESingleObservableExtra<Entity, Extra>
    {
        return RESingleObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, key: key, extra: extra, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreateSingle( key: REEntityKey? = nil, start: Bool = true, _ fetch: @escaping SingleFetchCallback ) -> RESingleObservable<Entity>
    {
        return RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, key: key, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }

    public func CreateSingleExtra<Extra>( key: REEntityKey? = nil, extra: Extra? = nil, start: Bool = true, _ fetch: @escaping SingleExtraFetchCallback<Extra> ) -> RESingleObservableExtra<Entity, Extra>
    {
        return RESingleObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, key: key, extra: extra, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }
    
    public override func CreateSingle( initial: Entity, refresh: Bool = false ) -> RESingleObservable<Entity>
    {
        if singleFetchCallback != nil
        {
            return RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, initial: initial, refresh: refresh, collectionExtra: collectionExtra, observeOn: queue, fetch: singleFetchCallback! )
        }
        else if singleFetchBackCallback != nil
        {
            return RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, initial: initial, refresh: refresh, collectionExtra: collectionExtra, observeOn: queue, fetch: singleFetchBackCallback! )
        }
        
        precondition( false, "To create Single with initial value you must specify singleFetchCallback or singleFetchBackCallback before" )
    }
    
    public func CreateSingle( key: REEntityKey, start: Bool = true, refresh: Bool = false ) -> RESingleObservable<Entity>
    {
        let e = sharedEntities[key]
        if e == nil
        {
            if singleFetchCallback != nil
            {
                return CreateSingle( key: key, start: start, singleFetchCallback! )
            }
            else if singleFetchBackCallback != nil
            {
                return CreateSingleBack( key: key, start: start, singleFetchBackCallback! )
            }
            
            precondition( false, "To create Single with key you must specify singleFetchCallback or singleFetchBackCallback before" )
        }
        
        return CreateSingle( initial: e!, refresh: refresh )
    }
    
    //MARK: - Array Observables
    public func CreateArrayBack( start: Bool = true, _ fetch: @escaping PageFetchBackCallback ) -> REArrayObservable<Entity>
    {
        return REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreateArrayBackExtra<Extra>( extra: Extra? = nil, start: Bool = true, _ fetch: @escaping PageExtraFetchBackCallback<Extra> ) -> REArrayObservableExtra<Entity, Extra>
    {
        return REPaginatorObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, extra: extra, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreateArray( start: Bool = true, _ fetch: @escaping PageFetchCallback ) -> REArrayObservable<Entity>
    {
        return REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreateArrayExtra<Extra>( extra: Extra? = nil, start: Bool = true, _ fetch: @escaping PageExtraFetchCallback<Extra> ) -> REArrayObservableExtra<Entity, Extra>
    {
        return REPaginatorObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, extra: extra, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }
    
    //MARK: - Array Keys Observables
    public func CreateKeyArrayBack( keys: [REEntityKey] = [], _ fetch: @escaping KeyArrayFetchBackCallback ) -> REKeyArrayObservable<Entity>
    {
        return REKeyArrayObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, keys: keys, collectionExtra: collectionExtra, observeOn: queue, fetch: fetch )
    }
    
    public func CreateKeyArrayBackExtra<Extra>( keys: [REEntityKey] = [], extra: Extra? = nil, _ fetch: @escaping KeyArrayExtraFetchBackCallback<Extra> ) -> REKeyArrayObservableExtra<Entity, Extra>
    {
        return REKeyArrayObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, keys: keys, extra: extra, collectionExtra: collectionExtra, observeOn: queue, fetch: fetch )
    }
    
    public func CreateKeyArray( keys: [REEntityKey] = [], _ fetch: @escaping KeyArrayFetchCallback ) -> REKeyArrayObservable<Entity>
    {
        return REKeyArrayObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, keys: keys, collectionExtra: collectionExtra, observeOn: queue, fetch: fetch )
    }
    
    public func CreateKeyArrayExtra<Extra>( keys: [REEntityKey] = [], extra: Extra? = nil, _ fetch: @escaping KeyArrayExtraFetchCallback<Extra> ) -> REKeyArrayObservableExtra<Entity, Extra>
    {
        return REKeyArrayObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, keys: keys, extra: extra, collectionExtra: collectionExtra, observeOn: queue, fetch: fetch )
    }
    
    public override func CreateKeyArray( initial: [Entity] ) -> REKeyArrayObservable<Entity>
    {
        if arrayFetchCallback != nil
        {
            return REKeyArrayObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, initial: initial, collectionExtra: collectionExtra, observeOn: queue, fetch: arrayFetchCallback! )
        }
        else if arrayFetchBackCallback != nil
        {
            return REKeyArrayObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, initial: initial, collectionExtra: collectionExtra, observeOn: queue, fetch: arrayFetchBackCallback! )
        }
        
        precondition( false, "To create Array with initial values you must specify arrayFetchCallback or arrayFetchBackCallback before" )
    }
    
    public func CreateKeyArray( keys: [REEntityKey] ) -> REKeyArrayObservable<Entity>
    {
        if arrayFetchCallback != nil
        {
            return CreateKeyArray( keys: keys, arrayFetchCallback! )
        }
        else if arrayFetchBackCallback != nil
        {
            return CreateKeyArrayBack( keys: keys, arrayFetchBackCallback! )
        }
        
        precondition( false, "To create Array with initial values you must specify arrayFetchCallback or arrayFetchBackCallback before" )
    }
    
    //MARK: - Paginator Observables
    public func CreatePaginatorBack( perPage: Int = 35, start: Bool = true, _ fetch: @escaping PageFetchBackCallback ) -> REPaginatorObservable<Entity>
    {
        return REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, collectionExtra: collectionExtra, perPage: perPage, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreatePaginatorBackExtra<Extra>( extra: Extra? = nil, perPage: Int = 35, start: Bool = true, _ fetch: @escaping PageExtraFetchBackCallback<Extra> ) -> REPaginatorObservableExtra<Entity, Extra>
    {
        return REPaginatorObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, extra: extra, collectionExtra: collectionExtra, perPage: perPage, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreatePaginator( perPage: Int = 35, start: Bool = true, _ fetch: @escaping PageFetchCallback ) -> REPaginatorObservable<Entity>
    {
        return REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, collectionExtra: collectionExtra, perPage: perPage, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreatePaginatorExtra<Extra>( extra: Extra? = nil, perPage: Int = 35, start: Bool = true, _ fetch: @escaping PageExtraFetchCallback<Extra> ) -> REPaginatorObservableExtra<Entity, Extra>
    {
        return REPaginatorObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, extra: extra, collectionExtra: collectionExtra, perPage: perPage, start: start, observeOn: queue, fetch: fetch )
    }
    
    //MARK: - Combine Latest
    public func combineLatest<T>( _ source: Observable<T>, _ merge: @escaping (Entity, T) -> (Entity, Bool) )
    {
        combineSources.append( RECombineSource<Entity>( sources: [source.map { $0 as Any }.asObservable().observeOn( queue )], combine: { (e, a) in merge( e, a[0] as! T ) } ) )
        BuildCombines()
    }

    public func combineLatest<T0, T1>( _ source0: Observable<T0>, _ source1: Observable<T1>, _ merge: @escaping (Entity, T0, T1) -> (Entity, Bool) )
    {
        let sources = [source0.map { $0 as Any }.asObservable().observeOn( queue ),
                       source1.map { $0 as Any }.asObservable().observeOn( queue )]
        
        combineSources.append( RECombineSource<Entity>( sources: sources, combine: { (e, a) in merge( e, a[0] as! T0, a[1] as! T1 ) } ) )
        BuildCombines()
    }

    public func combineLatest<T0, T1, T2>( _ source0: Observable<T0>, _ source1: Observable<T1>, _ source2: Observable<T2>, _ merge: @escaping (Entity, T0, T1, T2) -> (Entity, Bool) )
    {
        let sources = [source0.map { $0 as Any }.asObservable().observeOn( queue ),
                       source1.map { $0 as Any }.asObservable().observeOn( queue ),
                       source2.map { $0 as Any }.asObservable().observeOn( queue )]
        
        combineSources.append( RECombineSource<Entity>( sources: sources, combine: { (e, a) in merge( e, a[0] as! T0, a[1] as! T1, a[2] as! T2 ) } ) )
        BuildCombines()
    }

    public func combineLatest<T0, T1, T2, T3>( _ source0: Observable<T0>, _ source1: Observable<T1>, _ source2: Observable<T2>, _ source3: Observable<T3>, _ merge: @escaping (Entity, T0, T1, T2, T3) -> (Entity, Bool))
    {
        let sources = [source0.map { $0 as Any }.asObservable().observeOn( queue ),
                       source1.map { $0 as Any }.asObservable().observeOn( queue ),
                       source2.map { $0 as Any }.asObservable().observeOn( queue ),
                       source3.map { $0 as Any }.asObservable().observeOn( queue )]
        
        combineSources.append( RECombineSource<Entity>( sources: sources, combine: { (e, a) in merge( e, a[0] as! T0, a[1] as! T1, a[2] as! T2, a[3] as! T3 ) } ) )
        BuildCombines()
    }

    public func combineLatest<T0, T1, T2, T3, T4>( _ source0: Observable<T0>, _ source1: Observable<T1>, _ source2: Observable<T2>, _ source3: Observable<T3>, _ source4: Observable<T4>, _ merge: @escaping (Entity, T0, T1, T2, T3, T4) -> (Entity, Bool))
    {
        let sources = [source0.map { $0 as Any }.asObservable().observeOn( queue ),
                       source1.map { $0 as Any }.asObservable().observeOn( queue ),
                       source2.map { $0 as Any }.asObservable().observeOn( queue ),
                       source3.map { $0 as Any }.asObservable().observeOn( queue ),
                       source4.map { $0 as Any }.asObservable().observeOn( queue )]
        
        combineSources.append( RECombineSource<Entity>( sources: sources, combine: { (e, a) in merge( e, a[0] as! T0, a[1] as! T1, a[2] as! T2, a[3] as! T3, a[4] as! T4 ) } ) )
        BuildCombines()
    }

    public func combineLatest<T0, T1, T2, T3, T4, T5>( _ source0: Observable<T0>, _ source1: Observable<T1>, _ source2: Observable<T2>, _ source3: Observable<T3>, _ source4: Observable<T4>, _ source5: Observable<T5>, _ merge: @escaping (Entity, T0, T1, T2, T3, T4, T5) -> (Entity, Bool))
    {
        let sources = [source0.map { $0 as Any }.asObservable().observeOn( queue ),
                       source1.map { $0 as Any }.asObservable().observeOn( queue ),
                       source2.map { $0 as Any }.asObservable().observeOn( queue ),
                       source3.map { $0 as Any }.asObservable().observeOn( queue ),
                       source4.map { $0 as Any }.asObservable().observeOn( queue ),
                       source5.map { $0 as Any }.asObservable().observeOn( queue )]
        
        combineSources.append( RECombineSource<Entity>( sources: sources, combine: { (e, a) in merge( e, a[0] as! T0, a[1] as! T1, a[2] as! T2, a[3] as! T3, a[4] as! T4, a[5] as! T5 ) } ) )
        BuildCombines()
    }
    
    override func RxRequestForCombine( source: String = "", entity: Entity ) -> Single<Entity>
    {
        assert( queue.operationQueue == OperationQueue.current, "RxRequestForCombine can be called only from the specified in the constructor OperationQueue" )
        
        var obs = Observable.just( entity )
        combineSources.forEach {
            ms in
            switch ms.sources.count
            {
            case 1:
                obs = Observable.combineLatest( obs, ms.sources[0], resultSelector: { ms.combine( $0, [$1] ).0 } )
            case 2:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], resultSelector: { ms.combine( $0, [$1, $2] ).0 } )
            case 3:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], resultSelector: { ms.combine( $0, [$1, $2, $3] ).0 } )
            case 4:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], resultSelector: { ms.combine( $0, [$1, $2, $3, $4] ).0 } )
            case 5:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], ms.sources[4], resultSelector: { ms.combine( $0, [$1, $2, $3, $4, $5] ).0 } )
            case 6:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], ms.sources[4], ms.sources[6], resultSelector: { ms.combine( $0, [$1, $2, $3, $4, $5, $6] ).0 } )
            default:
                assert( false, "Unsupported number of the sources" )
            }
        }
        
        return obs
            .take( 1 )
            .do( onNext: { self.Update( source: source, entity: $0 ) }, onCompleted: { print( "COMPLETE" ) } )
            .asSingle()
    }
    
    override func RxRequestForCombine( source: String = "", entities: [Entity] ) -> Single<[Entity]>
    {
        assert( queue.operationQueue == OperationQueue.current, "RxRequestForCombine can be called only from the specified in the constructor OperationQueue" )
        
        var obs = Observable.just( entities )
        combineSources.forEach {
            ms in
            switch ms.sources.count
            {
            case 1:
                obs = Observable.combineLatest( obs, ms.sources[0], resultSelector: { (es, t0) in es.map { ms.combine( $0, [t0] ).0 } } )
            case 2:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], resultSelector: { (es, t0, t1) in es.map { ms.combine( $0, [t0, t1] ).0 } } )
            case 3:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], resultSelector: { (es, t0, t1, t2) in es.map { ms.combine( $0, [t0, t1, t2] ).0 } } )
            case 4:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], resultSelector: { (es, t0, t1, t2, t3) in es.map { ms.combine( $0, [t0, t1, t2, t3] ).0 } } )
            case 5:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], ms.sources[4], resultSelector: { (es, t0, t1, t2, t3, t4) in es.map { ms.combine( $0, [t0, t1, t2, t3, t4] ).0 } } )
            case 6:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], ms.sources[4], ms.sources[5], resultSelector: { (es, t0, t1, t2, t3, t4, t5) in es.map { ms.combine( $0, [t0, t1, t2, t3, t4, t5] ).0 } } )
            default:
                assert( false, "Unsupported number of the sources" )
            }
        }
        
        return obs
            .take( 1 )
            .do( onNext: { self.Update( source: source, entities: $0 ) }, onCompleted: { print( "COMPLETE" ) } )
            .asSingle()
    }
    
    func BuildCombines()
    {
        var obs: Observable<[(combine: CombineMethod<Entity>, values: [Any])]>! = Observable.just( [] ).observeOn( queue )
        combineSources.forEach {
            ms in
            switch ms.sources.count
            {
            case 1:
                obs = Observable.combineLatest( obs, ms.sources[0], resultSelector: { (arr, t0) in  arr + [(ms.combine, [t0])] } )
            case 2:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], resultSelector: { (arr, t0, t1) in arr + [(ms.combine, [t0, t1])] } )
            case 3:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], resultSelector: { (arr, t0, t1, t2) in arr + [(ms.combine, [t0, t1, t2])] } )
            case 4:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], resultSelector: { (arr, t0, t1, t2, t3) in arr + [(ms.combine, [t0, t1, t2, t3])] } )
            case 5:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], ms.sources[4], resultSelector: { (arr, t0, t1, t2, t3, t4) in arr + [(ms.combine, [t0, t1, t2, t3, t4])] } )
            case 6:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], ms.sources[4], ms.sources[5], resultSelector: { (arr, t0, t1, t2, t3, t4, t5) in arr + [(ms.combine, [t0, t1, t2, t3, t4, t5])] } )
            default:
                assert( false, "Unsupported number of the sources" )
            }
        }
        
        combineDisp?.dispose()
        weak var _self = self
        combineDisp = obs
            .subscribe( onNext: { _self?.ApplyCombines( combines: $0 ) } )
    }
    
    func ApplyCombines( combines: [(combine: CombineMethod<Entity>, values: [Any])] )
    {
        lock.lock()
        defer { lock.unlock() }
        
        var toUpdate = [REEntityKey: Entity]()
        sharedEntities.keys.forEach {
            var e = sharedEntities[$0]!
            var updated = false
            e = combines.reduce( e ) {
                let r = $1.combine( $0, $1.values )
                updated = updated || r.1
                return r.0
            }
            
            if updated
            {
                sharedEntities[$0] = e
                toUpdate[$0] = e
            }
        }
        
        items.forEach { $0.ref?.Update( source: "", entities: toUpdate ) }
    }
    
    //MARK: - Commit
    override func Commit( entity: Entity, operation: REUpdateOperation = .update )
    {
        lock.lock()
        defer { lock.unlock() }
        
        sharedEntities[entity._key] = entity
        items.forEach { $0.ref?.Update( entity: entity, operation: operation ) }
    }
    /*
    override func Commit( key: REEntityKey, operation: REUpdateOperation )
    {
        weak var _self = self
        if singleFetchCallback != nil
        {
            singleFetchCallback!( RESingleParams<Entity, REEntityExtraParamsEmpty, CollectionExtra>( key: key, lastEntity: nil ) )
                .observeOn( queue )
                .subscribe( onSuccess:
                {
                    if let e = $0
                    {
                        _self?.Commit( entity: e, operation: operation )
                    }
                }, onError: { _ in } )
                .disposed( by: dispBag )
        }
        else if singleFetchBackCallback != nil
        {
            
        }
        else
        {
            precondition( false, "To create Single with key you must specify singleFetchCallback or singleFetchBackCallback before" )
        }
    }
    */
    override func Commit( key: REEntityKey, changes: (Entity) -> Entity )
    {
        lock.lock()
        defer { lock.unlock() }
        
        if let e = sharedEntities[key]
        {
            let new = changes( e )
            sharedEntities[key] = new
            items.forEach { $0.ref?.Update( entity: new, operation: .update ) }
        }
    }
    
    override func Commit( entities: [Entity], operation: REUpdateOperation = .update )
    {
        lock.lock()
        defer { lock.unlock() }
        
        var forUpdate = [REEntityKey: Entity]()
        entities.forEach
        {
            if let _ = sharedEntities[$0._key]
            {
                forUpdate[$0._key] = $0
            }
            
            sharedEntities[$0._key] = $0
        }
        
        items.forEach { $0.ref?.Update( entities: forUpdate, operation: operation ) }
    }
    
    override func Commit( entities: [Entity], operations: [REUpdateOperation] )
    {
        lock.lock()
        defer { lock.unlock() }
        
        var forUpdate = [REEntityKey: Entity]()
        var operationUpdate = [REEntityKey: REUpdateOperation]()
        entities.enumerated().forEach
        {
            if let _ = sharedEntities[$1._key]
            {
                forUpdate[$1._key] = $1
            }
            
            operationUpdate[$1._key] = operations[$0]
            sharedEntities[$1._key] = $1
        }
        
        items.forEach { $0.ref?.Update( entities: forUpdate, operations: operationUpdate ) }
    }
    
    override func Commit( keys: [REEntityKey], operation: REUpdateOperation = .update )
    {
        fatalError( "This method must be overridden" )
    }
    
    override func Commit( keys: [REEntityKey], operations: [REUpdateOperation] )
    {
        fatalError( "This method must be overridden" )
    }
    
    override func Commit( keys: [REEntityKey], changes: (Entity) -> Entity )
    {
        lock.lock()
        defer { lock.unlock() }
        
        var forUpdate = [REEntityKey: Entity]()
        keys.forEach
        {
            if let e = sharedEntities[$0]
            {
                let new = changes( e )
                sharedEntities[$0] = new
                forUpdate[$0] = new
            }
        }
        
        items.forEach { $0.ref?.Update( entities: forUpdate, operation: .update ) }
    }
    

    //MARK: - Updates
    public func RxRequestForUpdate( source: String = "", key: REEntityKey, update: @escaping (Entity) -> Entity ) -> Single<Entity?>
    {
        return Single.create
            {
                [weak self] in
                
                if let entity = self?.sharedEntities[key]
                {
                    let new = update( entity )
                    self?.Update( source: source, entity: update( entity ) )
                    $0( .success( new ) )
                }
                else
                {
                    $0( .success( nil ) )
                }
                
                return Disposables.create()
            }
            .observeOn( queue )
            .subscribeOn( queue )
    }
    
    public func RxRequestForUpdate( source: String = "", keys: [REEntityKey], update: @escaping (Entity) -> Entity ) -> Single<[Entity]>
    {
        return Single.create
            {
                [weak self] in
                
                var updArr = [Entity](), updMap = [REEntityKey: Entity]()
                keys.forEach
                {
                    if let entity = self?.sharedEntities[$0]
                    {
                        let new = update( entity )
                        self?.sharedEntities[$0] = new
                        updArr.append( new )
                        updMap[$0] = new
                    }
                }
                
                self?.items.forEach { $0.ref?.Update( source: source, entities: updMap ) }
                $0( .success( updArr ) )
                return Disposables.create()
            }
            .observeOn( queue )
            .subscribeOn( queue )
    }
    
    public func RxRequestForUpdate( source: String = "", update: @escaping (Entity) -> Entity ) -> Single<[Entity]>
    {
        return RxRequestForUpdate( source: source, keys: sharedEntities.keys.map { $0 }, update: update )
    }
    
    public func RxRequestForUpdate<EntityS: REEntity>( source: String = "", entities: [REEntityKey: EntityS], underPathes: [KeyPath<Entity, REEntity>], update: @escaping (Entity, EntityS) -> Entity ) -> Single<[Entity]>
    {
        return Single.create
            {
                [weak self] in
                
                var updArr = [Entity](), updMap = [REEntityKey: Entity]()
                let Update: (Entity, EntityS) -> Void = {
                    let new = update( $0, $1 )
                    self?.sharedEntities[$0._key] = new
                    updArr.append( new )
                    updMap[$0._key] = new
                }
                self?.sharedEntities.forEach
                {
                    e0 in
                    
                    underPathes.forEach
                    {
                        if let v = e0.value[keyPath: $0] as? EntityS, let es = entities[v._key]
                        {
                            Update( e0.value, es )
                        }
                        else if let arr = e0.value[keyPath: $0] as? [EntityS]
                        {
                            arr.forEach
                            {
                                e1 in
                                if let es = entities[e1._key]
                                {
                                    Update( e0.value, es )
                                }
                            }
                        }
                    }
                }
                
                self?.items.forEach { $0.ref?.Update( source: source, entities: updMap ) }
                $0( .success( updArr ) )
                return Disposables.create()
            }
            .observeOn( queue )
            .subscribeOn( queue )
    }
    
    public func DispatchUpdates<EntityS: REEntity>( to: REEntityObservableCollectionExtra, withPathes: [KeyPath<EntityS, REEntity>] )
    {
        
    }
    
    public func DispatchUpdates<V>( to: REEntityObservableCollectionExtra, fromPathes: [KeyPath<Entity, V>], apply: (V) -> Entity )
    {
        
    }
    
    public func Refresh( resetCache: Bool = false, collectionExtra: CollectionExtra? = nil )
    {
        Single<Bool>.create
            {
                [weak self] in
                
                self?._Refresh( resetCache: resetCache, collectionExtra: collectionExtra )
                $0( .success( true ) )
                
                return Disposables.create()
            }
            .subscribeOn( queue )
            .observeOn( queue )
            .subscribe()
            .disposed( by: dispBag )
    }
    
    func _Refresh( resetCache: Bool = false, collectionExtra: CollectionExtra? = nil )
    {
        assert( queue.operationQueue == OperationQueue.current, "_Refresh can be called only from the specified in the constructor OperationQueue" )
        self.collectionExtra = collectionExtra ?? self.collectionExtra
        items.forEach { $0.ref?.RefreshData( resetCache: resetCache, data: self.collectionExtra ) }
    }
}
/*
public class ERZoombieRepostory<Entity: REEntity>: RERepository
{
    public typealias E = Entity
    
    public func RxGet( key: REEntityKey ) -> Single<Entity?>
    {
        return Single.just( nil )
    }
    
    public func RxGet( keys: REEntityKey ) -> Single<[Entity]>
    {
        return Single.just( [] )
    }
}
*/
public typealias REEntityObservableCollection<Entity: REEntity> = REEntityObservableCollectionExtra<Entity, REEntityCollectionExtraParamsEmpty>

//public typealias REEntityObservableCollectionExtra<Entity: REEntity, CollectionExtra> = REEntityObservableCollectionExtraRepository<Entity, CollectionExtra, ERZoombieRepostory<Entity>>

extension ObservableType
{
    public func bind<Entity: REEntity>( refresh: REEntityObservableCollectionExtra<Entity, Element>, resetCache: Bool = false ) -> Disposable
    {
        return observeOn( refresh.queue )
            .subscribe( onNext: { refresh._Refresh( resetCache: resetCache, collectionExtra: $0 ) } )
    }
}
