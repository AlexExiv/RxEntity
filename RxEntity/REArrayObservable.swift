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
    
    let rxPublish = BehaviorSubject<Element>( value: [] )
    let queue: OperationQueueScheduler

    public private(set) var page = -1
    public private(set) var perPage = 999999
    public private(set) var extra: Extra? = nil

    public private(set) var keys: [REEntityKey] = []
    public private(set) var entities: [Entity] = []
   
    init( holder: REEntityCollection<Entity>, keys: [REEntityKey] = [], extra: Extra? = nil, perPage: Int = 999999, start: Bool = true, observeOn: OperationQueueScheduler )
    {
        self.queue = observeOn
        self.keys = keys
        self.extra = extra
        self.perPage = perPage
        
        super.init( holder: holder )
    }
    
    override func Update( source: String, entity: Entity )
    {
        assert( queue.operationQueue == OperationQueue.current, "Paginator observable can be updated only from the same queue with the parent collection" )
        
        lock.lock()
        defer { lock.unlock() }
        
        if let i = entities.firstIndex( where: { entity._key == $0._key } ), source != uuid
        {
            entities[i] = entity
            rxPublish.onNext( entities )
        }
    }
    
    override func Update( source: String, entities: [REEntityKey: Entity] )
    {
        assert( queue.operationQueue == OperationQueue.current, "Paginator observable can be updated only from the same queue with the parent collection" )
        
        guard source != uuid else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        var was = false
        for i in 0..<self.entities.count
        {
            let e = self.entities[i]
            if let ne = entities[e._key]
            {
                self.entities[i] = ne
                was = true
            }
        }
        
        if was
        {
            rxPublish.onNext( self.entities )
        }
    }
    
    func Set( entities: [Entity] )
    {
        lock.lock()
        defer { lock.unlock() }
        
        self.entities = entities
        rxPublish.onNext( self.entities )
    }
    
    func Set( keys: [REEntityKey] )
    {
        lock.lock()
        defer { lock.unlock() }
        
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
        lock.lock()
        defer { lock.unlock() }
        
        self.page = page
    }
    
    //MARK: - Array operations
    public subscript( index: Int ) -> RESingleObservable<Entity>
    {
        lock.lock()
        defer { lock.unlock() }
        
        return collection!.CreateSingle( initial: entities[index] )
    }
    
    public func Append( entity: Entity )
    {
        lock.lock()
        defer { lock.unlock() }
        
        entities.AppendNotExist( entity: entity )
        keys.AppendNotExist( key: entity._key )
        
        rxPublish.onNext( entities )
    }
    
    public func Remove( entity: Entity )
    {
        lock.lock()
        defer { lock.unlock() }
        
        entities.Remove( entity: entity )
        keys.Remove( key: entity._key )
        
        rxPublish.onNext( entities )
    }
    
    //MARK: - ObservableType
    public func subscribe<Observer: ObserverType>( _ observer: Observer ) -> Disposable where Observer.Element == Element
    {
        lock.lock()
        defer { lock.unlock() }
        
        let disp = rxPublish
            .subscribe( observer )
        
        observer.onNext( entities )
        return disp
    }
    
    public func asObservable() -> Observable<Element>
    {
        return rxPublish
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
