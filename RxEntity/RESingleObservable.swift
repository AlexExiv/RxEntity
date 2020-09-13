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
    public typealias Element = Entity
    
    let queue: OperationQueueScheduler
    let rxPublish = BehaviorSubject<Entity?>( value: nil )
    
    public private(set) var extra: Extra? = nil
    
    public private(set) var key: REEntityKey? = nil
    public var entity: Entity?
    {
        return try! rxPublish.value()
    }
    
    init( holder: REEntityCollection<Entity>, key: REEntityKey? = nil, extra: Extra? = nil, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>] )
    {
        self.queue = observeOn
        self.key = key
        self.extra = extra
        
        super.init( holder: holder, combineSources: combineSources )
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
    
    func Set( key: REEntityKey )
    {
        self.key = key
    }
    
    public func Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        
    }
    
    func _Refresh( resetCache: Bool = false, extra: Extra? = nil )
    {
        assert( queue.operationQueue == OperationQueue.current, "_Refresh can be updated only from the specified in the constructor OperationQueue" )
        self.extra = extra ?? self.extra
    }

    //MARK: - ObservableType
    public func subscribe<Observer: ObserverType>( _ observer: Observer ) -> Disposable where Observer.Element == Element
    {
        return rxPublish
            .filter { $0 != nil }
            .map { $0! }
            .subscribe( observer )
    }
    
    public func asObservable() -> Observable<Entity>
    {
        return rxPublish
            .filter { $0 != nil }
            .map { $0! }
            .asObservable()
    }
}

public typealias RESingleObservable<Entity: REEntity> = RESingleObservableExtra<Entity, REEntityExtraParamsEmpty>

extension ObservableType
{
    public func bind<Entity: REEntity>( refresh: RESingleObservableExtra<Entity, Element>, resetCache: Bool = false ) -> Disposable
    {
        return observeOn( refresh.queue )
            .subscribe( onNext: { refresh._Refresh( resetCache: resetCache, extra: $0 ) } )
    }
}
