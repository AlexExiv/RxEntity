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
    public let rxLoader = BehaviorRelay<Bool>( value: false )
    public let rxError = PublishRelay<Error>()
    
    let dispBag = DisposeBag()
    
    public let uuid = UUID().uuidString
    public private(set) weak var collection: REEntityCollection<Entity>? = nil
    let combineSources: [RECombineSource<Entity>]
    
    init( holder: REEntityCollection<Entity>, combineSources: [RECombineSource<Entity>] )
    {
        self.collection = holder
        self.combineSources = combineSources
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
    
    func RefreshData( resetCache: Bool, data: Any? )
    {
        
    }
}

extension REEntityObservable
{
    public func bind( loader: BehaviorRelay<Bool> ) -> Disposable
    {
        return rxLoader.bind( to: loader )
    }
    
    public func bind( error: PublishRelay<Error> ) -> Disposable
    {
        return rxError.bind( to: error )
    }
}
