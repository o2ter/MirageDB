//
//  MongoDBTest.swift
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

import MirageDB
import XCTest

class MongoDBTest: XCTestCase {
    
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    var connection: MDConnection!
    
    override func setUpWithError() throws {
        
        do {
            
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            
            var url = URLComponents()
            url.scheme = "mongodb"
            url.host = env("MONGO_HOST") ?? "localhost"
            url.user = env("MONGO_USERNAME")
            url.password = env("MONGO_PASSWORD")
            url.path = "/\(env("MONGO_DATABASE") ?? "")"
            
            var queryItems: [URLQueryItem] = []
            
            if let authSource = env("MONGO_AUTHSOURCE") {
                queryItems.append(URLQueryItem(name: "authSource", value: authSource))
            }
            
            if let ssl_mode = env("MONGO_SSLMODE") {
                queryItems.append(URLQueryItem(name: "ssl", value: "true"))
                queryItems.append(URLQueryItem(name: "sslmode", value: ssl_mode))
            }
            
            url.queryItems = queryItems.isEmpty ? nil : queryItems
            
            self.connection = try MDConnection.connect(url: url, on: eventLoopGroup).wait()
            
            print("MONGO:", try connection.version().wait())
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    override func tearDownWithError() throws {
        
        do {
            
            try self.connection.close().wait()
            try eventLoopGroup.syncShutdownGracefully()
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testCreateTable() throws {
        
        do {
            
            try connection.createTable(MDSQLTable(
                name: "testCreateTable",
                columns: [
                    .init(name: "name", type: .string),
                    .init(name: "age", type: .integer),
                ]
            )).wait()
            
            let obj1 = try connection.query()
                .class("testCreateTable")
                .insert([
                    "name": "John",
                    "age": 10,
                ]).wait()
            
            XCTAssertEqual(obj1.id?.count, 10)
            XCTAssertEqual(obj1["name"], "John")
            XCTAssertEqual(obj1["age"], 10)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testUpdateQuery() throws {
        
        do {
            
            try connection.createTable(MDSQLTable(
                name: "testUpdateQuery",
                columns: [
                    .init(name: "col", type: .string),
                ]
            )).wait()
            
            var obj = MDObject(class: "testUpdateQuery")
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj.id?.count, 10)
            
            obj["col"] = "text_1"
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["col"].string, "text_1")
            
            let obj2 = try connection.query()
                .class("testUpdateQuery")
                .filter { $0.id == obj.id }
                .findOneAndUpdate([
                    "col": .set("text_2")
                ]).wait()
            
            XCTAssertEqual(obj2?.id, obj.id)
            XCTAssertEqual(obj2?["col"].string, "text_2")
            
            let obj3 = try connection.query()
                .class("testUpdateQuery")
                .filter { $0.id == obj.id }
                .findOneAndUpdate([
                    "col": .set("text_3")
                ], returning: .before).wait()
            
            XCTAssertEqual(obj3?.id, obj.id)
            XCTAssertEqual(obj3?["col"].string, "text_2")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testUpsertQuery() throws {
        
        do {
            
            try connection.createTable(MDSQLTable(
                name: "testUpsertQuery",
                columns: [
                    .init(name: "col", type: .string),
                ]
            )).wait()
            
            let obj = try connection.query()
                .class("testUpsertQuery")
                .filter { $0["col"] == "text_1" }
                .findOneAndUpsert([
                    "col": .set("text_1")
                ]).wait()
            
            XCTAssertEqual(obj.id?.count, 10)
            XCTAssertEqual(obj["col"].string, "text_1")
            
            let obj2 = try connection.query()
                .class("testUpsertQuery")
                .filter { $0.id == obj.id }
                .findOneAndUpsert([
                    "col": .set("text_2")
                ]).wait()
            
            XCTAssertEqual(obj2.id, obj.id)
            XCTAssertEqual(obj2["col"].string, "text_2")
            
            let obj3 = try connection.query()
                .class("testUpsertQuery")
                .filter { $0.id == obj.id }
                .findOneAndUpsert([
                    "col": .set("text_3")
                ], returning: .before).wait()
            
            XCTAssertEqual(obj3.id, obj.id)
            XCTAssertEqual(obj3["col"].string, "text_2")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
}