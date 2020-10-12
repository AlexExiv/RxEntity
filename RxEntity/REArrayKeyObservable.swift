//
//  REKeyArrayObservable.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 07.10.2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

public class REKeyArrayObservableExtra<Entity: REEntity, Extra>: REArrayObservableExtra<Entity, Extra>
{
    public typealias Element = [Entity]
    public var keys: [REEntityKey]
    {
        set
        {
            lock.lock()
            defer { lock.unlock() }
            
            _keys = newValue
        }
        get { _keys }
        
    }
    var _keys: [REEntityKey] = []

    init( holder: REEntityCollection<Entity>, keys: [REEntityKey] = [], extra: Extra? = nil, observeOn: OperationQueueScheduler )
    {
        self._keys = keys
        super.init( holder: holder, extra: extra, perPage: 0, observeOn: observeOn )
    }
    
    override func Update( entities: [REEntityKey: Entity], operation: REUpdateOperation )
    {
        lock.lock()
        defer { lock.unlock() }
        
        let _entities = self.entities
        _entities.forEach {
            if let e = entities[$0._key]
            {
                self.Apply( entity: e, operation: operation )
            }
        }
    }
    
    override func Update( entities: [REEntityKey: Entity], operations: [REEntityKey: REUpdateOperation] )
    {
        lock.lock()
        defer { lock.unlock() }
        
        let _entities = self.entities
        _entities.forEach {
            if let e = entities[$0._key], let o = operations[$0._key]
            {
                self.Apply( entity: e, operation: o )
            }
        }
    }
    
    private func Apply( entity: Entity, operation: REUpdateOperation )
    {
        switch operation
        {
        case .none, .insert, .update:
            self.Set( entity: entity )
            
        case .delete:
            self.Remove( key: entity._key )
        }
    }
    
    public func Append( key: REEntityKey )
    {
        lock.lock()
        defer { lock.unlock() }
        
        _keys.AppendNotExist( key: key )
    }
    
    public override func Append( entity: Entity )
    {
        lock.lock()
        defer { lock.unlock() }
        
        super.Append( entity: entity )
        _keys.AppendNotExist( key: entity._key )
    }
    
    public override func Remove( entity: Entity )
    {
        lock.lock()
        defer { lock.unlock() }
        
        super.Remove( entity: entity )
        _keys.Remove( key: entity._key )
    }

    public override func Remove( key: REEntityKey )
    {
        lock.lock()
        defer { lock.unlock() }
        
        super.Remove( key: key )
        _keys.Remove( key: key )
    }
}

public typealias REKeyArrayObservable<Entity: REEntity> = REKeyArrayObservableExtra<Entity, REEntityExtraParamsEmpty>

extension ObservableType
{
    public func bind<Entity: REEntity>( refresh: REKeyArrayObservableExtra<Entity, Element>, resetCache: Bool = false ) -> Disposable
    {
        return observeOn( refresh.queue )
            .subscribe( onNext: { refresh._Refresh( resetCache: resetCache, extra: $0 ) } )
    }
}

extension ObservableType where Element == [REEntityKey]
{
    public func bind<Entity: REEntity, Extra>( keys: REKeyArrayObservableExtra<Entity, Extra> ) -> Disposable
    {
        return observeOn( keys.queue )
            .subscribe( onNext: { keys.keys = $0 } )
    }
}
