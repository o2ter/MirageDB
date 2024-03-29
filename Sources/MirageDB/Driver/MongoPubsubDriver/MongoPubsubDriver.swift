//
//  MongoPubsubDriver.swift
//
//  The MIT License
//  Copyright (c) 2021 - 2024 O2ter Limited. All rights reserved.
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

struct MongoPubsubDriver: MDPubsubDriver {
    
    func publish(
        _ connection: MDConnection,
        _ channel: String,
        _ message: MDData
    ) async throws {
        
        try await connection.connection.mongoPubSub().publish(message.toBSON(), to: channel)
    }
    
    func subscribe(
        _ connection: MDConnection,
        _ channel: String,
        @UnsafeSendable _ handler: @escaping (_ channel: String, _ message: MDData) -> Void
    ) async throws {
        
        try await connection.connection.mongoPubSub().subscribe(channel: channel) { connection, channel, message in
            
            do {
                
                $handler.wrappedValue(channel, try MDData(message))
                
            } catch {
                
                connection.logger.error("\(error)")
            }
        }
    }
    
    func unsubscribe(
        _ connection: MDConnection,
        _ channel: String
    ) async throws {
        
        await connection.connection.mongoPubSub().unsubscribe(channel: channel)
    }
    
}
