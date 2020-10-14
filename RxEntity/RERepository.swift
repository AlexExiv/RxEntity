//
//  RERepository.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 13.09.2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

public enum REUpdateOperation
{
    case none, insert, update, delete
}

public struct REEntityUpdated: CustomStringConvertible
{
    let key: REEntityKey
    let fieldPath: AnyKeyPath?
    let entity: REBackEntityProtocol?
    let operation: REUpdateOperation
    
    public init( key: REEntityKey, fieldPath: AnyKeyPath? = nil, entity: REBackEntityProtocol? = nil, operation: REUpdateOperation = .none )
    {
        self.key = key
        self.entity = entity
        self.operation = operation
        self.fieldPath = fieldPath
    }
    
    public init( entity: REBackEntityProtocol, fieldPath: AnyKeyPath? = nil, operation: REUpdateOperation = .none )
    {
        self.init( key: entity._key, entity: entity, operation: operation )
    }
    
    public var description: String
    {
        return "Key: \(key.base); FieldPath: \(fieldPath == nil ? "nil" : "\(fieldPath!)"); EntityExist: \(entity != nil); Operation: \(operation)"
    }
}

public protocol REEntityRepositoryProtocol
{
    var rxEntitiesUpdated: PublishRelay<[REEntityUpdated]> { get }
    
    func _RxGet( key: REEntityKey ) -> Single<REBackEntityProtocol?>
    func _RxGet( keys: [REEntityKey] ) -> Single<[REBackEntityProtocol]>
}

open class REEntityRepository<EntityBack: REBackEntityProtocol>: REEntityRepositoryProtocol
{
    public var rxEntitiesUpdated = PublishRelay<[REEntityUpdated]>()
    public let dispBag = DisposeBag()
    
    public init()
    {
        
    }
    
    public func Connect<Entity: REEntity, V>( repository: REEntityRepositoryProtocol, fieldPath: KeyPath<Entity, V> )
    {
        repository
            .rxEntitiesUpdated
            .map { $0.map { REEntityUpdated( key: $0.key, fieldPath: fieldPath, operation: $0.operation ) } }
            .bind( to: rxEntitiesUpdated )
            .disposed( by: dispBag )
    }
    
    public func _RxGet( key: REEntityKey ) -> Single<REBackEntityProtocol?>
    {
        return RxGet( key: key ).map { $0 }
    }
    
    public func _RxGet( keys: [REEntityKey] ) -> Single<[REBackEntityProtocol]>
    {
        return RxGet( keys: keys ).map { $0 }
    }
    
    open func RxGet( key: REEntityKey ) -> Single<EntityBack?>
    {
        preconditionFailure( "RxGet must be implemented" )
    }
    
    open func RxGet( keys: [REEntityKey] ) -> Single<[EntityBack]>
    {
        preconditionFailure( "RxGet must be implemented" )
    }
}
