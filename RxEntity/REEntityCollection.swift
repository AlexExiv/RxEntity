//
//  REEntityCollection.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 10/02/2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift

struct REWeakObjectObservable<Entity: REEntity>
{
    weak var ref: REEntityObservable<Entity>?
}

public class REEntityCollection<Entity: REEntity>
{
    var items = [REWeakObjectObservable<Entity>]()
    var sharedEntities = [REEntityKey: Entity]()
    
    public var entitiesByKey: [REEntityKey: Entity] { sharedEntities }
    
    let lock = NSRecursiveLock()
    let queue: OperationQueueScheduler
    let dispBag = DisposeBag()
    
    init( queue: OperationQueueScheduler )
    {
        self.queue = queue
        self.queue.operationQueue.maxConcurrentOperationCount = 1
    }
    
    func Add( object: REEntityObservable<Entity> )
    {
        items.append( REWeakObjectObservable( ref: object ) )
    }
    
    func Remove( object: REEntityObservable<Entity> )
    {
        items.removeAll( where: { object.uuid == $0.ref?.uuid } )
    }
    
    func RxRequestForCombine( source: String = "", entity: Entity ) -> Single<Entity>
    {
        preconditionFailure( "" )
    }
    
    func RxRequestForCombine( source: String = "", entities: [Entity] ) -> Single<[Entity]>
    {
        preconditionFailure( "" )
    }
    
    public func RxUpdate( source: String = "", entity: Entity ) -> Single<Entity>
    {
        return Single.create
            {
                [weak self] in
                
                self?.Update( source: source, entity: entity )
                $0( .success( entity ) )
                
                return Disposables.create()
            }
            .observeOn( queue )
            .subscribeOn( queue )
    }
    
    public func RxUpdate( source: String = "", entities: [Entity] ) -> Single<[Entity]>
    {
        Update( source: source, entities: entities )
        return Single.create
            {
                [weak self] in
                
                self?.Update( source: source, entities: entities )
                $0( .success( entities ) )
                
                return Disposables.create()
            }
            .observeOn( queue )
            .subscribeOn( queue )
    }
    
    open func Update( source: String = "", entity: Entity )
    {
        assert( queue.operationQueue == OperationQueue.current, "Observable objects collection can be updated only from the specified in the constructor OperationQueue" )
        
        sharedEntities[entity._key] = entity
        items.forEach { $0.ref?.Update( source: source, entity: entity ) }
    }
    
    open func Update( source: String = "", entities: [Entity] )
    {
        assert( queue.operationQueue == OperationQueue.current, "Observable objects collection can be updated only from the specified in the constructor OperationQueue" )
        
        entities.forEach { sharedEntities[$0._key] = $0 }
        items.forEach { $0.ref?.Update( source: source, entities: entities.asEntitiesMap() ) }
    }
    
    //MARK: - Commit
    func Commit( entity: Entity, operation: REUpdateOperation = .update )
    {
        fatalError( "This method must be overridden" )
    }
    
    func Commit( key: REEntityKey, operation: REUpdateOperation = .update )
    {
        fatalError( "This method must be overridden" )
    }
    
    func Commit( key: REEntityKey, changes: (Entity) -> Entity )
    {
        fatalError( "This method must be overridden" )
    }
    
    func Commit( entities: [Entity], operation: REUpdateOperation = .update )
    {
        fatalError( "This method must be overridden" )
    }
    
    func Commit( entities: [Entity], operations: [REUpdateOperation] )
    {
        fatalError( "This method must be overridden" )
    }
    
    func Commit( keys: [REEntityKey], operation: REUpdateOperation = .update )
    {
        fatalError( "This method must be overridden" )
    }
    
    func Commit( keys: [REEntityKey], operations: [REUpdateOperation] )
    {
        fatalError( "This method must be overridden" )
    }
    
    func Commit( keys: [REEntityKey], changes: (Entity) -> Entity )
    {
        fatalError( "This method must be overridden" )
    }
    
    //MARK: - Create
    func CreateSingle( initial: Entity, refresh: Bool = false ) -> RESingleObservable<Entity>
    {
        fatalError( "This method must be overridden" )
    }

    func CreateKeyArray( initial: [Entity] ) -> REKeyArrayObservable<Entity>
    {
        fatalError( "This method must be overridden" )
    }
}
