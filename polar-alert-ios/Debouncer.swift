import Foundation

class Debouncer {
    private var workItem: DispatchWorkItem?
    
    func debounce(_ delay: DispatchTimeInterval, action: @escaping () -> Void) {
        // Cancel the previous work item if it exists
        workItem?.cancel()
        
        // Create a new work item with the action
        workItem = DispatchWorkItem { [weak self] in
            action()
            self?.workItem = nil
        }
        
        // Schedule the new work item
        if let workItem = workItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
}
