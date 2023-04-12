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
    /// Current page
    public let page: Int
    /// Number of element per page
    public let perPage: Int
    /// Update requested from refreshing
    public let refreshing: Bool
    public let resetCache: Bool
    /// The first loading request flag
    public let first: Bool
    /// The observable's extra params for example filter and e.g.
    public let extra: Extra?
    /// The collection extra params it maybe a region or city or so on
    public let collectionExtra: CollectionExtra?
    
    init( page: Int, perPage: Int, refreshing: Bool = false, resetCache: Bool = false, first: Bool = false, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        self.page = page
        self.perPage = perPage
        self.refreshing = refreshing
        self.resetCache = resetCache
        self.first = first
        self.extra = extra
        self.collectionExtra = collectionExtra
    }
}

public class REPaginatorObservableCollectionExtra<Entity: REEntity, Extra, CollectionExtra>: REPaginatorObservableExtra<Entity, Extra>
{
    public typealias Element = [Entity]
    public typealias PageFetchCallback<Extra, CollectionExtra> = (REPageParams<Extra, CollectionExtra>) -> Single<[Entity]>
    public typealias PageFetchBackCallback<Extra, CollectionExtra> = (REPageParams<Extra, CollectionExtra>) -> Single<[REBackEntityProtocol]>
    
    let rxPage = PublishRelay<REPageParams<Extra, CollectionExtra>>()

    public private(set) var collectionExtra: CollectionExtra? = nil
    var started = false
      
    init( holder: REEntityCollection<Entity>, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, perPage: Int = RE_ARRAY_PER_PAGE, start: Bool = true, observeOn: SchedulerType, fetch: @escaping PageFetchCallback<Extra, CollectionExtra> )
    {
        self.collectionExtra = collectionExtra
        super.init( holder: holder, extra: extra, perPage: perPage, observeOn: observeOn )
        
        weak var _self = self
        Observable
            .combineLatest( rxPage, rxSuspended )
            .filter { $0.0.page >= 0 && !$0.1 }
            .map { $0.0 }
            .do( onNext:
            {
                _self?.rxLoader.accept( $0.first ? .firstLoading : .loading )
                _self?.rxLastError.accept( nil )
            } )
            .flatMapLatest( {
                fetch( $0 )
                    .asObservable()
                    //.do( onNext: { _self?.Set( keys: $0.map { $0._key } ) } )
                    .catch
                    {
                        _self?.rxError.accept( $0 )
                        _self?.rxLastError.accept( $0 )
                        _self?.rxLoader.accept( .none )
                        return Observable.just( [] )
                    }
            } )
            .observe( on: observeOn )
            .do( onNext: { _ in _self?.rxLoader.accept( .none ) } )
            .flatMap { _self?.collection?.RxRequestForCombine( source: _self?.uuid ?? "", entities: $0 ) ?? Single.just( [] ) }
            .subscribe( onNext: { _self?.Set( entities: _self?.Append( entities: $0 ) ?? [] ) } )
            .disposed( by: dispBag )
        
        if start
        {
            started = true
            rxPage.accept( REPageParams( page: 0, perPage: perPage, first: true, extra: extra, collectionExtra: collectionExtra ) )
        }
    }
    
    convenience init( holder: REEntityCollection<Entity>, initial: [Entity], collectionExtra: CollectionExtra? = nil, observeOn: SchedulerType, fetch: @escaping PageFetchCallback<Extra, CollectionExtra> )
    {
        self.init( holder: holder, collectionExtra: collectionExtra, start: false, observeOn: observeOn, fetch: fetch )
        
        weak var _self = self
        Single.just( true )
            .observe( on: observeOn )
            .flatMap { _ in _self?.collection?.RxRequestForCombine( source: _self?.uuid ?? "", entities: initial ) ?? Single.just( [] ) }
            .subscribe( onSuccess: { _self?.Set( entities: $0 ) } )
            .disposed( by: dispBag )
        
        started = true
    }
    
    convenience init( holder: REEntityCollection<Entity>, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, perPage: Int = RE_ARRAY_PER_PAGE, start: Bool = true, observeOn: SchedulerType, fetch: @escaping PageFetchBackCallback<Extra, CollectionExtra> )
    {
        self.init( holder: holder, extra: extra, collectionExtra: collectionExtra, perPage: perPage, start: start, observeOn: observeOn, fetch: { fetch( $0 ).map { $0.map { Entity( entity: $0 ) } } } )
    }
    
    convenience init( holder: REEntityCollection<Entity>, initial: [Entity], collectionExtra: CollectionExtra? = nil, observeOn: SchedulerType, fetch: @escaping PageFetchBackCallback<Extra, CollectionExtra> )
    {
        self.init( holder: holder, initial: initial, collectionExtra: collectionExtra, observeOn: observeOn, fetch: { fetch( $0 ).map { $0.map { Entity( entity: $0 ) } } } )
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
            rxPage.accept( REPageParams( page: page + 1, perPage: perPage, extra: extra, collectionExtra: collectionExtra ) )
        }
        else
        {
            Refresh()
        }
    }
    
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
            .observe( on: queue )
            .subscribe( on: queue )
            .subscribe()
            .disposed( by: dispBag )
    }
    
    func _CollectionRefresh( resetCache: Bool = false, extra: Extra? = nil, collectionExtra: CollectionExtra? = nil )
    {
        lock.lock()
        defer { lock.unlock() }
        
        super._Refresh( resetCache: resetCache, extra: extra )
        self.collectionExtra = collectionExtra ?? self.collectionExtra
        rxPage.accept( REPageParams( page: page + 1, perPage: perPage, refreshing: true, resetCache: resetCache, first: !started, extra: self.extra, collectionExtra: self.collectionExtra ) )
        started = true
    }
}
