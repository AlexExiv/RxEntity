//
//  TestRepository.swift
//  RxEntityTests
//
//  Created by ALEXEY ABDULIN on 13.10.2020.
//  Copyright © 2020 ALEXEY ABDULIN. All rights reserved.
//

import Foundation
import RxSwift
import RxEntity

protocol TestEntityBackProtocol: REBackEntityProtocol
{
    var id: String { get }
    var value: String { get }
    var indirectId: String { get }
    var indirectValue: String { get }
    
    init( entity: TestEntityBackProtocol )
}

extension TestEntityBackProtocol
{
    var _key: REEntityKey { return REEntityKey( id ) }
    
    init( entity: REBackEntityProtocol )
    {
        self.init( entity: entity as! TestEntityBackProtocol )
    }
}

struct TestEntityBack: TestEntityBackProtocol
{
    let id: String
    let value: String
    let indirectId: String
    let indirectValue: String
    
    init( id: String, value: String, indirectId: String = "", indirectValue: String = "" )
    {
        self.id = id
        self.value = value
        self.indirectId = indirectId
        self.indirectValue = indirectValue
    }
    
    init( entity: TestEntityBackProtocol )
    {
        id = entity.id
        value = entity.value
        indirectId = entity.indirectId
        indirectValue = entity.indirectValue
    }
}

protocol IndirectEntityBackProtocol: REBackEntityProtocol
{
    var id: String { get }
    var value: String { get }
    
    init( entity: TestEntityBackProtocol )
}

extension IndirectEntityBackProtocol
{
    var _key: REEntityKey { return REEntityKey( id ) }
    
    init( entity: REBackEntityProtocol )
    {
        self.init( entity: entity as! TestEntityBackProtocol )
    }
}

struct IndirectEntityBack: IndirectEntityBackProtocol
{
    let id: String
    let value: String
    
    init( id: String, value: String )
    {
        self.id = id
        self.value = value
    }
    
    init( entity: TestEntityBackProtocol )
    {
        id = entity.id
        value = entity.value
    }
}

class TestRepository<Entity: REBackEntityProtocol>: REEntityRepository<Entity>
{
    var items: [Entity] = []

    func Add( entities: [Entity] )
    {
        items.append( contentsOf: entities )
        rxEntitiesUpdated.accept( entities.map { REEntityUpdated( key: $0._key, operation: .insert ) } )
    }
    
    func Update( entity: Entity )
    {
        if let i = items.firstIndex( where: { entity._key == $0._key } )
        {
            items[i] = entity
        }
        else
        {
            items.append( entity )
        }
        rxEntitiesUpdated.accept( [REEntityUpdated( key: entity._key, operation: .update )] )
    }
    
    func Delete( key: REEntityKey )
    {
        items.removeAll( where: { $0._key == key } )
        rxEntitiesUpdated.accept( [REEntityUpdated( key: key, operation: .delete )] )
    }
    
    override func RxGet( key: REEntityKey ) -> Single<Entity?>
    {
        return Single.just( items.first(where: { $0._key == key } ) )
    }
    
    override func RxGet( keys: [REEntityKey] ) -> Single<[Entity]>
    {
        return Single.just( items.filter { keys.contains( $0._key ) } )
    }
}

typealias TestRepositoryIndirect = TestRepository<IndirectEntityBack>

class TestRepositoryDirect: TestRepository<TestEntityBack>
{
    let second: TestRepositoryIndirect
    
    init( second: TestRepositoryIndirect )
    {
        self.second = second
        super.init()
    }
    
    override func RxGet( key: REEntityKey ) -> Single<TestEntityBack?>
    {
        return super.RxGet( key: key )
            .flatMap { $0 == nil ? Single.just( nil ) : self.RxLoad( entities: [$0!] ).map { $0.first } }
    }
    
    override func RxGet( keys: [REEntityKey] ) -> Single<[TestEntityBack]>
    {
        return super.RxGet( keys: keys )
            .flatMap { self.RxLoad( entities: $0 ) }
    }
    
    func RxLoad( entities: [TestEntityBack] ) -> Single<[TestEntityBack]>
    {
        let keys = entities.map { $0.indirectId }
        return second
            .RxGet( keys: keys )
            .map { $0.asEntitiesMap() }
            .map { m in entities.map { TestEntityBack( id: $0.id, value: $0.value, indirectId: $0.indirectId, indirectValue: m[$0.indirectId]?.value ?? "" ) } }
    }
}

extension Array where Element: REBackEntityProtocol
{
    public func asEntitiesMap() -> [REEntityKey: Element]
    {
        var map = [REEntityKey: Element]()
        forEach { map[$0._key] = $0 }
        return map
    }
}
