//
//  RESingleObservable.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 22/01/2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

public class RESingleObservableExtra<Entity: REEntity, Extra>: REEntityObservable<Entity>, ObservableType
{
    public typealias Element = Entity?
    
    public enum State
    {
        case initializing, ready, notFound, deleted
    }
    
    let queue: SchedulerType
    
    public let rxState = BehaviorRelay<State>( value: .initializing )
    let rxPublish = BehaviorSubject<Entity?>( value: nil )
    
    public private(set) var extra: Extra? = nil
    
    public var key: REEntityKey? = nil
    public var entity: Entity?
    {
        return try! rxPublish.value()
    }
    
    init( holder: REEntityCollection<Entity>, key: REEntityKey? = nil, extra: Extra? = nil, observeOn: SchedulerType )
    {
        self.queue = observeOn
        self.key = key
        self.extra = extra
        
        super.init( holder: holder )
    }
    
    override func Update( source: String, entity: Entity )
    {
        if let key = self.entity?._key, key == entity._key, source != uuid
        {
            rxPublish.onNext( entity )
        }
    }
    
    override func Update( source: String, entities: [REEntityKey: Entity] )
    {
        if let key = entity?._key, let entity = entities[key], source != uuid
        {
            rxPublish.onNext( entity )
        }
    }
    
    override func Update( entities: [REEntityKey: Entity], operation: REUpdateOperation )
    {
        if let k = entity?._key, let e = entities[k]
        {
            switch operation
            {
            case .none, .insert, .update:
                rxPublish.onNext( e )
                rxState.accept( .ready )
                
            case .delete, .clear:
                Clear()
            }
        }
    }
    
    override func Update( entities: [REEntityKey: Entity], operations: [REEntityKey: REUpdateOperation] )
    {
        if let k = entity?._key, let e = entities[k], let o = operations[k]
        {
            switch o
            {
            case .none, .insert, .update:
                rxPublish.onNext( e )
                rxState.accept( .ready )
                
            case .delete, .clear:
                Clear()
            }
        }
    }
    
    override func Delete( keys: Set<REEntityKey> )
    {
        if let k = entity?._key, keys.contains( k )
        {
            Clear()
        }
    }
    
    override func Clear()
    {
        rxPublish.onNext( nil )
        rxState.accept( .deleted )
    }
    
    func Set( key: REEntityKey )
    {
        self.key = key
    }
    
    public func Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        
    }
    
    func _Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        lock.lock()
        defer { lock.unlock() }
        
        self.extra = extra ?? self.extra
    }

    //MARK: - ObservableType
    public func subscribe<Observer: ObserverType>( _ observer: Observer ) -> Disposable where Observer.Element == Element
    {
        return rxPublish
            .subscribe( observer )
    }
    
    public func asObservable() -> Observable<Element>
    {
        return rxPublish
            .asObservable()
    }
}

public typealias RESingleObservable<Entity: REEntity> = RESingleObservableExtra<Entity, REEntityExtraParamsEmpty>

extension ObservableType
{
    public func bind<Entity: REEntity>( refresh: RESingleObservableExtra<Entity, Element>, resetCache: Bool = false ) -> Disposable
    {
        return observe( on: refresh.queue )
            .subscribe( onNext: { refresh._Refresh( resetCache: resetCache, extra: $0 ) } )
    }
}
