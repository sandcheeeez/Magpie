//
//  main.swift
//  Magpie
//

import AppKit

// `Magpie --mcp` runs a local MCP server over stdin/stdout instead of the app, so AI assistants can read the history when the user allows it.
if CommandLine.arguments.contains("--mcp") {
    MCPServer.runStdio()
    exit(0)
}

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
