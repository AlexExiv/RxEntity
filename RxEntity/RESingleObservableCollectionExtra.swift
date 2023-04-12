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

public struct RESingleParams<Entity: REEntity, Extra, CollectionExtra>
{
    /// Update requested from refreshing
    public let refreshing: Bool
    public let resetCache: Bool
    /// The first loading request flag
    public let first: Bool
    /// The key of the entity
    public let key: REEntityKey?
    public let lastEntity: Entity?
    /// The observable's extra params for example filter and so on which you've passed to the `Refresh` method or its analogues of `Observable` instance
    public let extra: Extra?
    /// The collection's global extra params it maybe a region or city or so on which you've passed to the `Refresh` method or its analogues of `Collection` of observables
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

///Represents Observable that contains only one element
///- Parameters:
///- `Entity`: Type of entity
///- `Extra`: Any extra type which passes to the `fetch` closure for using during the data fetching
///- `CollectionExtra`: Any collection's extra type which passes to the `fetch` closure for using during the data fetching
public class RESingleObservableCollectionExtra<Entity: REEntity, Extra, CollectionExtra>: RESingleObservableExtra<Entity, Extra>
{
    public typealias SingleFetchBackCallback = (RESingleParams<Entity, Extra, CollectionExtra>) -> Single<REBackEntityProtocol?>
    public typealias SingleFetchCallback = (RESingleParams<Entity, Extra, CollectionExtra>) -> Single<Entity?>
    
    let _rxRefresh = BehaviorRelay<RESingleParams<Entity, Extra, CollectionExtra>?>( value: nil )
    public private(set) var collectionExtra: CollectionExtra? = nil
    var started = false
    
    public override var key: REEntityKey?
    {
        set
        {
            lock.lock()
            defer { lock.unlock() }
            super.key = newValue
            
            let params = _rxRefresh.value
            _rxRefresh.accept( RESingleParams( refreshing: true, resetCache: true, first: true, key: newValue, lastEntity: entity, extra: params?.extra, collectionExtra: params?.collectionExtra ) )
            started = true
        }
        get
        {
            super.key
        }
    }

    init( holder: REEntityCollection<Entity>, key: REEntityKey? = nil, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, start: Bool = true, observeOn: SchedulerType, fetch: @escaping SingleFetchCallback )
    {
        self.collectionExtra = collectionExtra
        
        super.init( holder: holder, key: key, extra: extra, observeOn: observeOn )
        
        weak var _self = self
        Observable
            .combineLatest( _rxRefresh, rxSuspended )
            .filter { $0.0 != nil && !$0.1 }
            .map { $0.0! }
            .do( onNext:
            {
                _self?.rxLoader.accept( $0.first ? .firstLoading : .loading )
                if $0.first
                {
                    _self?.rxState.accept( .initializing )
                }
                _self?.rxLastError.accept( nil )
            } )
            .flatMapLatest
            {
                fetch( $0 )
                    .asObservable()
                    .flatMap
                    {
                        e -> Observable<Entity?> in
                        
                        if e == nil
                        {
                            //_self?.rxState.accept( .notFound )
                            return Observable.error( NSError( domain: "", code: 404, userInfo: nil ) )
                        }
                        
                        return Observable.just( e! )
                    }
                    .catch
                    {
                        e -> Observable<Entity?> in
                        /*if (e as NSError).code == 404
                        {
                            _self?.rxState.accept( .notFound )
                        }
                        else
                        {
                            //_self?.rxError.accept( e )
                        }*/
                        _self?.rxError.accept( e )
                        _self?.rxLastError.accept( e )
                        _self?.rxLoader.accept( .none )
                        return Observable.just( nil )
                    }
            }
            .observe( on: observeOn )
            .flatMap
            {
                $0 != nil ? (_self?.collection?.RxRequestForCombine( source: _self?.uuid ?? "", entity: $0! ).map { $0 } ?? Single.just( nil )) : Single.just( nil )
            }
            .subscribe( onNext:
            {
                _self?.rxPublish.onNext( $0 )
                _self?.rxLoader.accept( .none )
                _self?.rxState.accept( $0 == nil ? .notFound : .ready )
            } )
            .disposed( by: dispBag )
        
        if start
        {
            started = true
            _rxRefresh.accept( RESingleParams( first: true, key: key, lastEntity: entity, extra: extra, collectionExtra: collectionExtra ) )
        }
    }
    
    convenience init( holder: REEntityCollection<Entity>, initial: Entity, refresh: Bool, collectionExtra: CollectionExtra? = nil, observeOn: SchedulerType, fetch: @escaping SingleFetchCallback )
    {
        self.init( holder: holder, key: initial._key, collectionExtra: collectionExtra, start: false, observeOn: observeOn, fetch: fetch )
        
        weak var _self = self
        Single.just( true )
            .observe( on: observeOn )
            .flatMap { _ in _self?.collection?.RxRequestForCombine( source: _self?.uuid ?? "", entity: initial ).map { $0 } ?? Single.just( nil ) }
            .subscribe( onSuccess:
            {
                _self?.rxPublish.onNext( $0 )
                _self?.rxState.accept( .ready )
            } )
            .disposed( by: dispBag )
        
        started = !refresh
    }
    
    convenience init( holder: REEntityCollection<Entity>, initial: Entity, refresh: Bool, collectionExtra: CollectionExtra? = nil, observeOn: SchedulerType, fetch: @escaping SingleFetchBackCallback )
    {
        self.init( holder: holder, initial: initial, refresh: refresh, collectionExtra: collectionExtra, observeOn: observeOn, fetch: { fetch( $0 ).map { $0 == nil ? nil : Entity( entity: $0! ) } } )
    }
    
    convenience init( holder: REEntityCollection<Entity>, key: REEntityKey? = nil, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, start: Bool = true, observeOn: SchedulerType,  fetch: @escaping SingleFetchBackCallback )
    {
        self.init( holder: holder, key: key, extra: extra, collectionExtra: collectionExtra, start: start, observeOn: observeOn, fetch: { fetch( $0 ).map { $0 == nil ? nil : Entity( entity: $0! ) } } )
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
            .subscribe( on: queue )
            .observe( on: queue )
            .subscribe()
            .disposed( by: dispBag )
    }
    
    public override func Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        CollectionRefresh( resetCache: resetCache, extra: extra )
    }
    
    func _CollectionRefresh( resetCache: Bool = false, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        lock.lock()
        defer { lock.unlock() }
        
        super._Refresh( resetCache: resetCache, extra: extra )
        self.collectionExtra = collectionExtra ?? self.collectionExtra
        _rxRefresh.accept( RESingleParams( refreshing: true, resetCache: resetCache, first: !started, key: key, lastEntity: entity, extra: self.extra, collectionExtra: self.collectionExtra ) )
        started = true
    }
}
