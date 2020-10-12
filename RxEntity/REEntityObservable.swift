//
//  REObjectObservable.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 22/01/2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

public struct REEntityExtraParamsEmpty
{
    
}

public class REEntityObservable<Entity: REEntity>
{
    public enum Loading
    {
        case none, firstLoading, loading
        
        public var isLoading: Bool { self == .firstLoading || self == .loading }
    }
    
    public let rxLoader = BehaviorRelay<Loading>( value: .none )
    public let rxError = PublishRelay<Error>()
    
    let dispBag = DisposeBag()
    
    public let uuid = UUID().uuidString
    let lock = NSRecursiveLock()
    
    public private(set) weak var collection: REEntityCollection<Entity>? = nil
    
    init( holder: REEntityCollection<Entity> )
    {
        self.collection = holder
        holder.Add( object: self )
    }
    
    deinit
    {
        collection?.Remove( object: self )
        print( "EntityObservable has been deleted. UUID - \(uuid)" )
    }

    func Update( source: String, entity: Entity )
    {
        
    }
    
    func Update( source: String, entities: [REEntityKey: Entity] )
    {
        
    }
    
    func Update( entity: Entity, operation: REUpdateOperation )
    {
        Update( entities: [entity._key: entity], operation: operation )
    }

    func Update( entities: [REEntityKey: Entity], operation: REUpdateOperation )
    {
        fatalError( "This method must be overridden" )
    }
    
    func Update( entities: [REEntityKey: Entity], operations: [REEntityKey: REUpdateOperation] )
    {
        fatalError( "This method must be overridden" )
    }
    
    func RefreshData( resetCache: Bool, data: Any? )
    {
        
    }
}

extension REEntityObservable
{
    public func bind( loader: BehaviorRelay<REEntityObservable.Loading> ) -> Disposable
    {
        return rxLoader.bind( to: loader )
    }
    
    public func bind( error: PublishRelay<Error> ) -> Disposable
    {
        return rxError.bind( to: error )
    }
}
