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

public struct RESingleParams<Extra, CollectionExtra>
{
    public let refreshing: Bool
    public let resetCache: Bool
    public let first: Bool
    public let extra: Extra?
    public let collectionExtra: CollectionExtra?
    
    init( refreshing: Bool = false, resetCache: Bool = false, first: Bool = false, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        self.refreshing = refreshing
        self.resetCache = resetCache
        self.first = first
        self.extra = extra
        self.collectionExtra = collectionExtra
    }
}

public class RESingleObservableCollectionExtra<Entity: REEntity, Extra, CollectionExtra>: RESingleObservableExtra<Entity, Extra>
{
    let _rxRefresh = PublishRelay<RESingleParams<Extra, CollectionExtra>>()
    public private(set) var collectionExtra: CollectionExtra? = nil
    var started = false

    init( holder: REEntityCollection<Entity>, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, start: Bool = true, observeOn: OperationQueueScheduler, fetch: @escaping (RESingleParams<Extra, CollectionExtra>) -> Single<Entity> )
    {
        self.collectionExtra = collectionExtra
        
        super.init( holder: holder, extra: extra, observeOn: observeOn )
        
        weak var _self = self
        _rxRefresh
            .do( onNext: { _ in _self?.rxLoader.accept( true ) } )
            .flatMapLatest { fetch( $0 ) }
            .catchError
            {
                e -> Observable<Entity> in
                _self?.rxError.accept( e )
                _self?.rxLoader.accept( false )
                return Observable.empty()
            }
            .do( onNext: { _ in _self?.rxLoader.accept( false ) } )
            .flatMapLatest { _self?.collection?.RxUpdate( entity: $0 ).asObservable() ?? Observable.empty() }
            .observeOn( observeOn )
            .bind( to: rxPublish )
            .disposed( by: dispBag )
        
        if start
        {
            started = true
            _rxRefresh.accept( RESingleParams( first: true, extra: extra, collectionExtra: collectionExtra ) )
        }
    }
    
    override func Update( source: String, entity: Entity )
    {
        assert( queue.operationQueue == OperationQueue.current, "Single observable can be updated only from the same queue with the parent collection" )
        
        if let key = self.entity?.key, key == entity.key, source != uuid
        {
            rxPublish.onNext( entity )
        }
    }
    
    override func Update( source: String, entities: [REEntityKey: Entity] )
    {
        assert( queue.operationQueue == OperationQueue.current, "Single observable can be updated only from the same queue with the parent collection" )
        
        if let key = entity?.key, let entity = entities[key], source != uuid
        {
            rxPublish.onNext( entity )
        }
    }
    
    public func CollectionRefresh( resetCache: Bool = false, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
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
    
    public func _CollectionRefresh( resetCache: Bool = false, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        assert( queue.operationQueue == OperationQueue.current, "_Refresh can be updated only from the specified in the constructor OperationQueue" )
        
        super._Refresh( resetCache: resetCache, extra: extra )
        self.collectionExtra = collectionExtra ?? self.collectionExtra
        _rxRefresh.accept( RESingleParams( refreshing: true, resetCache: resetCache, first: !started, extra: self.extra, collectionExtra: self.collectionExtra ) )
        started = true
    }
    
    override func _Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        _CollectionRefresh( resetCache: resetCache, extra: extra )
    }
    
    public func CollectionRefreshData( resetCache: Bool, collectionExtra: CollectionExtra )
    {
        _CollectionRefresh( resetCache: resetCache, collectionExtra: collectionExtra )
    }
    
    override func RefreshData( resetCache: Bool, data: Any )
    {
        CollectionRefreshData( resetCache: resetCache, collectionExtra: data as! CollectionExtra )
    }
}
