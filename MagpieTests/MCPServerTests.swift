//
//  MCPServerTests.swift
//  MagpieTests
//

import Testing
import AppKit
import SwiftData
@testable import Magpie

@Suite struct MCPServerTests {
    
    let history: History
    let container: ModelContainer
    
    init() throws {
        container = try HistoryStore.makeContainer(inMemory: true)
        history = History(container: container, persistsSettings: false)
        history.insert(data: [.string: Data("def greet(name):\n    print(f\"Hello {name}\")\n".utf8)], sourceBundleId: nil)
        history.insert(data: [.string: Data("Call me on +1 (555) 123-4567".utf8)], sourceBundleId: nil)
        history.insert(data: [.string: Data("https://github.com/sandcheeeez/Magpie".utf8)], sourceBundleId: nil)
        history.setPinned(true, forItemAt: 0)
    }
    
    private func request(_ server: MCPServer, _ method: String, _ params: [String: Any] = [:], id: Int = 1) throws -> [String: Any] {
        let message: [String: Any] = ["jsonrpc": "2.0", "id": id, "method": method, "params": params]
        let response = try #require(server.handle(try JSONSerialization.data(withJSONObject: message)))
        return try #require(try JSONSerialization.jsonObject(with: response) as? [String: Any])
    }
    
    /// Calls a tool and returns its result, decoding the JSON text content.
    private func call(_ server: MCPServer, _ tool: String, _ arguments: [String: Any] = [:]) throws -> (json: [String: Any]?, isError: Bool, content: [[String: Any]]) {
        let response = try request(server, "tools/call", ["name": tool, "arguments": arguments])
        let result = try #require(response["result"] as? [String: Any])
        let content = try #require(result["content"] as? [[String: Any]])
        let text = content.first?["text"] as? String ?? ""
        let json = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any]
        return (json, result["isError"] as? Bool ?? false, content)
    }
    
    @Test func initializeAndListTools() throws {
        let server = MCPServer(container: container, isAllowed: { true })
        let initialize = try request(server, "initialize", ["protocolVersion": "2025-06-18"])
        let result = try #require(initialize["result"] as? [String: Any])
        #expect(result["protocolVersion"] as? String == "2025-06-18")
        #expect((result["serverInfo"] as? [String: Any])?["name"] as? String == "magpie")
        
        let tools = try #require((try request(server, "tools/list")["result"] as? [String: Any])?["tools"] as? [[String: Any]])
        #expect(tools.compactMap({ $0["name"] as? String }) == ["list_clipboard_history", "search_clipboard_history", "get_clipboard_item"])
    }
    
    @Test func notificationsGetNoReply() throws {
        let server = MCPServer(container: container, isAllowed: { true })
        let notification = try JSONSerialization.data(withJSONObject: ["jsonrpc": "2.0", "method": "notifications/initialized"])
        #expect(server.handle(notification) == nil)
    }
    
    @Test func unknownMethodsAreErrors() throws {
        let server = MCPServer(container: container, isAllowed: { true })
        let error = try #require(try request(server, "resources/list")["error"] as? [String: Any])
        #expect(error["code"] as? Int == -32601)
    }
    
    @Test func nothingIsSharedUntilTheUserAllowsIt() throws {
        let server = MCPServer(container: container, isAllowed: { false })
        let result = try call(server, "list_clipboard_history")
        #expect(result.isError)
        #expect(result.json == nil)
    }
    
    @Test func listsNewestFirstWithFilters() throws {
        let server = MCPServer(container: container, isAllowed: { true })
        let all = try #require(try call(server, "list_clipboard_history").json?["items"] as? [[String: Any]])
        #expect(all.compactMap({ $0["kind"] as? String }) == ["link", "text", "code"])
        #expect(all.first?["pinned"] as? Bool == true)
        
        let code = try #require(try call(server, "list_clipboard_history", ["kind": "code"]).json?["items"] as? [[String: Any]])
        #expect(code.count == 1)
        #expect(code.first?["language"] as? String == "Python")
        
        let phones = try #require(try call(server, "list_clipboard_history", ["tag": "phone"]).json?["items"] as? [[String: Any]])
        #expect(phones.count == 1)
        
        let limited = try #require(try call(server, "list_clipboard_history", ["limit": 1]).json?["items"] as? [[String: Any]])
        #expect(limited.count == 1)
    }
    
    @Test func searchesAndGetsFullItems() throws {
        let server = MCPServer(container: container, isAllowed: { true })
        let results = try #require(try call(server, "search_clipboard_history", ["query": "greet"]).json?["results"] as? [[String: Any]])
        #expect(results.count == 1)
        let id = try #require(results.first?["id"] as? String)
        
        let item = try #require(try call(server, "get_clipboard_item", ["id": id]).json)
        #expect((item["text"] as? String)?.hasPrefix("def greet(name):") == true)
        
        let missing = try call(server, "get_clipboard_item", ["id": UUID().uuidString])
        #expect(missing.isError)
    }
}
