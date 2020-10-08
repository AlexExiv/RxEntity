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

    init( holder: REEntityCollection<Entity>, keys: [REEntityKey] = [], extra: Extra? = nil, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>] )
    {
        super.init( holder: holder, keys: keys, extra: extra, perPage: 0, observeOn: observeOn, combineSources: combineSources )
    }
    
    public func Append( key: REEntityKey )
    {
        lock.lock()
        defer { lock.unlock() }
        
        var _keys = keys
        _keys.append( key )
        Set( keys: _keys )
    }
    
    public func Remove( key: REEntityKey )
    {
        lock.lock()
        defer { lock.unlock() }
        
        if let i = keys.firstIndex( where: { $0 == key } )
        {
            var _keys = keys
            _keys.remove( at: i )
            Set( keys: _keys )
        }
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
            .subscribe( onNext: { keys.Set( keys: $0 ) } )
    }
}
