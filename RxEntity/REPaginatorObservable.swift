//
//  REPaginatorObservable.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 22/01/2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

public class REPaginatorObservableExtra<Entity: REEntity, Extra>: REArrayObservableExtra<Entity, Extra>
{
    public typealias Element = [Entity]
    
    override init( holder: REEntityCollection<Entity>, keys: [REEntityKey] = [], extra: Extra? = nil, perPage: Int = 30, start: Bool = true, observeOn: OperationQueueScheduler, combineSources: [RECombineSource<Entity>] )
    {
        super.init( holder: holder, keys: keys, extra: extra, perPage: perPage, start: start, observeOn: observeOn, combineSources: combineSources )
    }

    public func Next()
    {
        
    }
    
    override func Append( entities: [Entity] ) -> [Entity]
    {
        assert( queue.operationQueue == OperationQueue.current, "Append can be updated only from the specified in the constructor OperationQueue" )
        
        var _entities = self.entities ?? []
        _entities.AppendOrReplace( entities: entities )
        Set( page: entities.count == perPage ? page + 1 : PAGINATOR_END )
        return _entities
    }
}

public typealias REPaginatorObservable<Entity: REEntity> = REPaginatorObservableExtra<Entity, REEntityExtraParamsEmpty>
