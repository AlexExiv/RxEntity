//
//  REEntity.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 22/01/2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation

public typealias REEntityKey = AnyHashable

public protocol REEntity
{
    ///The key of the element
    var _key: REEntityKey { get }
    init( entity: REBackEntityProtocol )
}

public extension REEntity
{
    init( entity: REBackEntityProtocol )
    {
        preconditionFailure( "Default implimentation is prohibited to call" )
    }
}

public protocol REBackEntityProtocol
{
    ///The key of the element
    var _key: REEntityKey { get }
    init( entity: REBackEntityProtocol )
}

public extension AnyHashable
{
    /// Returns string representation of the key
    var stringKey: String
    {
        base as! String
    }
    
    /// Returns int representation of the key
    var intKey: Int
    {
        base as! Int
    }
}
