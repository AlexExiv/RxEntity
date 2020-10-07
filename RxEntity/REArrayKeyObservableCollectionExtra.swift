//
//  REKeyArrayObservableCollectionExtra.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 07.10.2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation

import RxSwift
import RxRelay
import RxCocoa

public struct REKeyParams<Extra, CollectionExtra>
{
    public let refreshing: Bool
    public let resetCache: Bool
    public let first: Bool
    public let keys: [REEntityKey]
    public let extra: Extra?
    public let collectionExtra: CollectionExtra?
    
    init( refreshing: Bool = false, resetCache: Bool = false, first: Bool = false, keys: [REEntityKey], extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        self.refreshing = refreshing
        self.resetCache = resetCache
        self.first = first
        self.keys = keys
        self.extra = extra
        self.collectionExtra = collectionExtra
    }
}

public class REKeyArrayObservableCollectionExtra<Entity: REEntity, Extra, CollectionExtra>: REKeyArrayObservableExtra<Entity, Extra>
{
    public typealias Element = [Entity]
    public typealias ArrayFetchCallback<Extra, CollectionExtra> = (REKeyParams<Extra, CollectionExtra>) -> Single<[Entity]>
    public typealias ArrayFetchBackCallback<Extra, CollectionExtra> = (REKeyParams<Extra, CollectionExtra>) -> Single<[REBackEntityProtocol]>
    
    let rxMiddleware = BehaviorRelay<Element?>( value: nil )
    let rxKeys = PublishRelay<REKeyParams<Extra, CollectionExtra>>()

    public private(set) var collectionExtra: CollectionExtra? = nil
      
    init( holder: REEntityCollection<Entity>, keys: [REEntityKey] = [], start: Bool = true, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>], fetch: @escaping ArrayFetchCallback<Extra, CollectionExtra> )
    {
        self.collectionExtra = collectionExtra
        super.init( holder: holder, keys: keys, extra: extra, observeOn: observeOn, combineSources: combineSources )
        
        weak var _self = self
        var obs = rxKeys
            .filter { $0.keys.count > 0 }
            .do( onNext: { _self?.rxLoader.accept( $0.first ? .firstLoading : .loading ) } )
            .observeOn( queue )
            .flatMapLatest( {
                (_self?.RxFetchElements( params: $0, fetch: fetch ) ?? Single.just( [] ))
                    .asObservable()
                    .catchError
                    {
                        _self?.rxError.accept( $0 )
                        _self?.rxLoader.accept( .none )
                        return Observable.just( [] )
                    }
            } )
            .flatMap( { _self?.collection?.RxUpdate( source: _self?.uuid ?? "", entities: $0 ) ?? Single.just( [] ) } )
            .observeOn( observeOn )
            .do( onNext: { _ in _self?.rxLoader.accept( .none ) } )
        
        obs
            .bind( to: rxMiddleware )
            .disposed( by: dispBag )
        
        obs = rxMiddleware.filter { $0 != nil }.map { $0! }
        combineSources.forEach {
            ms in
            switch ms.sources.count
            {
            case 1:
                obs = Observable.combineLatest( obs, ms.sources[0], resultSelector: { (es, t0) in es.map { ms.combine( $0, [t0] ) } } )
            case 2:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], resultSelector: { (es, t0, t1) in es.map { ms.combine( $0, [t0, t1] ) } } )
            case 3:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], resultSelector: { (es, t0, t1, t2) in es.map { ms.combine( $0, [t0, t1, t2] ) } } )
            case 4:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], resultSelector: { (es, t0, t1, t2, t3) in es.map { ms.combine( $0, [t0, t1, t2, t3] ) } } )
            case 5:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], ms.sources[4], resultSelector: { (es, t0, t1, t2, t3, t4) in es.map { ms.combine( $0, [t0, t1, t2, t3, t4] ) } } )
            case 6:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], ms.sources[4], ms.sources[5], resultSelector: { (es, t0, t1, t2, t3, t4, t5) in es.map { ms.combine( $0, [t0, t1, t2, t3, t4, t5] ) } } )
            default:
                assert( false, "Unsupported number of the sources" )
            }
        }
        
        obs
            .subscribe( onNext: { _self?.Set( entities: $0 ) } )
            .disposed( by: dispBag )
        
        if start
        {
            rxKeys.accept( REKeyParams( first: true, keys: keys, extra: extra, collectionExtra: collectionExtra ) )
        }
    }
    
    convenience init( holder: REEntityCollection<Entity>, initial: [Entity], collectionExtra: CollectionExtra? = nil, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>], fetch: @escaping ArrayFetchCallback<Extra, CollectionExtra> )
    {
        self.init( holder: holder, keys: initial.map { $0._key }, start: false, collectionExtra: collectionExtra, observeOn: observeOn, combineSources: combineSources, fetch: fetch )
        rxMiddleware.accept( initial )
    }
    
    convenience init( holder: REEntityCollection<Entity>, keys: [REEntityKey] = [], extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>], fetch: @escaping ArrayFetchBackCallback<Extra, CollectionExtra> )
    {
        self.init( holder: holder, keys: keys, extra: extra, collectionExtra: collectionExtra, observeOn: observeOn, combineSources: combineSources, fetch: { fetch( $0 ).map { $0.map { Entity( entity: $0 ) } } } )
    }
    
    convenience init( holder: REEntityCollection<Entity>, initial: [Entity], collectionExtra: CollectionExtra? = nil, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>], fetch: @escaping ArrayFetchBackCallback<Extra, CollectionExtra> )
    {
        self.init( holder: holder, initial: initial, collectionExtra: collectionExtra, observeOn: observeOn, combineSources: combineSources, fetch: { fetch( $0 ).map { $0.map { Entity( entity: $0 ) } } } )
    }
    
    override func Set( keys: [REEntityKey] )
    {
        lock.lock()
        defer { lock.unlock() }
        
        super.Set( keys: keys )
        rxKeys.accept( REKeyParams( keys: keys, extra: extra, collectionExtra: collectionExtra ) )
    }
    
    public override func Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        CollectionRefresh( resetCache: resetCache, extra: extra )
    }
    
    override func _Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        _CollectionRefresh( resetCache: resetCache, extra: extra )
    }

    override func RefreshData( resetCache: Bool, data: Any? )
    {
        _CollectionRefresh( resetCache: resetCache, collectionExtra: data as? CollectionExtra )
    }
    

    func CombineSources( combine: CombineMethod<Entity>, values: Any... )
    {
        lock.lock()
        defer { lock.unlock() }
        
        let _entities = entities.map { combine( $0, values ) }
        Set( entities: _entities )
    }
    /*
    func CombineSources( entities: [Entity], combine: CombineMethod<Entity>, values: Any... ) -> [Entity]
    {
        lock.lock()
        defer { lock.unlock() }
        
        let _entities = entities.map { combine( $0, values ) }
        Set( entities: _entities )
    }*/
    
    
    //MARK: - Collection
    func CollectionRefresh( resetCache: Bool = false, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        Single<Bool>.create
            {
                [weak self] in
                
                self?._CollectionRefresh( resetCache: resetCache, extra: extra, collectionExtra: collectionExtra )
                $0( .success( true ) )
                return Disposables.create()
            }
            .observeOn( queue )
            .subscribeOn( queue )
            .subscribe()
            .disposed( by: dispBag )
    }
    
    func _CollectionRefresh( resetCache: Bool = false, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        assert( queue.operationQueue == OperationQueue.current, "_Refresh can be updated only from the specified in the constructor OperationQueue" )
        
        super._Refresh( resetCache: resetCache, extra: extra )
        self.collectionExtra = collectionExtra ?? self.collectionExtra
        rxKeys.accept( REKeyParams( refreshing: true, resetCache: resetCache, keys: keys, extra: self.extra, collectionExtra: self.collectionExtra ) )
    }
    
    //MARK: - Fetch
    private func RxFetchElements( params: REKeyParams<Extra, CollectionExtra>, fetch: @escaping ArrayFetchCallback<Extra, CollectionExtra> ) -> Single<[Entity]>
    {
        assert( queue.operationQueue == OperationQueue.current, "RxFetchElements can be called only from the specified in the constructor OperationQueue" )
        
        if params.refreshing
        {
            return fetch( params )
        }
        
        let exist = params.keys.compactMap { collection?.sharedEntities[$0] }
        if exist.count != keys.count
        {
            let _params = REKeyParams( refreshing: params.refreshing, resetCache: params.resetCache, first: params.first, keys: params.keys.filter { collection?.sharedEntities[$0] == nil }, extra: extra, collectionExtra: collectionExtra )
            return Observable
                .zip( Observable.just( exist ), fetch( _params ).asObservable() )
                .asSingle()
                .map
                {
                    let exist = $0.0.asEntitiesMap()
                    let new = $0.1.asEntitiesMap()
                    print( "KeyArray exist: \(exist.count); new: \(new.count)" )
                    return params.keys.compactMap { exist[$0] ?? new[$0] }
                }
        }
        
        return Single.just( exist )
    }
}
