//
//  DBData.swift
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

extension MDData {
    
    init(_ data: DBData) throws {
        switch data.base {
        case .null: self = nil
        case let .boolean(value): self.init(value)
        case let .string(value): self.init(value)
        case let .signed(value): self.init(value)
        case let .unsigned(value): self.init(value)
        case let .number(value): self.init(value)
        case let .decimal(value): self.init(value)
        case let .timestamp(value): self.init(value)
        case let .date(value):
            if value.containsDate(), let date = MDDate(value) {
                self.init(date)
            } else if value.containsTime(), let time = MDTime(value) {
                self.init(time)
            } else {
                throw MDError.unsupportedType
            }
        case let .array(value): try self.init(value.map(MDData.init))
        case let .dictionary(value): try self.init(value.mapValues(MDData.init))
        default: throw MDError.unsupportedType
        }
    }
}

extension MDData: DBDataConvertible {
    
    public func toDBData() -> DBData {
        switch base {
        case .null: return nil
        case let .boolean(value): return DBData(value)
        case let .string(value): return DBData(value)
        case let .integer(value): return DBData(value)
        case let .number(value): return DBData(value)
        case let .decimal(value): return DBData(value)
        case let .timestamp(value): return DBData(value)
        case let .date(value): return DBData(value.dateComponents)
        case let .time(value): return DBData(value.dateComponents)
        case let .array(value): return DBData(value.map { $0.toDBData() })
        case let .dictionary(value): return DBData(value.mapValues { $0.toDBData() })
        }
    }
}