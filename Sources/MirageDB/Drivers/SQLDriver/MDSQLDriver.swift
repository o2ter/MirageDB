//
//  MDSQLDriver.swift
//
//  The MIT License
//  Copyright (c) 2021 The Oddmen Technology Limited. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import DoggieDB

protocol MDSQLDriver: MDDriver {
    
}

extension MDObject {
    
    fileprivate init(_ object: DBObject) throws {
        var data: [String: MDData] = [:]
        for key in object.keys where key != "id" {
            data[key] = try MDData(object[key])
        }
        self.init(class: object.class, id: object["id"].string, data: data)
    }
}

extension DBQuerySortOrder {
    
    fileprivate init(_ order: MDSortOrder) {
        switch order {
        case .ascending: self = .ascending
        case .descending: self = .descending
        }
    }
}

extension DBQueryUpdateOperation {
    
    fileprivate init(_ operation: MDUpdateOperation) {
        switch operation {
        case let .set(value): self = .set(value)
        case let .increment(value): self = .increment(value)
        case let .multiply(value): self = .multiply(value)
        case let .max(value): self = .max(value)
        case let .min(value): self = .min(value)
        case let .push(value): self = .push([value])
        case let .removeAll(value): self = .removeAll(value)
        case .popFirst: self = .popFirst
        case .popLast: self = .popLast
        }
    }
}

extension MDSQLDriver {
    
    func tables(_ connection: MDConnection) -> EventLoopFuture<[String]> {
        
        do {
            
            guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
            
            return connection.tables()
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func count(_ query: MDQuery) -> EventLoopFuture<Int> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            var _query = query.connection.connection.query().find(`class`)
            
            _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
            
            return _query.count()
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func _find(_ query: MDQuery) throws -> DBQueryFindExpression {
        
        guard let `class` = query.class else { throw MDError.classNotSet }
        
        var _query = query.connection.connection.query().find(`class`)
        
        _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
        
        if let sort = query.sort {
            _query = _query.sort(sort.mapValues(DBQuerySortOrder.init))
        }
        if let skip = query.skip {
            _query = _query.skip(skip)
        }
        if let limit = query.limit {
            _query = _query.limit(limit)
        }
        if let includes = query.includes {
            _query = _query.includes(includes)
        }
        
        return _query
    }
    
    func toArray(_ query: MDQuery) -> EventLoopFuture<[MDObject]> {
        
        do {
            
            let _query = try self._find(query)
            
            return _query.toArray().flatMapThrowing { try $0.map(MDObject.init) }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func forEach(_ query: MDQuery, _ body: @escaping (MDObject) throws -> Void) -> EventLoopFuture<Void> {
        
        do {
            
            let _query = try self._find(query)
            
            return _query.forEach { try body(MDObject($0)) }.map { _ in }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func first(_ query: MDQuery) -> EventLoopFuture<MDObject?> {
        return self.toArray(query.limit(1)).map { $0.first }
    }
    
    func findOneAndUpdate(_ query: MDQuery, _ update: [String : MDUpdateOperation], _ returning: MDQueryReturning) -> EventLoopFuture<MDObject?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            var _query = query.connection.connection.query().findOne(`class`)
            
            _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
            
            switch returning {
            case .before: _query = _query.returning(.before)
            case .after: _query = _query.returning(.after)
            }
            
            if let sort = query.sort {
                _query = _query.sort(sort.mapValues(DBQuerySortOrder.init))
            }
            if let includes = query.includes {
                _query = _query.includes(includes)
            }
            
            let update = update.mapValues(DBQueryUpdateOperation.init)
            
            return _query.update(update).flatMapThrowing { try $0.map(MDObject.init) }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndUpsert(_ query: MDQuery, _ update: [String : MDUpdateOperation], _ setOnInsert: [String : MDData], _ returning: MDQueryReturning) -> EventLoopFuture<MDObject?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            var _query = query.connection.connection.query().findOne(`class`)
            
            _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
            
            switch returning {
            case .before: _query = _query.returning(.before)
            case .after: _query = _query.returning(.after)
            }
            
            if let sort = query.sort {
                _query = _query.sort(sort.mapValues(DBQuerySortOrder.init))
            }
            if let includes = query.includes {
                _query = _query.includes(includes)
            }
            
            let update = update.mapValues(DBQueryUpdateOperation.init)
            var setOnInsert = setOnInsert.mapValues { $0.toDBData() }
            setOnInsert["id"] = DBData(objectIDGenerator())
            
            return _query.upsert(update, setOnInsert: setOnInsert).flatMapThrowing { try $0.map(MDObject.init) }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndDelete(_ query: MDQuery) -> EventLoopFuture<MDObject?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            var _query = query.connection.connection.query().findOne(`class`)
            
            _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
            
            if let sort = query.sort {
                _query = _query.sort(sort.mapValues(DBQuerySortOrder.init))
            }
            if let includes = query.includes {
                _query = _query.includes(includes)
            }
            
            return _query.delete().flatMapThrowing { try $0.map(MDObject.init) }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func deleteAll(_ query: MDQuery) -> EventLoopFuture<Int?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            var _query = query.connection.connection.query().find(`class`)
            
            _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
            
            return _query.delete()
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func insert(_ connection: MDConnection, _ class: String, _ data: [String: MDData]) -> EventLoopFuture<MDObject> {
        
        var data = data.mapValues(DBData.init)
        data["id"] = DBData(objectIDGenerator())
        
        return connection.connection.query().insert(`class`, data).flatMapThrowing { try MDObject($0) }
    }
    
    func withTransaction<T>(_ connection: MDConnection, _ transactionBody: @escaping () throws -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        
        do {
            
            guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
            
            return connection.withTransaction { _ in try transactionBody() }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}
