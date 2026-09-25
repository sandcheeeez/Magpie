//
//  ClipAnalyzerTests.swift
//  MagpieTests
//

import Testing
import AppKit
@testable import Magpie

@Suite struct ClipAnalyzerTests {
    
    private func analyze(_ text: String) -> ClipAnalysis {
        return ClipAnalyzer.analyze([.string: Data(text.utf8)])
    }
    
    // MARK: Kinds
    
    @Test func kindComesFromTheData() {
        let url = URL(fileURLWithPath: "/Applications/Safari.app")
        #expect(ClipAnalyzer.analyze([.fileURL: url.dataRepresentation]).kind == .file)
        #expect(ClipAnalyzer.analyze([.tiff: Data([0])]).kind == .image)
        #expect(analyze("https://apple.com").kind == .link)
        #expect(analyze("hello there").kind == .text)
    }
    
    @Test func sizeAndCountsAreRecorded() {
        let analysis = analyze("héllo")
        #expect(analysis.characterCount == 5)
        #expect(analysis.byteCount == 6)
    }
    
    @Test func searchTextIsFolded() {
        #expect(analyze("Café ÜBER").searchText == "cafe uber")
    }
    
    @Test func fileSearchTextIncludesTheName() {
        let url = URL(fileURLWithPath: "/Users/me/Documents/Report.pdf")
        #expect(ClipAnalyzer.analyze([.fileURL: url.dataRepresentation]).searchText.contains("report.pdf"))
    }
    
    // MARK: Colours
    
    @Test(arguments: ["#598CF2", "#fff", "#598cf280", " #598CF2\n", "rgb(89, 140, 242)", "rgba(89,140,242,0.5)", "hsl(220, 85%, 65%)", "rgb(89 140 242 / 50%)"])
    func colourTextIsAColour(text: String) {
        #expect(analyze(text).kind == .color)
        #expect(ClipAnalyzer.color(fromText: text) != nil)
    }
    
    @Test(arguments: ["598CF2", "123456", "#12345", "#ggg", "rgb(300, 0, 0)", "the colour #598CF2 is nice"])
    func otherTextIsNotAColour(text: String) {
        #expect(analyze(text).kind != .color)
    }
    
    @Test func hexIsParsedExactly() throws {
        let color = try #require(ClipAnalyzer.color(fromText: "#598CF2")?.usingColorSpace(.sRGB))
        #expect(Int(round(color.redComponent * 255)) == 0x59)
        #expect(Int(round(color.greenComponent * 255)) == 0x8C)
        #expect(Int(round(color.blueComponent * 255)) == 0xF2)
    }
    
    // MARK: Code
    
    @Test(arguments: [
        ("import SwiftUI\n\nstruct ContentView: View {\n    var body: some View {\n        Text(\"Hi\")\n    }\n}", "Swift"),
        ("guard let url = URL(string: s) else { return }", "Swift"),
        ("def greet(name):\n    print(f\"Hello {name}\")\n", "Python"),
        ("const add = (a, b) => a + b;\nconsole.log(add(1, 2));", "JavaScript"),
        ("interface User {\n  name: string;\n  age: number;\n}", "TypeScript"),
        ("git commit -m \"Fix bug\" && git push", "Shell"),
        ("#!/bin/bash\necho hello", "Shell"),
        ("SELECT name, email FROM users WHERE id = 1;", "SQL"),
        ("<div class=\"card\">\n  <p>Hello</p>\n</div>", "HTML"),
        ("{\"name\": \"Magpie\", \"version\": 1}", "JSON"),
        ("package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"hi\")\n}", "Go"),
        ("fn main() {\n    let mut x = 5;\n    println!(\"{}\", x);\n}", "Rust"),
        ("#include <stdio.h>\nint main() { printf(\"hi\"); }", "C/C++"),
        (".card {\n  color: red;\n  padding: 4px;\n}", "CSS"),
    ])
    func codeIsDetected(code: String, language: String) {
        let analysis = analyze(code)
        #expect(analysis.kind == .code)
        #expect(analysis.codeLanguage == language)
        #expect(analysis.tags.contains(language))
        #expect(analysis.lineCount == code.split(separator: "\n", omittingEmptySubsequences: false).count)
    }
    
    @Test(arguments: [
        "Let me know if you can make it to the meeting on Friday.",
        "Import duties apply to all shipments over $100.",
        "The function of this committee is to review proposals (see appendix A).",
        "482913",
        "Shopping list: eggs, milk, bread",
    ])
    func proseIsNotCode(text: String) {
        #expect(analyze(text).kind == .text)
    }
    
    // MARK: Tags
    
    @Test func emailsAndPhoneNumbersAreTagged() {
        let tags = analyze("Contact jane@example.com or call +1 (555) 123-4567").tags
        #expect(tags.contains("Email"))
        #expect(tags.contains("Phone"))
    }
    
    @Test func plainTextHasNoTags() {
        #expect(analyze("just a note to self").tags.isEmpty)
    }
}
