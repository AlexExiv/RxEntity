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

struct RECombineSource<E>
{
    let sources: [Observable<Any>]
    let combine: (E, Array<Any>) -> E
}

public class REEntityObservableCollectionExtra<Entity: REEntity, CollectionExtra>: REEntityCollection<Entity>
{
    public typealias SingleFetchBackCallback = RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>.SingleFetchBackCallback
    public typealias SingleExtraFetchBackCallback<Extra> = RESingleObservableCollectionExtra<Entity, Extra, CollectionExtra>.SingleFetchBackCallback
    
    public typealias SingleFetchCallback = RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>.SingleFetchCallback
    public typealias SingleExtraFetchCallback<Extra> = RESingleObservableCollectionExtra<Entity, Extra, CollectionExtra>.SingleFetchCallback
    
    public typealias PageFetchCallback = REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>.PageFetchCallback<REEntityExtraParamsEmpty, CollectionExtra>
    public typealias PageExtraFetchCallback<Extra> = REPaginatorObservableCollectionExtra<Entity, Extra, CollectionExtra>.PageFetchCallback<Extra, CollectionExtra>
    
    public var singleFetchBackCallback: SingleFetchBackCallback? = nil
    public var singleFetchCallback: SingleFetchCallback? = nil
    public var arrayFetchCallback: PageFetchCallback? = nil
    
    public private(set) var collectionExtra: CollectionExtra? = nil
    private(set) var combineSources = [RECombineSource<Entity>]()
        
    public convenience init( operationQueue: OperationQueue, collectionExtra: CollectionExtra? = nil )
    {
        self.init( queue: OperationQueueScheduler( operationQueue: operationQueue ), collectionExtra: collectionExtra )
    }
    
    public init( queue: OperationQueueScheduler, collectionExtra: CollectionExtra? = nil )
    {
        self.collectionExtra = collectionExtra
        super.init( queue: queue )
    }

    //MARK: - Single Observables
    public func CreateSingleBack( key: REEntityKey? = nil, start: Bool = true, _ fetch: @escaping SingleFetchBackCallback ) -> RESingleObservable<Entity>
    {
        return RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, key: key, collectionExtra: collectionExtra, start: start, observeOn: queue, combineSources: combineSources, fetch: fetch )
    }

    public func CreateSingleBackExtra<Extra>( key: REEntityKey? = nil, extra: Extra? = nil, start: Bool = true, _ fetch: @escaping SingleExtraFetchBackCallback<Extra> ) -> RESingleObservableExtra<Entity, Extra>
    {
        return RESingleObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, key: key, extra: extra, collectionExtra: collectionExtra, start: start, observeOn: queue, combineSources: combineSources, fetch: fetch )
    }
    
    public func CreateSingle( key: REEntityKey? = nil, start: Bool = true, _ fetch: @escaping SingleFetchCallback ) -> RESingleObservable<Entity>
    {
        return RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, key: key, collectionExtra: collectionExtra, start: start, observeOn: queue, combineSources: combineSources, fetch: fetch )
    }

    public func CreateSingleExtra<Extra>( key: REEntityKey? = nil, extra: Extra? = nil, start: Bool = true, _ fetch: @escaping SingleExtraFetchCallback<Extra> ) -> RESingleObservableExtra<Entity, Extra>
    {
        return RESingleObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, key: key, extra: extra, collectionExtra: collectionExtra, start: start, observeOn: queue, combineSources: combineSources, fetch: fetch )
    }
    
    public override func CreateSingle( initial: Entity, refresh: Bool = false ) -> RESingleObservable<Entity>
    {
        if singleFetchCallback != nil
        {
            return RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, initial: initial, refresh: refresh, collectionExtra: collectionExtra, observeOn: queue, combineSources: combineSources, fetch: singleFetchCallback! )
        }
        else if singleFetchBackCallback != nil
        {
            return RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, initial: initial, refresh: refresh, collectionExtra: collectionExtra, observeOn: queue, combineSources: combineSources, fetch: singleFetchBackCallback! )
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
    public override func CreateArray( initial: [Entity] ) -> REArrayObservable<Entity>
    {
        assert( arrayFetchCallback != nil, "To create Array with initial values you must specify arrayFetchCallback before" )
        return REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, initial: initial, collectionExtra: collectionExtra, observeOn: queue, combineSources: combineSources, fetch: arrayFetchCallback! )
    }
    
    public func CreateArray( keys: [REEntityKey], start: Bool = true ) -> REArrayObservable<Entity>
    {
        assert( arrayFetchCallback != nil, "To create Array with initial value you must specify arrayFetchCallback before" )
        return CreateArray( keys: keys, start: start, arrayFetchCallback! )
    }
    
    public func CreateArray( keys: [REEntityKey] = [], start: Bool = true, _ fetch: @escaping PageFetchCallback ) -> REArrayObservable<Entity>
    {
        return REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, keys: keys, collectionExtra: collectionExtra, start: start, observeOn: queue, combineSources: combineSources, fetch: fetch )
    }
    
    public func CreateArrayExtra<Extra>( keys: [REEntityKey] = [], extra: Extra? = nil, start: Bool = true, _ fetch: @escaping PageExtraFetchCallback<Extra> ) -> REArrayObservableExtra<Entity, Extra>
    {
        return REPaginatorObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, keys: keys, extra: extra, collectionExtra: collectionExtra, start: start, observeOn: queue, combineSources: combineSources, fetch: fetch )
    }
    
    //MARK: - Paginator Observables
    public func CreatePaginator( perPage: Int = 35, start: Bool = true, _ fetch: @escaping PageFetchCallback ) -> REPaginatorObservable<Entity>
    {
        return REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, collectionExtra: collectionExtra, perPage: perPage, start: start, observeOn: queue, combineSources: combineSources, fetch: fetch )
    }
    
    public func CreatePaginatorExtra<Extra>( extra: Extra? = nil, perPage: Int = 35, start: Bool = true, _ fetch: @escaping PageExtraFetchCallback<Extra> ) -> REPaginatorObservableExtra<Entity, Extra>
    {
        return REPaginatorObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, extra: extra, collectionExtra: collectionExtra, perPage: perPage, start: start, observeOn: queue, combineSources: combineSources, fetch: fetch )
    }
    
    //MARK: - Combine Latest
    func combineLatest<T>( _ source: Observable<T>, _ merge: @escaping (Entity, T) -> Entity )
    {
        combineSources.append( RECombineSource<Entity>( sources: [source.map { $0 as Any }.asObservable()], combine: { (e, a) in merge( e, a[0] as! T ) } ) )
    }

    func combineLatest<T0, T1>( _ source0: Observable<T0>, _ source1: Observable<T1>, _ merge: @escaping (Entity, T0, T1) -> Entity )
    {
        let sources = [source0.map { $0 as Any }.asObservable(),
                       source1.map { $0 as Any }.asObservable()]
        
        combineSources.append( RECombineSource<Entity>( sources: sources, combine: { (e, a) in merge( e, a[0] as! T0, a[1] as! T1 ) } ) )
    }

    func combineLatest<T0, T1, T2>( _ source0: Observable<T0>, _ source1: Observable<T1>, _ source2: Observable<T2>, _ merge: @escaping (Entity, T0, T1, T2) -> Entity )
    {
        let sources = [source0.map { $0 as Any }.asObservable(),
                       source1.map { $0 as Any }.asObservable(),
                       source2.map { $0 as Any }.asObservable()]
        
        combineSources.append( RECombineSource<Entity>( sources: sources, combine: { (e, a) in merge( e, a[0] as! T0, a[1] as! T1, a[2] as! T2 ) } ) )
    }

    func combineLatest<T0, T1, T2, T3>( _ source0: Observable<T0>, _ source1: Observable<T1>, _ source2: Observable<T2>, _ source3: Observable<T3>, _ merge: @escaping (Entity, T0, T1, T2, T3) -> Entity)
    {
        let sources = [source0.map { $0 as Any }.asObservable(),
                       source1.map { $0 as Any }.asObservable(),
                       source2.map { $0 as Any }.asObservable(),
                       source3.map { $0 as Any }.asObservable()]
        
        combineSources.append( RECombineSource<Entity>( sources: sources, combine: { (e, a) in merge( e, a[0] as! T0, a[1] as! T1, a[2] as! T2, a[3] as! T3 ) } ) )
    }

    func combineLatest<T0, T1, T2, T3, T4>( _ source0: Observable<T0>, _ source1: Observable<T1>, _ source2: Observable<T2>, _ source3: Observable<T3>, _ source4: Observable<T4>, _ merge: @escaping (Entity, T0, T1, T2, T3, T4) -> Entity)
    {
        let sources = [source0.map { $0 as Any }.asObservable(),
                       source1.map { $0 as Any }.asObservable(),
                       source2.map { $0 as Any }.asObservable(),
                       source3.map { $0 as Any }.asObservable(),
                       source4.map { $0 as Any }.asObservable()]
        
        combineSources.append( RECombineSource<Entity>( sources: sources, combine: { (e, a) in merge( e, a[0] as! T0, a[1] as! T1, a[2] as! T2, a[3] as! T3, a[4] as! T4 ) } ) )
    }

    func combineLatest<T0, T1, T2, T3, T4, T5>( _ source0: Observable<T0>, _ source1: Observable<T1>, _ source2: Observable<T2>, _ source3: Observable<T3>, _ source4: Observable<T4>, _ source5: Observable<T5>, _ merge: @escaping (Entity, T0, T1, T2, T3, T4, T5) -> Entity)
    {
        let sources = [source0.map { $0 as Any }.asObservable(),
                       source1.map { $0 as Any }.asObservable(),
                       source2.map { $0 as Any }.asObservable(),
                       source3.map { $0 as Any }.asObservable(),
                       source4.map { $0 as Any }.asObservable(),
                       source5.map { $0 as Any }.asObservable()]
        
        combineSources.append( RECombineSource<Entity>( sources: sources, combine: { (e, a) in merge( e, a[0] as! T0, a[1] as! T1, a[2] as! T2, a[3] as! T3, a[4] as! T4, a[5] as! T5 ) } ) )
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
