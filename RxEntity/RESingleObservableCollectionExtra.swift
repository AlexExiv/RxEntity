//
//  RESingleObservableService.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 10/02/2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

public struct RESingleParams<Entity: REEntity, Extra, CollectionExtra>
{
    public let refreshing: Bool
    public let resetCache: Bool
    public let first: Bool
    public let key: REEntityKey?
    public let lastEntity: Entity?
    public let extra: Extra?
    public let collectionExtra: CollectionExtra?
    
    init( refreshing: Bool = false, resetCache: Bool = false, first: Bool = false, key: REEntityKey?, lastEntity: Entity?, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        self.refreshing = refreshing
        self.resetCache = resetCache
        self.first = first
        self.key = key
        self.lastEntity = lastEntity
        self.extra = extra
        self.collectionExtra = collectionExtra
    }
}

public class RESingleObservableCollectionExtra<Entity: REEntity, Extra, CollectionExtra>: RESingleObservableExtra<Entity, Extra>
{
    public typealias SingleFetchCallback = (RESingleParams<Entity, Extra, CollectionExtra>) -> Single<Entity>
    
    let rxMiddleware = BehaviorRelay<Entity?>( value: nil )
    let _rxRefresh = PublishRelay<RESingleParams<Entity, Extra, CollectionExtra>>()
    public private(set) var collectionExtra: CollectionExtra? = nil
    var started = false

    init( holder: REEntityCollection<Entity>, key: REEntityKey? = nil, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, start: Bool = true, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>], fetch: @escaping SingleFetchCallback )
    {
        self.collectionExtra = collectionExtra
        
        super.init( holder: holder, key: key, extra: extra, observeOn: observeOn, combineSources: combineSources )
        
        weak var _self = self
        var obs = _rxRefresh
            .do( onNext: { _ in _self?.rxLoader.accept( true ) } )
            .flatMapLatest
            {
                fetch( $0 )
                    .asObservable()
                    .catchError
                    {
                        e -> Observable<Entity> in
                        _self?.rxError.accept( e )
                        _self?.rxLoader.accept( false )
                        return Observable.empty()
                    }
            }
            .do( onNext: { _self?.Set( key: $0.key ) } )
            .do( onNext: { _ in _self?.rxLoader.accept( false ) } )
            .flatMapLatest { _self?.collection?.RxUpdate( entity: $0 ).asObservable() ?? Observable.empty() }
            .observeOn( observeOn )
        
        obs
            .bind( to: rxMiddleware )
            .disposed( by: dispBag )
        
        obs = rxMiddleware.filter { $0 != nil }.map { $0! }
        combineSources.forEach {
            ms in
            switch ms.sources.count
            {
            case 1:
                obs = Observable.combineLatest( obs, ms.sources[0], resultSelector: { ms.combine( $0, [$1] ) } )
            case 2:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], resultSelector: { ms.combine( $0, [$1, $2] ) } )
            case 3:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], resultSelector: { ms.combine( $0, [$1, $2, $3] ) } )
            case 4:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], resultSelector: { ms.combine( $0, [$1, $2, $3, $4] ) } )
            case 5:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], ms.sources[4], resultSelector: { ms.combine( $0, [$1, $2, $3, $4, $5] ) } )
            case 6:
                obs = Observable.combineLatest( obs, ms.sources[0], ms.sources[1], ms.sources[2], ms.sources[3], ms.sources[4], ms.sources[6], resultSelector: { ms.combine( $0, [$1, $2, $3, $4, $5, $6] ) } )
            default:
                assert( false, "Unsupported number of the sources" )
            }
        }
        
        obs
            .bind( to: rxPublish )
            .disposed( by: dispBag )
        
        if start
        {
            started = true
            _rxRefresh.accept( RESingleParams( first: true, key: key, lastEntity: entity, extra: extra, collectionExtra: collectionExtra ) )
        }
    }
    
    convenience init( holder: REEntityCollection<Entity>, initial: Entity, refresh: Bool, collectionExtra: CollectionExtra? = nil, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>], fetch: @escaping SingleFetchCallback )
    {
        self.init( holder: holder, key: initial.key, collectionExtra: collectionExtra, start: false, observeOn: observeOn, combineSources: combineSources, fetch: fetch )
        rxPublish.onNext( initial )
        started = !refresh
    }
    
    override func _Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        _CollectionRefresh( resetCache: resetCache, extra: extra )
    }
    
    override func RefreshData( resetCache: Bool, data: Any? )
    {
        _CollectionRefresh( resetCache: resetCache, collectionExtra: data as? CollectionExtra )
    }
    
    func CollectionRefresh( resetCache: Bool = false, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        Single<Bool>.create
            {
                [weak self] in
                
                self?._CollectionRefresh( resetCache: resetCache, extra: extra, collectionExtra: collectionExtra )
                $0( .success( true ) )
                
                return Disposables.create()
            }
            .subscribeOn( queue )
            .observeOn( queue )
            .subscribe()
            .disposed( by: dispBag )
    }
    
    public override func Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        CollectionRefresh( resetCache: resetCache, extra: extra )
    }
    
    func _CollectionRefresh( resetCache: Bool = false, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        assert( queue.operationQueue == OperationQueue.current, "_Refresh can be updated only from the specified in the constructor OperationQueue" )
        
        super._Refresh( resetCache: resetCache, extra: extra )
        self.collectionExtra = collectionExtra ?? self.collectionExtra
        _rxRefresh.accept( RESingleParams( refreshing: true, resetCache: resetCache, first: !started, key: key, lastEntity: entity, extra: self.extra, collectionExtra: self.collectionExtra ) )
        started = true
    }
}
