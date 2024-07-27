import Foundation

func runWithTimeout(timeout: UInt64, task: @escaping () async throws -> Void) -> Task<Void, Error> {
    let mainTask = Task { @MainActor in
        try await task()
    }

    let timeoutTask = Task {
        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        mainTask.cancel()
        print("Task cancelled due to timeout")
    }

    // Await both tasks and handle the results
//    async let result: Void = mainTask.value
//    async let _ = timeoutTask.value
    
    return mainTask
//
//    do {
//        try await result
//    } catch {
//        if Task.isCancelled {
//            print("Main task was cancelled")
//        } else {
//            print("An error occurred: \(error)")
//        }
//    }
}
