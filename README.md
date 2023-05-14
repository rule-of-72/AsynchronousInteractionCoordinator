# Asynchronous Interaction Coordinator

This package contains three libraries:
- Interaction Queue
- Async Operations
- Concurrent KVO

## Interaction Queue

Coordinate a sequence of modal user interactions.

### Scenario

Apps may need to present several modal interactions to the user, especially at startup.

For example:
- Requesting permission to use location.
- Requestion permission to use the camera.
- Prompting the user for credentials or biometric verification.
- Displaying an important notification about service availability.

It can be challenging to coordinate many such interactions:
- You want to present the interactions one at a time, so one modal view doesn’t cover another.
- You want to be sure that each interaction is finished before the next one appears.
- You want to account for interactions that may not need to appear, depending on circumstances.

### Solution

Use the **InteractionQueue** to coordinate your interactions.

Each interaction presents its user interface and waits for the user’s response. The queue ensures that the next interaction doesn’t present its UI until the previous interaction has finished.
 
InteractionQueue is agnostic about which asynchronous programming model any particular interaction is using:
- Delegates (for example, UIDocumentPickerViewController)
- Completion blocks (for example, UIAlertController)
- Async/await (for example, StoreKit 2)

InteractionQueue is also thread-safe. Although it always starts interactions on the main (UI) queue, it can mark the running interaction as finished from any queue or thread.
 
### Usage

1. Place an instance of `InteractionQueue` in your main view controller.

```swift
import InteractionQueue
⋮
private let interactionQueue = InteractionQueue()
```

2. Tell the queue when your view appears and disappears.

The queue suspends itself when your view isn’t on screen.

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    interactionQueue.onViewDidAppear()
}

override func viewWillDisappear(_ animated: Bool) {
    interactionQueue.onViewWillDisappear()
    super.viewWillDisappear(animated)
}
```

3. Add interactive, modal UI operations to the interaction queue.

The interaction queue adds one operation at a time to the main (UI) queue and blocks until it’s finished.

```swift
interactionQueue.add { markInteractionFinished in
    doSomethingWithEscapingCompletionBlock {
        [weak self] in
        defer { markOperationAsFinished() }
        guard let self = self else { return }

        // Rest of the completion block...
    }
}
```

4. Mark each operation as finished.

The queue passes a callback function (`markInteractionFinished`) into the operation closure. You **must** call this function when you are finished with the interaction, even if the interaction gets cancelled or isn’t needed.

This is the only way to unblock the queue and proceed with the next interaction.

*Hint:* Put the call into a `defer` block, as in the example above, **before** testing `weak self` for `nil`.

Even if `self` has been dealloced/deinited, you will leak the queue and operation objects if you don’t mark the operation as finished, because the OS itself still retains strong references to them.

There are additional advantages to requiring an explicit mark-as-finished:
- The queue never _guesses_ about when an interaction is finished.
    - For example, when a specific view disappears or an animation completes.
- The queue handles interactions that require showing _multiple_ modal views.
    - For example, a confirmation alert that appears after the user taps Delete in an action sheet.
- The queue handles interactions that may not need to show UI, depending on the situation.
    - For example, if the app already has permission to access a specific resource.
    - Avoid special-case code by always putting the interaction on the queue. It can call `markInteractionFinished()` immediately if it doesn’t need to interact with the user.


## Async Operation

An asynchronous `Operation` for use with an `OperationQueue`.

- In this context, “asynchronous” means the operation isn’t really finished when its function / block / closure returns.
- Normally, that return tells the queue that the operation is complete and it can proceed to the next operation.
- In contrast, the async operation holds up the queue until it explicitly indicates that it’s finished.

Typical scenarios:
- The operation calls a function that takes an `@escaping` completion block (closure) as a parameter.
    - The operation isn’t finished until the completion block gets called.
    - Other operations may depend on a result that gets delivered in the completion block. `OperationQueue` needs an accurate indication of completion in order to schedule the dependent tasks.
- The operation contains a `Task` that uses `await` to call an `async` function.
    - The operation isn’t finished until the entire `Task` completes.
- The operation presents a modal user interface that requires the user to interact with it.
    - The operation isn’t complete until the user dismisses the modal UI.
