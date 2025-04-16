//
//  HasLazyServerTests.swift
//  HasLazyServer
//
//  Created by kin on 4/16/25.
//

import XCTest

@testable import HasLazyServer
@testable import FullyRESTful

final class MaybeTests: XCTestCase {
    func testMaybeString() throws {
        let jsons = [
            #"{"title": "Hello"}"#,
            #"{"title": 123}"#,
            #"{"title": 123}"#,
            #"{"title": 123.456}"#
        ]
        
        for json in jsons {
            let data = json.data(using: .utf8)!
            struct Model: Codable { let title: MaybeString }
            let decoded = try JSONDecoder().decode(Model.self, from: data)
            print("Decoded title:", decoded.title.asString)
        }
    }
    
    func testMaybeNumber() throws {
        let jsons = [
            #"{"price": 100}"#,
            #"{"price": 123.45}"#,
            #"{"price": "999"}"#,
            #"{"price": "456.78"}"#
        ]
        
        for json in jsons {
            let data = json.data(using: .utf8)!
            struct Model: Codable { let price: MaybeNumber }
            let decoded = try JSONDecoder().decode(Model.self, from: data)
            print("Decoded price asInt:", decoded.price.asInt)
            print("Decoded price asDouble:", decoded.price.asDouble)
        }
    }
    
}

final class SometimeTests: XCTestCase {
    func testSometimeArrayString() throws {
        let single = #"{"tags": "swift"}"#.data(using: .utf8)!
        let multiple = #"{"tags": ["swift", "json"]}"#.data(using: .utf8)!
        
        struct Model: Codable { let tags: SometimeArray<String> }
        
        let one = try JSONDecoder().decode(Model.self, from: single)
        let many = try JSONDecoder().decode(Model.self, from: multiple)
        
        XCTAssertEqual(one.tags.asArray, ["swift"])
        XCTAssertEqual(many.tags.asArray, ["swift", "json"])
    }
    
    func testSometimeArrayNumber() throws {
        let single = #"{"values": 1}"#.data(using: .utf8)!
        let multiple = #"{"values": [1, 2, 3]}"#.data(using: .utf8)!
        
        struct Model: Codable { let values: SometimeArray<Int> }
        
        let one = try JSONDecoder().decode(Model.self, from: single)
        let many = try JSONDecoder().decode(Model.self, from: multiple)
        
        XCTAssertEqual(one.values.asArray, [1])
        XCTAssertEqual(many.values.asArray, [1,2,3])
    }
    
    func testSometimeArrayObject() throws {
        let single = #"{"items": {"id": 1}}"#.data(using: .utf8)!
        let multiple = #"{"items": [{"id": 1}, {"id": 2}]}"#.data(using: .utf8)!
        
        struct Item: Codable, Equatable { let id: Int }
        struct Model: Codable { let items: SometimeArray<Item> }
        
        let one = try JSONDecoder().decode(Model.self, from: single)
        let many = try JSONDecoder().decode(Model.self, from: multiple)
        
        XCTAssertEqual(one.items.asArray, [Item(id: 1)])
        XCTAssertEqual(many.items.asArray, [Item(id: 1), Item(id: 2)])
    }
    
}

final class InInsistsTests: XCTestCase {
    func testOptionalFallback() throws {
        let present = #"{"name": "Alice"}"#.data(using: .utf8)!
        let missing = #"{"name": null}"#.data(using: .utf8)!
        
        struct User: Codable { let name: InsistsNonNull<String> }
        
        let user1 = try JSONDecoder().decode(User.self, from: present)
        XCTAssertEqual(user1.name.value, "Alice")
        
        let user2 = try JSONDecoder().decode(User.self, from: missing)
        XCTAssertNil(user2.name.value)
    }
    
}

final class FullFullyRestfulTest: XCTestCase {
    // Optional: you can define actual API test if you want to mock or hit real endpoints.
    // For now, just a placeholder.
    func testCompile() {
        struct Item: Codable {
            let price: MaybeNumber
            let title: MaybeString
        }
        let jsonList = [
            #"{"price": 100.0, "title": "Book"}"#,
            #"{"price": "100.0", "title": 3001}"#,
        ]
        jsonList.forEach {
            let item:Item? = $0.data?.makeObj()
            print("💰 Price as Double:", item?.price.asDouble)
            print("💰 Price as Int:", item?.price.asInt)
            print("🪪 Title:", item?.title.asString)
        }
        
        
        struct User: Codable {
            let name: String
            let email: String?
            let age: MaybeNumber?
        }
        struct UserList: Codable {
            let users: SometimeArray<User>
        }
        let jsonList2 = [
            #"{"users":{"name": "john", "email": "john@example.com", "age": "30"}}"#,
            #"{"users":[{"name": "john1", "email": "john1@example.com", "age": 30},{"name": "john2", "email": "john2@example.com", "age": "30"}]}"#
        ]
        jsonList2.forEach {
            let userList:UserList? = $0.data?.makeObj()
            userList?.users.asArray.forEach {
                print($0.name)
                print($0.email)
                print($0.age?.asInt)
            }
        }
        
        struct Book : Codable {
            let name:MaybeString
            let author:MaybeString
            let price:InsistsNonNull<MaybeNumber>
            let code:MaybeString?
        }
        struct Search : APIITEM {
            struct Request : Codable {
                let searchText:String
            }
            struct Response : Codable {
                let items:SometimeArray<Book>
                let totalCount:MaybeNumber
            }
            let requestModel = Request.self
            let responseModel = Response.self
            var method:HTTPMethod = .GET
            var customHeader: [String : String]?
            let server: ServerInfo = .init(domain: "https://myServer.com:8080", defaultHeader: ["Content-Type": "application/json; utf-8"])
            let path = "/library/books/search"
        }
        Task {
            let bookList = try? await Search().request(param: .init(searchText: "API Docs"))?.model?.items.asArray
            bookList?.forEach {
                print($0.name.asString)
                print($0.author.asString)
            }
        }
        
        XCTAssertTrue(true)
    }
}
