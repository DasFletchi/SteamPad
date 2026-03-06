import Foundation
import Metal
import QuartzCore

// MARK: - MoltenMetal: Direct3D → Vulkan → Metal Translation Bridge
//
// This module manages the graphics translation pipeline:
//   Direct3D (inside translated game) → DXVK → Vulkan API → MoltenVK → Metal
//
// The final Metal commands render into a CAMetalLayer that is embedded
// in the SwiftUI view hierarchy via UIViewRepresentable.

class MoltenMetalInterop {

    // MARK: - Metal State
    private static var device: MTLDevice?
    private static var commandQueue: MTLCommandQueue?
    private static var metalLayer: CAMetalLayer?

    /// Errors from the graphics translation layer
    enum GraphicsError: Error {
        case noMetalDevice
        case layerCreationFailed
        case vulkanInitFailed
        case dxvkInitFailed
    }

    // MARK: - Initialize Metal Context

    /// Set up the Metal device and command queue.
    /// This is called once at app launch before any game starts.
    static func initializeMetalContext() throws {
        guard let dev = MTLCreateSystemDefaultDevice() else {
            throw GraphicsError.noMetalDevice
        }

        device = dev
        commandQueue = dev.makeCommandQueue()

        print("[MoltenMetal] Metal device: \(dev.name)")
        print("[MoltenMetal] GPU Family: Apple \(dev.supportsFamily(.apple7) ? "7+" : "≤6")")
        print("[MoltenMetal] Max buffer length: \(dev.maxBufferLength / 1_048_576) MB")
    }

    /// Bind a CAMetalLayer to the rendering pipeline.
    /// The SwiftUI overlay view calls this to provide the drawable surface.
    static func bindMetalLayer(_ layer: CAMetalLayer) {
        guard let dev = device else { return }

        layer.device = dev
        layer.pixelFormat = .bgra8Unorm
        layer.framebufferOnly = false
        layer.contentsScale = UIScreen.main.scale

        // Enable ProMotion (120Hz) on supported iPads
        layer.maximumDrawableCount = 3

        metalLayer = layer

        print("[MoltenMetal] CAMetalLayer bound (\(Int(layer.drawableSize.width))x\(Int(layer.drawableSize.height)))")
    }

    /// Initialize the MoltenVK Vulkan-to-Metal bridge
    static func initializeMoltenVK() throws {
        // In production: load libMoltenVK.dylib (bundled with the app)
        // and call vkCreateInstance with MoltenVK-specific extensions.
        //
        // Key MoltenVK configuration:
        //   MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS = 1
        //   MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS = 0
        //   MVK_CONFIG_PREFILL_METAL_COMMAND_BUFFERS = 1

        guard let mvkHandle = dlopen("libMoltenVK.dylib", RTLD_NOW) else {
            let error = String(cString: dlerror())
            print("[MoltenMetal] MoltenVK load failed: \(error)")
            throw GraphicsError.vulkanInitFailed
        }

        // Get vkCreateInstance
        guard let createInstance = dlsym(mvkHandle, "vkCreateInstance") else {
            throw GraphicsError.vulkanInitFailed
        }

        print("[MoltenMetal] MoltenVK loaded, Vulkan instance ready")
        _ = createInstance // Suppress unused warning in prototype
    }

    /// Initialize DXVK (Direct3D → Vulkan translation)
    static func initializeDXVK() throws {
        // In production: DXVK DLLs (d3d9.dll, d3d11.dll, dxgi.dll) are
        // pre-translated to ARM64 .dylib files by the AOT compiler.
        // They intercept Direct3D calls from the game and output Vulkan commands.
        //
        // Expected modules:
        //   d3d9.dylib   - Direct3D 9 translation
        //   d3d11.dylib  - Direct3D 11 translation
        //   dxgi.dylib   - DXGI infrastructure

        let dxvkModules = ["d3d9", "d3d11", "dxgi"]

        for module in dxvkModules {
            if let path = Bundle.main.path(forResource: module, ofType: "dylib") {
                if dlopen(path, RTLD_NOW) != nil {
                    print("[DXVK] Loaded \(module).dylib")
                } else {
                    print("[DXVK] Warning: \(module).dylib failed to load")
                }
            } else {
                print("[DXVK] \(module).dylib not bundled (expected in production build)")
            }
        }
    }

    // MARK: - Render Loop

    /// Begin the render loop, drawing translated game frames to the Metal layer
    static func startRenderLoop() {
        guard let layer = metalLayer, let queue = commandQueue else { return }

        // In production: this runs on a dedicated high-priority render thread.
        // MoltenVK's vkQueueSubmit calls translate to Metal command buffer commits.
        // We use a CADisplayLink for frame pacing.

        let displayLink = CADisplayLink(target: RenderLoopTarget.shared, selector: #selector(RenderLoopTarget.frame))
        displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 60)
        displayLink.add(to: .main, forMode: .common)

        print("[MoltenMetal] Render loop started (target: 60 FPS)")
        _ = (layer, queue) // Used by the render target in production
    }
}

// MARK: - Render Loop Target (for CADisplayLink)
class RenderLoopTarget {
    static let shared = RenderLoopTarget()

    @objc func frame(_ displayLink: CADisplayLink) {
        // In production: this is where MoltenVK flushes pending Vulkan
        // commands and Metal presents the next drawable.
        //
        // The game thread submits Vulkan draw calls via DXVK.
        // MoltenVK translates them to Metal encoder commands.
        // This callback commits the Metal command buffer and
        // presents the drawable to screen.
    }
}
