import Foundation
import GameController

// MARK: - Controller Input Manager
class ControllerInputManager: ObservableObject {
    @Published var connectedControllers: [GCController] = []
    @Published var isUsingTouchControls = true
    @Published var xinputState = XInputState()

    // MARK: - XInput State
    struct XInputState {
        var leftStickX: Float = 0
        var leftStickY: Float = 0
        var rightStickX: Float = 0
        var rightStickY: Float = 0
        var leftTrigger: Float = 0
        var rightTrigger: Float = 0
        var buttons: UInt16 = 0

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

    // MARK: - Setup

    func startListening() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil, queue: .main
        ) { [weak self] note in
            if let ctrl = note.object as? GCController {
                self?.controllerConnected(ctrl)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil, queue: .main
        ) { [weak self] note in
            if let ctrl = note.object as? GCController {
                self?.controllerDisconnected(ctrl)
            }
        }

        GCController.controllers().forEach { controllerConnected($0) }
    }

    private func controllerConnected(_ controller: GCController) {
        connectedControllers.append(controller)
        isUsingTouchControls = false
        if let gamepad = controller.extendedGamepad {
            bindExtendedGamepad(gamepad)
        }
    }

    private func controllerDisconnected(_ controller: GCController) {
        connectedControllers.removeAll { $0 == controller }
        isUsingTouchControls = connectedControllers.isEmpty
    }

    // MARK: - Bindings

    private func bindExtendedGamepad(_ gp: GCExtendedGamepad) {
        gp.leftThumbstick.valueChangedHandler = { [weak self] _, x, y in
            self?.xinputState.leftStickX = x
            self?.xinputState.leftStickY = y
        }
        gp.rightThumbstick.valueChangedHandler = { [weak self] _, x, y in
            self?.xinputState.rightStickX = x
            self?.xinputState.rightStickY = y
        }
        gp.leftTrigger.valueChangedHandler = { [weak self] _, v, _ in
            self?.xinputState.leftTrigger = v
        }
        gp.rightTrigger.valueChangedHandler = { [weak self] _, v, _ in
            self?.xinputState.rightTrigger = v
        }

        gp.buttonA.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.A, p) }
        gp.buttonB.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.B, p) }
        gp.buttonX.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.X, p) }
        gp.buttonY.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.Y, p) }
        gp.leftShoulder.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.LEFT_SHOULDER, p) }
        gp.rightShoulder.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.RIGHT_SHOULDER, p) }
        gp.dpad.up.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.DPAD_UP, p) }
        gp.dpad.down.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.DPAD_DOWN, p) }
        gp.dpad.left.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.DPAD_LEFT, p) }
        gp.dpad.right.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.DPAD_RIGHT, p) }
        gp.buttonMenu.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.START, p) }
        gp.buttonOptions?.pressedChangedHandler = { [weak self] _, _, p in self?.setBtn(XInputState.BACK, p) }
    }

    private func setBtn(_ mask: UInt16, _ pressed: Bool) {
        if pressed {
            xinputState.buttons |= mask
        } else {
            xinputState.buttons &= ~mask
        }
    }
}
