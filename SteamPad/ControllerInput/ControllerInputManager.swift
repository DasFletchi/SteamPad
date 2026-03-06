import Foundation
import GameController

// MARK: - Controller Input Manager
//
// Translates Apple GameController framework inputs (MFi, Xbox, DualSense, DualShock)
// into Windows XInput button/axis events that Wine can consume.
// Also provides a virtual on-screen gamepad for touch-only usage.

class ControllerInputManager: ObservableObject {
    @Published var connectedControllers: [GCController] = []
    @Published var isUsingTouchControls = true

    // XInput state (what the game sees through Wine)
    @Published var xinputState = XInputState()

    // MARK: - XInput State Model
    struct XInputState {
        var leftStickX: Float = 0
        var leftStickY: Float = 0
        var rightStickX: Float = 0
        var rightStickY: Float = 0
        var leftTrigger: Float = 0
        var rightTrigger: Float = 0
        var buttons: UInt16 = 0

        // XInput button masks
        static let DPAD_UP: UInt16      = 0x0001
        static let DPAD_DOWN: UInt16    = 0x0002
        static let DPAD_LEFT: UInt16    = 0x0004
        static let DPAD_RIGHT: UInt16   = 0x0008
        static let START: UInt16        = 0x0010
        static let BACK: UInt16         = 0x0020
        static let LEFT_THUMB: UInt16   = 0x0040
        static let RIGHT_THUMB: UInt16  = 0x0080
        static let LEFT_SHOULDER: UInt16  = 0x0100
        static let RIGHT_SHOULDER: UInt16 = 0x0200
        static let A: UInt16            = 0x1000
        static let B: UInt16            = 0x2000
        static let X: UInt16            = 0x4000
        static let Y: UInt16            = 0x8000
    }

    // MARK: - Start Listening

    func startListening() {
        // Watch for controller connects/disconnects
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil, queue: .main
        ) { [weak self] notification in
            if let controller = notification.object as? GCController {
                self?.controllerConnected(controller)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil, queue: .main
        ) { [weak self] notification in
            if let controller = notification.object as? GCController {
                self?.controllerDisconnected(controller)
            }
        }

        // Pick up any already-connected controllers
        GCController.controllers().forEach { controllerConnected($0) }

        print("[Input] Controller listener active. Connected: \(connectedControllers.count)")
    }

    // MARK: - Controller Connected

    private func controllerConnected(_ controller: GCController) {
        connectedControllers.append(controller)
        isUsingTouchControls = false

        print("[Input] Controller connected: \(controller.vendorName ?? "Unknown")")

        // Map extended gamepad inputs to XInput
        if let gamepad = controller.extendedGamepad {
            mapExtendedGamepad(gamepad)
        }
    }

    private func controllerDisconnected(_ controller: GCController) {
        connectedControllers.removeAll { $0 == controller }
        if connectedControllers.isEmpty {
            isUsingTouchControls = true
        }
        print("[Input] Controller disconnected: \(controller.vendorName ?? "Unknown")")
    }

    // MARK: - Map Apple GameController → XInput

    private func mapExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        // Thumbsticks
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, x, y in
            self?.xinputState.leftStickX = x
            self?.xinputState.leftStickY = y
        }
        gamepad.rightThumbstick.valueChangedHandler = { [weak self] _, x, y in
            self?.xinputState.rightStickX = x
            self?.xinputState.rightStickY = y
        }

        // Triggers
        gamepad.leftTrigger.valueChangedHandler = { [weak self] _, value, _ in
            self?.xinputState.leftTrigger = value
        }
        gamepad.rightTrigger.valueChangedHandler = { [weak self] _, value, _ in
            self?.xinputState.rightTrigger = value
        }

        // Face buttons → XInput
        gamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.A, pressed: pressed)
        }
        gamepad.buttonB.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.B, pressed: pressed)
        }
        gamepad.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.X, pressed: pressed)
        }
        gamepad.buttonY.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.Y, pressed: pressed)
        }

        // Shoulders
        gamepad.leftShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.LEFT_SHOULDER, pressed: pressed)
        }
        gamepad.rightShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.RIGHT_SHOULDER, pressed: pressed)
        }

        // D-Pad
        gamepad.dpad.up.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.DPAD_UP, pressed: pressed)
        }
        gamepad.dpad.down.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.DPAD_DOWN, pressed: pressed)
        }
        gamepad.dpad.left.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.DPAD_LEFT, pressed: pressed)
        }
        gamepad.dpad.right.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.DPAD_RIGHT, pressed: pressed)
        }

        // Menu buttons
        gamepad.buttonMenu.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.START, pressed: pressed)
        }
        gamepad.buttonOptions?.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.setButton(.BACK, pressed: pressed)
        }
    }

    // MARK: - Button State Helper

    private enum XInputButton {
        case A, B, X, Y
        case DPAD_UP, DPAD_DOWN, DPAD_LEFT, DPAD_RIGHT
        case LEFT_SHOULDER, RIGHT_SHOULDER
        case START, BACK

        var mask: UInt16 {
            switch self {
            case .A: return XInputState.A
            case .B: return XInputState.B
            case .X: return XInputState.X
            case .Y: return XInputState.Y
            case .DPAD_UP: return XInputState.DPAD_UP
            case .DPAD_DOWN: return XInputState.DPAD_DOWN
            case .DPAD_LEFT: return XInputState.DPAD_LEFT
            case .DPAD_RIGHT: return XInputState.DPAD_RIGHT
            case .LEFT_SHOULDER: return XInputState.LEFT_SHOULDER
            case .RIGHT_SHOULDER: return XInputState.RIGHT_SHOULDER
            case .START: return XInputState.START
            case .BACK: return XInputState.BACK
            }
        }
    }

    private func setButton(_ button: XInputButton, pressed: Bool) {
        if pressed {
            xinputState.buttons |= button.mask
        } else {
            xinputState.buttons &= ~button.mask
        }
    }
}
