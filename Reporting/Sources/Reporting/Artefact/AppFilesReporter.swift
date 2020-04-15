import Foundation

struct AppFilesReporter {
    
    func reportSections(forAppAt appURL: URL, info: AppInfo) -> [ReportSection] {
        guard var context = FileReporterContext(appInfo: info, appURL: appURL) else {
            return [ReportSection(title: "Bundle Files", content: "❌ Could not process bundle")]
        }
        
        return [
            frameworks(with: &context),
            contentIntegrityChecks(with: &context),
        ]
    }
    
    private func frameworks(with context: inout FileReporterContext) -> ReportSection {
        
        let table = ReportTable(
            rows: context.findEmbeddedFrameworks(),
            columns: [
                ReportColumnAdapter(title: "Name", makeContent: { $0 }),
                ]
        )
        
        return ReportSection(title: "Frameworks", content: table)
    }
    
    private func contentIntegrityChecks(with context: inout FileReporterContext) -> ReportSection {
        
        let table = ReportTable(checks: [
            IntegrityCheck(name: "Has icons", result: context.checkHasIconFiles()),
            IntegrityCheck(name: "Has launch storyboard", result: context.checkHasLaunchStoryboard()),
            IntegrityCheck(name: "Has the required common files", result: context.checkHasRequiredFiles()),
            IntegrityCheck(name: "Has bundle executable", result: context.checkHasBundleExecutable()),
            IntegrityCheck(name: "Embeds Swift frameworks", result: context.checkEmbedsSwiftFrameworks()),
            IntegrityCheck(name: "All files are known", result: context.checkHasNoUnexptectedFilesLeft()),
            ]
        )
        
        return ReportSection(title: "Contents", content: table)
    }
    
    func attachments(forAppAt appURL: URL, info: AppInfo) -> [ReportAttachment] {
        guard let context = FileReporterContext(appInfo: info, appURL: appURL) else {
            return []
        }
        
        return [
            context.icon,
            ]
            .compactMap { $0 }
    }
    
}

private struct AppResource {
    var url: URL
    var pathInBundle: String
    
    init(url: URL, appURL: URL) {
        precondition(url.path.hasPrefix(appURL.path))
        self.url = url
        pathInBundle = String(url.path.dropFirst(appURL.path.count).trimmingCharacters(in: .pathSeparator))
    }
}

private extension CharacterSet {
    
    static let pathSeparator = CharacterSet(charactersIn: "/")
    
}

private struct FileReporterContext {
    var appInfo: AppInfo
    var filesByPathInBundle: [String: URL]
    
    var unaccountedFilePaths: Set<String>
    
    init?(appInfo: AppInfo, appURL: URL) {
        let fileManager = FileManager()
        guard let enumerator = fileManager.enumerator(at: appURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil) else {
            return nil
        }
        
        self.appInfo = appInfo
        filesByPathInBundle = Dictionary(uniqueKeysWithValues: enumerator
            .lazy
            .map { ($0 as! URL).resolvingSymlinksInPath() }
            .map { url in
                precondition(url.path.hasPrefix(appURL.path))
                let pathInBundle = String(url
                    .path
                    .dropFirst(appURL.path.count)
                    .trimmingCharacters(in: .pathSeparator)
                )
                return (pathInBundle, url)
            }
        )
        
        unaccountedFilePaths = Set(filesByPathInBundle.keys)
        
        // These are always allowed:
        unaccountedFilePaths.remove("Frameworks") // Folder
        unaccountedFilePaths.remove("_CodeSignature") // Folder
        unaccountedFilePaths.remove("PlugIns") // Folder
        unaccountedFilePaths.remove("embedded.mobileprovision")
        unaccountedFilePaths.remove("libswiftRemoteMirror.dylib")
        unaccountedFilePaths.remove("Assets.car")
        
        unaccountedFilePaths = unaccountedFilePaths.filter {
            let isTest = $0.hasPrefix("PlugIns/") && $0.contains(".xctest")
            return !isTest
        }
    }
    
}

extension FileReporterContext {
    
    mutating func checkHasRequiredFiles() -> IntegrityCheck.Result {
        
        for fileName in ["Info.plist", "_CodeSignature/CodeResources", "PkgInfo"] {
            guard filesByPathInBundle[fileName] != nil else {
                return .failed(message: "Expected file \(fileName).")
            }
            
            unaccountedFilePaths.remove(fileName)
        }
        
        return .passed
    }
    
    mutating func checkHasBundleExecutable() -> IntegrityCheck.Result {
        guard let binaryName = appInfo.value(for: \.bundleExecutable) else {
            return .failed(message: "No binary executable name specified.")
        }
        
        guard filesByPathInBundle[binaryName] != nil else {
            return .failed(message: "Expected app to have binary executable at `\(binaryName)`.")
        }
        
        unaccountedFilePaths.remove(binaryName)
        
        return .passed
    }
    
    mutating func checkHasIconFiles() -> IntegrityCheck.Result {
        let appInfo = self.appInfo
        let iconFiles = Set([\AppInfo.bundleIcons, \AppInfo.bundleIconsForIpad]
            .lazy
            .compactMap {
                appInfo.value(for: $0)
            }
            .flatMap {
                $0.primary.files
            }
        )
        guard !iconFiles.isEmpty else {
            return .failed(message: "No icon files specified.")
        }
        
        for file in iconFiles {
            let result = checkHasFiles(for: "Expected icon files for `\(file)`") {
                $0.hasPrefix(file) && $0.hasSuffix(".png")
            }
            switch result {
            case .passed:
                break
            default:
                return result
            }
        }

        return .passed
    }
    
    mutating func checkHasLaunchStoryboard() -> IntegrityCheck.Result {
        guard let launchStoryboardName = appInfo.value(for: \.launchStoryboardName) else {
            return .failed(message: "No launch storyboard name specified.")
        }
        
        let fileName = "\(launchStoryboardName).storyboardc"
        let folderName = "\(fileName)/"
        guard filesByPathInBundle[fileName] != nil else {
            return .failed(message: "Expected app to have launch storyboard named `\(launchStoryboardName)`.")
        }
        
        unaccountedFilePaths.remove(fileName)
        unaccountedFilePaths = unaccountedFilePaths.filter {
            !$0.hasPrefix(folderName)
        }
        
        return .passed
    }
    
    mutating func checkEmbedsSwiftFrameworks() -> IntegrityCheck.Result {
        return checkHasFiles(for: "Expected to find swift `dylib`s.") {
            $0.hasPrefix("Frameworks/libswift") && $0.hasSuffix(".dylib")
        }
    }
    
    mutating func findEmbeddedFrameworks() -> [String] {
        let frameworkNames = unaccountedFilePaths
            .filter {
            $0.hasPrefix("Frameworks/") && $0.hasSuffix(".framework")
        }
            .map { path in
                String(
                    path.dropFirst("Frameworks/".count)
                        .dropLast(".framework".count)
                )
        }
        
        for name in frameworkNames {
            let prefix = "Frameworks/\(name).framework"
            unaccountedFilePaths = unaccountedFilePaths.filter {
                !$0.hasPrefix(prefix)
            }
        }
        
        return frameworkNames.sorted()
    }
    
    func checkHasNoUnexptectedFilesLeft() -> IntegrityCheck.Result {
        if unaccountedFilePaths.isEmpty {
            return .passed
        } else {
            let list = ReportList(
                kind: .unordered,
                items: unaccountedFilePaths.sorted().map { "`\($0)`" })
            return .failed(message: "Found unexpected files: \(list.markdownBody)")
        }
    }
    
}

extension FileReporterContext {
    
    var icon: ReportAttachment? {
        let appInfo = self.appInfo
        let iconFileNames = [\AppInfo.bundleIcons, \AppInfo.bundleIconsForIpad]
            .lazy
            .compactMap {
                appInfo.value(for: $0)
            }
            .flatMap {
                $0.primary.files
        }
        let iconURL = iconFileNames
            .lazy
            .compactMap { file in
                self.firstURL {
                    $0.hasPrefix(file) && $0.hasSuffix(".png")
                }
            }
            .first
        return iconURL.map {
            ReportAttachment(name: "Icon.png", source: $0)
        }
    }
    
}

extension FileReporterContext {
    
    func firstURL(matching pattern: (String) -> Bool) -> URL? {
        let key = filesByPathInBundle.keys.lazy.filter(pattern).sorted().first
        return key.flatMap {
            filesByPathInBundle[$0]
        }
    }
    
    private mutating func checkHasFiles(for expectation: String, matching pattern: (String) -> Bool) -> IntegrityCheck.Result {
        
        let filtered = unaccountedFilePaths.filter { file in
            let matches = pattern(file)
            return !matches
        }
        
        guard filtered.count != unaccountedFilePaths.count else {
            return .failed(message: expectation)
        }
        
        unaccountedFilePaths = filtered
        return .passed
    }
    
}
