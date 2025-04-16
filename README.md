# HasLazyServer

> Coping tools for gaslighting JSON.

## 🧩 The Problem: “Just Pick a Type. Please.”

Sometimes it's a number.
Sometimes it's a string.
Sometimes it's null.
Sometimes it's a whole object pretending to be a number.
And the API doc? It swears it's always an `Int`.

## 🧠 The Solution

You can't change the backend.
But you can protect your decoder — and your sanity.

HasLazyServer provides Codable types that accept the chaos, convert it safely, and log when things go sideways (in DEBUG).

## ✅ MaybeString & MaybeNumber

These types help you decode values that shift between string, int, or double.
They normalize the result to a usable format, and log inconsistencies.

```swift
struct Item: Codable {
    let price: MaybeNumber
    let title: MaybeString
}
let jsonList = [
    #"{"price": 100.0, "title": "Book"}"#,
    #"{"price": "100.0", "title": 3001}"#,
]
jsonList.forEach {
    guard let item:Item = $0.data?.makeObj() else {return}
    print("💰 Price as Double:", item.price.asDouble)
    print("💰 Price as Int:", item.price.asInt)
    print("🪪 Title:", item.title.asString)
}
```
#### result
```bash
💰 Price as Double: Optional(100.0)
💰 Price as Int: Optional(100)
🪪 Title: Optional("Book")
⚠️ [MaybeNumber] 'price' got String instead of Int/Double
⚠️ [MaybeString] 'title' got Int instead of String
💰 Price as Double: Optional(100.0)
💰 Price as Int: Optional(100)
🪪 Title: Optional("3001")
```

## ✅ SometimeArray

Sometimes you get one, sometimes many.
SometimeArray remembers which it was —
but gives you .asArray when you just want to move on.
```swift
struct User: Codable {
    let name: String
    let email: String?
    let age: MaybeNumber?
}
struct UserList: Codable {
    let users: SometimeArray<User>
}
let jsonList = [
    #"{"name": "john", "email": "john@example.com", "age": "30"}"#,
    #"[{"name": "john1", "email": "john1@example.com", "age": 30},{"name": "john2", "email": "john2@example.com", "age": "30"}]"#
]
jsonList.forEach {
    guard let userList:UserList = $0.data?.makeObj() else { return }
    userList.users.asArray.forEach {
        print($0.name)
        print($0.email)
        print($0.age)
    }
}
```
#### result
```bash
⚠️ [MaybeNumber] 'users.age' got String instead of Int/Double
john
Optional("john@example.com")
Optional(30)
⚠️ [MaybeNumber] 'users.Index 1.age' got String instead of Int/Double
john1
Optional("john1@example.com")
Optional(30)
john2
Optional("john2@example.com")
Optional(30)
```

## 🔍 Debug Output

In DEBUG builds, HasLazyServer prints logs for type mismatches.
So you know *when* and *where* your trust was betrayed.
```bash
⚠️ [MaybeNumber] 'price' got String instead of Int/Double
⚠️ [MaybeString] 'title' got Int instead of String
```

## 🧪 Full Example with API Layer

These types work great standalone — but also integrate cleanly with [FullyRESTful](https://github.com/southkin/FullyRESTFul),
a declarative Swift API library for REST and WebSocket.
```swift
import FullyRESTful

struct Book : Codable {
    let name:MaybeString
    let author:MaybeString
    let price:MaybeNumber
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
```

## 🎁 Bonus: InsistsNonNull

When something is *supposed* to never be null,
but reality disagrees — this type lets you keep going,
while leaving a paper trail in your logs.
```swift
let price:InsistsNonNull<MaybeNumber>
```

## 🧘 Closing Thoughts

Your app deserves to live.
You deserve to sleep.

Let HasLazyServer handle the weird stuff.
And protect your mental health — it's the only real production system you run.

---

## 📄 License

MIT License
