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
    var _key: REEntityKey { get }
    init( entity: REBackEntityProtocol )
}

public protocol REBackEntityProtocol
{
    var _key: REEntityKey { get }
    init( entity: REBackEntityProtocol )
}

extension AnyHashable
{
    var stringKey: String
    {
        return base as! String
    }
    
    var intKey: Int
    {
        return base as! Int
    }
}
