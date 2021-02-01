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

public enum REArrayUpdatePolicy
{
    case update, reload
}

public let RE_ARRAY_PER_PAGE = 999999

public class REArrayObservableExtra<Entity: REEntity, Extra>: REEntityObservable<Entity>, ObservableType
{
    public typealias Element = [Entity]
    
    let rxPublish = BehaviorSubject<Element>( value: [] )
    let queue: OperationQueueScheduler

    public private(set) var page = -1
    public private(set) var perPage = RE_ARRAY_PER_PAGE
    public private(set) var extra: Extra? = nil

    public private(set) var entities: [Entity] = []
    
    public var updatePolicy: REArrayUpdatePolicy = .update
    /*{
        didSet
        {
            rxPublish.onNext( entities )
        }
    }*/
   
    init( holder: REEntityCollection<Entity>, extra: Extra? = nil, perPage: Int = RE_ARRAY_PER_PAGE, start: Bool = true, observeOn: OperationQueueScheduler )
    {
        self.queue = observeOn
        self.extra = extra
        self.perPage = perPage
        
        super.init( holder: holder )
    }
    
    //MARK: - Update
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
    
    override func Update( entities: [REEntityKey: Entity], operation: REUpdateOperation )
    {
        lock.lock()
        defer { lock.unlock() }

        switch operation
        {
        case .insert,
             .update where updatePolicy == .reload:
            Refresh( extra: extra )
            
        case .clear:
            Clear()
            
        default:
            let _entities = self.entities
            _entities.forEach
            {
                if let e = entities[$0._key]
                {
                    switch operation
                    {
                    case .update:
                        Set( entity: e )
                        
                    case .delete:
                        Remove( key: e._key )
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
    override func Update( entities: [REEntityKey: Entity], operations: [REEntityKey: REUpdateOperation] )
    {
        lock.lock()
        defer { lock.unlock() }
        
        if operations.values.contains( .insert ) || (updatePolicy == .reload && operations.values.contains( .update ))
        {
            Refresh( extra: extra )
        }
        else
        {
            let _entities = self.entities
            _entities.forEach
            {
                if let e = entities[$0._key], let o = operations[$0._key]
                {
                    switch o
                    {
                    case .update:
                        Set( entity: e )
                        
                    case .delete:
                        Remove( key: e._key )
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
    override func Delete( keys: Set<REEntityKey> )
    {
        let _entities = self.entities
        _entities.forEach
        {
            if keys.contains( $0._key )
            {
                Remove( key: $0._key )
            }
        }
    }
    
    override func Clear()
    {
        Set( entities: [] )
    }
    
    //MARK: - Set
    func Set( entity: Entity )
    {
        lock.lock()
        defer { lock.unlock() }
        
        if let i = entities.firstIndex( where: { $0._key == entity._key } )
        {
            entities[i] = entity
            rxPublish.onNext( entities )
        }
    }
    
    func Set( entities: [Entity] )
    {
        lock.lock()
        defer { lock.unlock() }
        
        self.entities = entities
        rxPublish.onNext( self.entities )
    }
    
    public func Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        
    }
    
    func _Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        assert( queue.operationQueue == OperationQueue.current, "_Refresh can be updated only from the specified in the constructor OperationQueue" )
        
        self.extra = extra ?? self.extra
        page = -1
        if perPage != RE_ARRAY_PER_PAGE
        {
            Set( entities: [] )
            rxPublish.onNext( [] )
        }
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
        rxPublish.onNext( entities )
    }
    
    public func Remove( entity: Entity )
    {
        lock.lock()
        defer { lock.unlock() }
        
        entities.Remove( entity: entity )
        rxPublish.onNext( entities )
    }
    
    public func Remove( key: REEntityKey )
    {
        lock.lock()
        defer { lock.unlock() }
        
        entities.Remove( key: key )
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
