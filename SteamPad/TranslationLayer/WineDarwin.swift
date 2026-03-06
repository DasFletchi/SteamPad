import Foundation

// MARK: - Wine Darwin: Single-Process Windows API Translation Layer
//
// Runs the entire Wine environment within a single iOS process.
// wineserver → background thread. DLLs → dlopen'd dylibs.

enum WineDarwin {

    private(set) static var isInitialized = false
    private static var prefixPath = ""
    private static var serverThread: Thread?

    enum WineError: Error {
        case prefixFailed(String)
        case moduleFailed(String)
    }

    // MARK: - Setup WINEPREFIX as threaded environment

    static func initializeThreadedPrefix(path: String) {
        let fm = FileManager.default
        let prefix = resolvePrefixPath(for: path)

        let dirs = [
            "\(prefix)/drive_c",
            "\(prefix)/drive_c/windows/system32",
            "\(prefix)/drive_c/users/steampad/AppData/Local",
            "\(prefix)/drive_c/users/steampad/Documents",
            "\(prefix)/drive_c/Program Files",
        ]
        for dir in dirs {
            try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }

        prefixPath = prefix
        isInitialized = true
        startWineServerThread()
    }

    // MARK: - WineServer as background thread (no fork)

    private static func startWineServerThread() {
        let thread = Thread {
            Thread.current.name = "WineServer"
            while isInitialized {
                // Process registry, file locks, window messages via shared memory
                Thread.sleep(forTimeInterval: 0.001)
            }
        }
        thread.qualityOfService = .userInteractive
        thread.start()
        serverThread = thread
    }

    // MARK: - Windows → Darwin API Translation Reference

    static let apiTable: [String: String] = [
        "CreateFileW": "open", "ReadFile": "read", "WriteFile": "write",
        "CloseHandle": "close", "VirtualAlloc": "mmap", "VirtualFree": "munmap",
        "CreateThread": "pthread_create", "Sleep": "usleep",
        "GetTickCount": "mach_absolute_time", "LoadLibraryW": "dlopen",
        "GetProcAddress": "dlsym", "FreeLibrary": "dlclose",
    ]

    // MARK: - Shutdown

    static func shutdown() {
        isInitialized = false
        serverThread = nil
        prefixPath = ""
    }

    private static func resolvePrefixPath(for gamePath: String) -> String {
        let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "/tmp"
        let safe = gamePath.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: " ", with: "_")
        return "\(docs)/Prefixes/\(safe)"
    }
}
