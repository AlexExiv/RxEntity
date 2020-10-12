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

public struct RERepositoryUpdated
{
    let key: REEntityKey
    let entity: REBackEntityProtocol?
    let operation: REUpdateOperation
    let needSync: Bool
    
    init( key: REEntityKey, entity: REBackEntityProtocol? = nil, operation: REUpdateOperation = .none, needSync: Bool = false )
    {
        self.key = key
        self.entity = entity
        self.operation = operation
        self.needSync = needSync
    }
    
    init( entity: REBackEntityProtocol, operation: REUpdateOperation = .none, needSync: Bool = false )
    {
        self.init( key: entity._key, entity: entity, operation: operation, needSync: needSync )
    }
}

public protocol RERepositoryProtocol
{
    var rxUpdated: PublishRelay<RERepositoryUpdated> { get }
    
    func RxSave( key: REBackEntityProtocol ) -> Single<REBackEntityProtocol>
    func RxGet( key: REEntityKey ) -> Single<REBackEntityProtocol?>
    func RxGet( keys: [REEntityKey] ) -> Single<[REBackEntityProtocol]>
}

public class RERepository: RERepositoryProtocol
{
    public var rxUpdated = PublishRelay<RERepositoryUpdated>()
    
    public func RxSave( key: REBackEntityProtocol ) -> Single<REBackEntityProtocol>
    {
        preconditionFailure( "RxSave must be implemented" )
    }
    
    public func RxGet( key: REEntityKey ) -> Single<REBackEntityProtocol?>
    {
        preconditionFailure( "RxGet must be implemented" )
    }
    
    public func RxGet( keys: [REEntityKey] ) -> Single<[REBackEntityProtocol]>
    {
        preconditionFailure( "RxGet must be implemented" )
    }
}
