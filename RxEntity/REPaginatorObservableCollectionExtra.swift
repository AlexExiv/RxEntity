//
//  REPaginatorObservableCollectionExtra.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 10/02/2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

public let PAGINATOR_END = -1000

public struct REPageParams<Extra, CollectionExtra>
{
    public let page: Int
    public let perPage: Int
    public let refreshing: Bool
    public let resetCache: Bool
    public let first: Bool
    public let keys: [REEntityKey]
    public let extra: Extra?
    public let collectionExtra: CollectionExtra?
    
    init( page: Int, perPage: Int, refreshing: Bool = false, resetCache: Bool = false, first: Bool = false, keys: [REEntityKey], extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        self.page = page
        self.perPage = perPage
        self.refreshing = refreshing
        self.resetCache = resetCache
        self.first = first
        self.keys = keys
        self.extra = extra
        self.collectionExtra = collectionExtra
    }
}

public class REPaginatorObservableCollectionExtra<Entity: REEntity, Extra, CollectionExtra>: REPaginatorObservableExtra<Entity, Extra>
{
    public typealias Element = [Entity]
    public typealias PageFetchCallback<Extra, CollectionExtra> = (REPageParams<Extra, CollectionExtra>) -> Single<[Entity]>
    public typealias PageFetchBackCallback<Extra, CollectionExtra> = (REPageParams<Extra, CollectionExtra>) -> Single<[REBackEntityProtocol]>
    
    let rxMiddleware = BehaviorRelay<Element?>( value: nil )
    let rxPage = PublishRelay<REPageParams<Extra, CollectionExtra>>()

    public private(set) var collectionExtra: CollectionExtra? = nil
    var started = false
      
    init( holder: REEntityCollection<Entity>, keys: [REEntityKey] = [], extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, perPage: Int = 35, start: Bool = true, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>], fetch: @escaping PageFetchCallback<Extra, CollectionExtra> )
    {
        self.collectionExtra = collectionExtra
        super.init( holder: holder, keys: keys, extra: extra, perPage: perPage, observeOn: observeOn, combineSources: combineSources )
        
        weak var _self = self
        var obs = rxPage
            .filter { $0.page >= 0 }
            .do( onNext: { _self?.rxLoader.accept( $0.first ? .firstLoading : .loading ) } )
            .flatMapLatest( {
                fetch( $0 )
                    .asObservable()
                    .do( onNext: { _self?.Set( keys: $0.map { $0._key } ) } )
                    .catchError
                    {
                        _self?.rxError.accept( $0 )
                        _self?.rxLoader.accept( .none )
                        return Observable.just( [] )
                    }
            } )
            .flatMap( { _self?.collection?.RxUpdate( source: _self?.uuid ?? "", entities: $0 ) ?? Single.just( [] ) } )
            .observeOn( observeOn )
            .map( { _self?.Append( entities: $0 ) ?? [] } )
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
            started = true
            rxPage.accept( REPageParams( page: 0, perPage: perPage, first: true, keys: keys, extra: extra, collectionExtra: collectionExtra ) )
        }
    }
    
    convenience init( holder: REEntityCollection<Entity>, initial: [Entity], collectionExtra: CollectionExtra? = nil, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>], fetch: @escaping PageFetchCallback<Extra, CollectionExtra> )
    {
        self.init( holder: holder, keys: initial.map { $0._key }, collectionExtra: collectionExtra, start: false, observeOn: observeOn, combineSources: combineSources, fetch: fetch )
        rxMiddleware.accept( initial )
        started = true
    }
    
    convenience init( holder: REEntityCollection<Entity>, keys: [REEntityKey] = [], extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, perPage: Int = 35, start: Bool = true, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>], fetch: @escaping PageFetchBackCallback<Extra, CollectionExtra> )
    {
        self.init( holder: holder, keys: keys, extra: extra, collectionExtra: collectionExtra, perPage: perPage, start: start, observeOn: observeOn, combineSources: combineSources, fetch: { fetch( $0 ).map { $0.map { Entity( entity: $0 ) } } } )
    }
    
    convenience init( holder: REEntityCollection<Entity>, initial: [Entity], collectionExtra: CollectionExtra? = nil, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>], fetch: @escaping PageFetchBackCallback<Extra, CollectionExtra> )
    {
        self.init( holder: holder, initial: initial, collectionExtra: collectionExtra, observeOn: observeOn, combineSources: combineSources, fetch: { fetch( $0 ).map { $0.map { Entity( entity: $0 ) } } } )
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
    
    public override func Next()
    {
        if rxLoader.value == .firstLoading || rxLoader.value == .loading
        {
            return
        }
        
        if started
        {
            rxPage.accept( REPageParams( page: page + 1, perPage: perPage, keys: keys, extra: extra, collectionExtra: collectionExtra ) )
        }
        else
        {
            Refresh()
        }
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
        rxPage.accept( REPageParams( page: page + 1, perPage: perPage, refreshing: true, resetCache: resetCache, first: !started, keys: keys, extra: self.extra, collectionExtra: self.collectionExtra ) )
        started = true
    }
}
