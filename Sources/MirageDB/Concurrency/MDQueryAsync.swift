//
//  MDQueryAsync.swift
//
//  The MIT License
//  Copyright (c) 2021 - 2022 O2ter Limited. All rights reserved.
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

#if compiler(>=5.5.2) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDFindExpression {
    
    public func count() async throws -> Int {
        return try await self.count().get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDFindExpression {
    
    public func toArray() async throws -> [MDObject] {
        return try await self.toArray().get()
    }
    
    public func forEach(_ body: @escaping (MDObject) throws -> Void) async throws {
        return try await self.forEach(body).get()
    }
    
    public func toStream() -> AsyncThrowingStream<MDObject, Error> {
        
        return AsyncThrowingStream { continuation in
            
            self.forEach { continuation.yield($0) }.whenComplete { result in
                switch result {
                case .success: continuation.finish()
                case let .failure(error): continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func first() async throws -> MDObject? {
        return try await self.first().get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDQuery {
    
    @discardableResult
    public func insert(_ class: String, _ data: [String: MDData]) async throws -> MDObject {
        return try await self.insert(`class`, data).get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDFindExpression {
    
    @discardableResult
    public func delete() async throws -> Int? {
        return try await self.delete().get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDFindOneExpression {
    
    @discardableResult
    public func update(_ update: [String: MDDataConvertible]) async throws -> MDObject? {
        return try await self.update(update).get()
    }
    
    @discardableResult
    public func update(_ update: [String: MDUpdateOption]) async throws -> MDObject? {
        return try await self.update(update).get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDFindOneExpression {
    
    @discardableResult
    public func upsert(_ upsert: [String: MDDataConvertible]) async throws -> MDObject? {
        return try await self.upsert(upsert).get()
    }
    
    @discardableResult
    public func upsert(_ upsert: [String: MDUpsertOption]) async throws -> MDObject? {
        return try await self.upsert(upsert).get()
    }
    
    @discardableResult
    public func upsert(_ update: [String: MDDataConvertible], setOnInsert: [String: MDDataConvertible]) async throws -> MDObject? {
        return try await self.upsert(update, setOnInsert: setOnInsert).get()
    }
    
    @discardableResult
    public func upsert(_ update: [String: MDUpdateOption], setOnInsert: [String: MDDataConvertible]) async throws -> MDObject? {
        return try await self.upsert(update, setOnInsert: setOnInsert).get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDFindOneExpression {
    
    @discardableResult
    public func update(_ update: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        return try await self.update(update).get()
    }
    
    @discardableResult
    public func update(_ update: [MDQueryKey: MDUpdateOption]) async throws -> MDObject? {
        return try await self.update(update).get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDFindOneExpression {
    
    @discardableResult
    public func upsert(_ upsert: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        return try await self.upsert(upsert).get()
    }
    
    @discardableResult
    public func upsert(_ upsert: [MDQueryKey: MDUpsertOption]) async throws -> MDObject? {
        return try await self.upsert(upsert).get()
    }
    
    @discardableResult
    public func upsert(_ update: [MDQueryKey: MDDataConvertible], setOnInsert: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        return try await self.upsert(update, setOnInsert: setOnInsert).get()
    }
    
    @discardableResult
    public func upsert(_ update: [MDQueryKey: MDUpdateOption], setOnInsert: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        return try await self.upsert(update, setOnInsert: setOnInsert).get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDFindOneExpression {
    
    @discardableResult
    public func delete() async throws -> MDObject? {
        return try await self.delete().get()
    }
}

#endif
