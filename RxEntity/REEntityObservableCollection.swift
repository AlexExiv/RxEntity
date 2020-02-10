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

public class REEntityObservableCollectionExtra<Entity: REEntity, CollectionExtra>: REEntityCollection<Entity>
{
    public convenience init( operationQueue: OperationQueue )
    {
        self.init( queue: OperationQueueScheduler( operationQueue: operationQueue ) )
    }
    
    public override init( queue: OperationQueueScheduler )
    {
        super.init( queue: queue )
    }

    //MARK: - Create Observables
    public func CreateSingle( collectionExtra: CollectionExtra? = nil, start: Bool = true, _ fetch: @escaping (RESingleParams<REEntityExtraParamsEmpty, CollectionExtra>) -> Single<Entity> ) -> RESingleObservable<Entity>
    {
        return RESingleObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreateSingleExtra<Extra>( extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, start: Bool = true, _ fetch: @escaping (RESingleParams<Extra, CollectionExtra>) -> Single<Entity> ) -> RESingleObservableExtra<Entity, Extra>
    {
        return RESingleObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, extra: extra, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreateArray( collectionExtra: CollectionExtra? = nil, start: Bool = true, _ fetch: @escaping (REPageParams<REEntityExtraParamsEmpty, CollectionExtra>) -> Single<[Entity]> ) -> REArrayObservable<Entity>
    {
        return REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreateArrayExtra<Extra>( extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, start: Bool = true, _ fetch: @escaping (REPageParams<Extra, CollectionExtra>) -> Single<[Entity]> ) -> REArrayObservableExtra<Entity, Extra>
    {
        return REPaginatorObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, extra: extra, collectionExtra: collectionExtra, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreatePaginator( collectionExtra: CollectionExtra? = nil, perPage: Int = 35, start: Bool = true, _ fetch: @escaping (REPageParams<REEntityExtraParamsEmpty, CollectionExtra>) -> Single<[Entity]> ) -> REPaginatorObservable<Entity>
    {
        return REPaginatorObservableCollectionExtra<Entity, REEntityExtraParamsEmpty, CollectionExtra>( holder: self, collectionExtra: collectionExtra, perPage: perPage, start: start, observeOn: queue, fetch: fetch )
    }
    
    public func CreatePaginatorExtra<Extra>( extra: Extra? = nil, collectionExtra: CollectionExtra? = nil, perPage: Int = 35, start: Bool = true, _ fetch: @escaping (REPageParams<Extra, CollectionExtra>) -> Single<[Entity]> ) -> REPaginatorObservableExtra<Entity, Extra>
    {
        return REPaginatorObservableCollectionExtra<Entity, Extra, CollectionExtra>( holder: self, extra: extra, collectionExtra: collectionExtra, perPage: perPage, start: start, observeOn: queue, fetch: fetch )
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
                    self?.sharedEntities[$0.key] = new
                    updArr.append( new )
                    updMap[$0.key] = new
                }
                self?.sharedEntities.forEach
                {
                    e0 in
                    
                    underPathes.forEach
                    {
                        if let v = e0.value[keyPath: $0] as? EntityS, let es = entities[v.key]
                        {
                            Update( e0.value, es )
                        }
                        else if let arr = e0.value[keyPath: $0] as? [EntityS]
                        {
                            arr.forEach
                            {
                                e1 in
                                if let es = entities[e1.key]
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
    
    public func Refresh( resetCache: Bool = false, collectionExtra: CollectionExtra )
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
    
    func _Refresh( resetCache: Bool = false, collectionExtra: CollectionExtra )
    {
        assert( queue.operationQueue == OperationQueue.current, "_Refresh can be called only from the specified in the constructor OperationQueue" )
        items.forEach { $0.ref?.RefreshData( resetCache: resetCache, data: collectionExtra ) }
    }
}

typealias REEntityObservableCollection<Entity: REEntity> = REEntityObservableCollectionExtra<Entity, REEntityCollectionExtraParamsEmpty>

extension ObservableType
{
    public func bind<Entity: REEntity>( refresh: REEntityObservableCollectionExtra<Entity, Element>, resetCache: Bool = false ) -> Disposable
    {
        return observeOn( refresh.queue )
            .subscribe( onNext: { refresh._Refresh( resetCache: resetCache, collectionExtra: $0 ) } )
    }
}
