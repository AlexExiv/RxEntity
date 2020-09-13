//
//  REArrayObservable.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 29/01/2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

public class REArrayObservableExtra<Entity: REEntity, Extra>: REEntityObservable<Entity>, ObservableType
{
    public typealias Element = [Entity]
    
    let rxPublish = BehaviorSubject<Element?>( value: nil )
    let queue: OperationQueueScheduler

    public private(set) var page = -1
    public private(set) var perPage = 999999
    public private(set) var extra: Extra? = nil

    public private(set) var keys: [REEntityKey] = []
    
    public var entities: [Entity]?
    {
        return try! rxPublish.value()
    }
    
    public var entitiesNotNil: [Entity]
    {
        return entities ?? []
    }
        
    init( holder: REEntityCollection<Entity>, keys: [REEntityKey] = [], extra: Extra? = nil, perPage: Int = 999999, start: Bool = true, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>] )
    {
        self.queue = observeOn
        self.keys = keys
        self.extra = extra
        self.perPage = perPage
        
        super.init( holder: holder, combineSources: combineSources )
    }
    
    override func Update( source: String, entity: Entity )
    {
        assert( queue.operationQueue == OperationQueue.current, "Paginator observable can be updated only from the same queue with the parent collection" )
        
        if var entities = self.entities, let i = entities.firstIndex( where: { entity.key == $0.key } ), source != uuid
        {
            entities[i] = entity
            rxPublish.onNext( entities )
        }
    }
    
    override func Update( source: String, entities: [REEntityKey: Entity] )
    {
        assert( queue.operationQueue == OperationQueue.current, "Paginator observable can be updated only from the same queue with the parent collection" )
        
        guard var _entities = self.entities, source != uuid else { return }
        
        var was = false
        for i in 0..<_entities.count
        {
            let e = _entities[i]
            if let ne = entities[e.key]
            {
                _entities[i] = ne
                was = true
            }
        }
        
        if was
        {
            rxPublish.onNext( _entities )
        }
    }
    
    subscript( index: Int ) -> RESingleObservable<Entity>
    {
        return collection!.CreateSingle( initial: entitiesNotNil[index] )
    }
    
    func Set( keys: [REEntityKey] )
    {
        self.keys = keys
    }
    
    public func Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        
    }
    
    func _Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        assert( queue.operationQueue == OperationQueue.current, "_Refresh can be updated only from the specified in the constructor OperationQueue" )
        
        self.extra = extra ?? self.extra
        page = -1
        rxPublish.onNext( [] )
    }

    func Append( entities: [Entity] ) -> [Entity]
    {
        assert( queue.operationQueue == OperationQueue.current, "Append can be updated only from the specified in the constructor OperationQueue" )
        page = PAGINATOR_END
        return entities
    }
    
    func Set( page: Int )
    {
        self.page = page
    }
    
    //MARK: - ObservableType
    public func subscribe<Observer: ObserverType>( _ observer: Observer ) -> Disposable where Observer.Element == Element
    {
        return rxPublish
            .filter { $0 != nil }
            .map { $0! }
            .subscribe( observer )
    }
    
    public func asObservable() -> Observable<Element>
    {
        return rxPublish
            .filter { $0 != nil }
            .map { $0! }
            .asObservable()
    }
}

public typealias REArrayObservable<Entity: REEntity> = REArrayObservableExtra<Entity, REEntityExtraParamsEmpty>

extension ObservableType
{
    public func bind<Entity: REEntity>( refresh: REArrayObservableExtra<Entity, Element>, resetCache: Bool = false ) -> Disposable
    {
        return observeOn( refresh.queue )
            .subscribe( onNext: { refresh._Refresh( resetCache: resetCache, extra: $0 ) } )
    }
}
