import Foundation
import AppKit

public final class FetchService: ObservableObject {
    @Published public var data: FetchData?
    @Published public var isLoading: Bool = false
    @Published public var errorText: String? = nil
    @Published public var lastRefreshedAt: Date? = nil

    public static let shared = FetchService()

    public init() {}

    public func refresh() {
        guard !isLoading else { return }
        isLoading = true
        errorText = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let probedData = SystemProbe.probe()

            DispatchQueue.main.async {
                self.data = probedData
                self.isLoading = false
                self.lastRefreshedAt = Date()
            }
        }
    }

    public func copyToClipboard() {
        guard let output = data?.rawOutput, !output.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
}

public typealias FastfetchService = FetchService

