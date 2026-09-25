//
//  Observe.swift
//  Magpie
//

import Foundation
import Observation

/// Calls `onChange` with the current result of `value`, then again whenever an `@Observable` property it reads changes.
///
/// Changes made together are delivered once, on the main actor. Consecutive equal values are skipped. Cancel the returned task to stop observing.
@discardableResult
func observe<T: Equatable>(_ value: @escaping @MainActor @Sendable () -> T, onChange: @escaping @MainActor (T) -> Void) -> Task<Void, Never> {
    return Task { @MainActor in
        var last: T?
        for await current in Observations(value) {
            if let previous = last, previous == current {
                continue
            }
            last = current
            onChange(current)
        }
    }
}

/// Like `observe(_:onChange:)`, for values that aren't `Equatable`. Every change is delivered.
@discardableResult
func observeAll<T>(_ value: @escaping @MainActor @Sendable () -> T, onChange: @escaping @MainActor (T) -> Void) -> Task<Void, Never> {
    return Task { @MainActor in
        for await current in Observations(value) {
            onChange(current)
        }
    }
}
