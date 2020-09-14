//
//  RERepository.swift
//  RxEntity
//
//  Created by ALEXEY ABDULIN on 13.09.2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift

public protocol RERepository
{
    func RxGet( key: REEntityKey ) -> Single<REBackEntityProtocol?>
    func RxGet( keys: REEntityKey ) -> Single<[REBackEntityProtocol]>
}
