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
    var key: REEntityKey { get }
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
