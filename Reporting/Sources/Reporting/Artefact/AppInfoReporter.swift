import Foundation

struct AppInfoReporter {
    var compilationRequirements: [CompilationRequirement]

    func overviewSections(for appInfo: AppInfo) -> [ReportSection] {
        return [
            appInfo.versioningAttributesSection,
            appInfo.detailedAttributesSection,
        ]
    }

    func technicalSections(for appInfo: AppInfo) -> [ReportSection] {
        return [
            appInfo.technicalAttributesSection,
            appInfo.integrityChecksSection,
            appInfo.compilationRequirementsSection(with: compilationRequirements)
        ]
    }

}

private protocol DisplayAttributeProtocol {
    var displayName: String { get }
    func value(in info: AppInfo) -> String?
}

private extension AppInfo {

    struct DisplayAttribute<Value: Decodable>: DisplayAttributeProtocol {
        var displayName: String
        var key: KeyPath<AppInfo, Decoded<Value>?>
        var format: (Value) -> String

        init(displayName: String, key: KeyPath<AppInfo, Decoded<Value>?>, format: @escaping (Value) -> String = { "\($0)" }) {
            self.displayName = displayName
            self.key = key
            self.format = format
        }

        func value(in info: AppInfo) -> String? {
            return info.value(for: key).map(format)
        }
    }

    var versioningAttributesSection: ReportSection {
        let interestingCases: [DisplayAttributeProtocol] = [
            DisplayAttribute(displayName: "Version", key: \.version),
            DisplayAttribute(displayName: "Build", key: \.bundleVersion),
            ]

        let table = ReportTable(
            rows: interestingCases,
            columns: [
                ReportColumnAdapter(title: "Attribute", makeContent: { $0.displayName }),
                ReportColumnAdapter(title: "Value", makeContent: { $0.value(in: self) ?? "❌ missing" }),
                ]
        )
        return ReportSection(title: "Versioning", content: table)
    }

    var detailedAttributesSection: ReportSection {
        let interestingCases: [DisplayAttributeProtocol] = [
            DisplayAttribute(displayName: "Name", key: \.bundleName),
            DisplayAttribute(displayName: "Minimum supported OS version", key: \.minimumOSVersion),
            DisplayAttribute(displayName: "Supported interface orientations", key: \.supportedInterfaceOrientations) {
                $0.displayValue
            },
            DisplayAttribute(displayName: "Supported interface orientations (iPad)", key: \.supportedInterfaceOrientationsForIpad) {
                $0.displayValue
            },
            DisplayAttribute(displayName: "Required device capabilities", key: \.requiredDeviceCapabilities) {
                $0.lazy.map { $0.rawValue }.sorted().joined(separator: ", ")
            },
            ]

        let table = ReportTable(
            rows: interestingCases,
            columns: [
                ReportColumnAdapter(title: "Attribute", makeContent: { $0.displayName }),
                ReportColumnAdapter(title: "Value", makeContent: { $0.value(in: self) ?? "❌ missing" }),
                ]
        )
        return ReportSection(title: "Attributes", content: table)
    }

    var technicalAttributesSection: ReportSection {
        let interestingCases: [DisplayAttributeProtocol] = [
            DisplayAttribute(displayName: "Bundle identifier", key: \.bundleIdentifier),
            DisplayAttribute(displayName: "Development region", key: \.bundleDevelopmentRegion),
            DisplayAttribute(displayName: "Executable", key: \.bundleExecutable),
            DisplayAttribute(displayName: "Launch storyboard name", key: \.launchStoryboardName),
            ]

        let table = ReportTable(
            rows: interestingCases,
            columns: [
                ReportColumnAdapter(title: "Attribute", makeContent: { $0.displayName }),
                ReportColumnAdapter(title: "Value", makeContent: { $0.value(in: self) ?? "❌ missing" }),
                ]
        )
        return ReportSection(title: "Technical Attributes", content: table)
    }

    var integrityChecksSection: ReportSection {

        let table = ReportTable(checks: [
            IntegrityCheck(name: "All keys are known", result: checkOnlyHasExpectedKeys()),
            IntegrityCheck(name: "All expected keys are formatted correctly", result: checkForParsingErrors()),
            IntegrityCheck(name: "Bundle attribtues are set correctly", result: checkBundleAttributesAreCorrect()),
            ]
        )
        return ReportSection(title: "Info integrity checks", content: table)
    }

    func compilationRequirementsSection(with requirements: [CompilationRequirement]) -> ReportSection {

        let table = ReportTable(
            rows: requirements,
            columns: [
                ReportColumnAdapter(title: "Check", makeContent: { $0.displayTitle }),
                ReportColumnAdapter(title: "Passed?", makeContent: { $0.passes(for: self) ? "✅" : "❌" }),
                ]
        )
        return ReportSection(title: "Compilation integrity checks", content: table)
    }

    func checkOnlyHasExpectedKeys() -> IntegrityCheck.Result {
        if unknownKeys.isEmpty {
            return .passed
        } else {
            let list = ReportList(
                kind: .unordered,
                items: unknownKeys.sorted().map { "`\($0)`" })
            return .failed(message: "Found unexpected keys: \(list.markdownBody)")
        }
    }

    func checkForParsingErrors() -> IntegrityCheck.Result {
        let parseErrors = self.parseErrors
        if parseErrors.isEmpty {
            return .passed
        } else {
            let list = ReportList(
                kind: .unordered,
                items: parseErrors.sorted(by: { $0.key < $1.key }).map { "`\($0.key)`: \($0.error)" })
            return .failed(message: list.markdownBody)
        }
    }

    func checkBundleAttributesAreCorrect() -> IntegrityCheck.Result {
        guard let bundleInfoDictionaryVersion = value(for: \.bundleInfoDictionaryVersion) else {
            return .failed(message: "Missing bundle info version")
        }
        guard let bundlePackageType = value(for: \.bundlePackageType) else {
            return .failed(message: "Missing bundle package type")
        }
        guard bundleInfoDictionaryVersion == "6.0" else {
            return .failed(message: "Expected bundle info version to be “6.0”. Instead found “\(bundleInfoDictionaryVersion)”")
        }
        guard bundlePackageType == "APPL" else {
            return .failed(message: "Expected bundle info version to be “6.0”. Instead found “\(bundlePackageType)”")
        }
        return .passed
    }

}

private extension Set where Element == AppInfo.InterfaceOrientation {

    var displayValue: String {
        let missingAtLeastOneCase = AppInfo.InterfaceOrientation.allCases.contains { !self.contains($0) }
        guard missingAtLeastOneCase else { return "All" }

        var parts = [String]()
        if contains(.portrait) {
            parts.append("Portrait (upright)")
        }
        switch (contains(.left), contains(.right)) {
        case (true, true):
            parts.append("Landscape")
        case (true, false):
            parts.append("Landscape (left)")
        case (false, true):
            parts.append("Landscape (right)")
        case (false, false):
            break
        }
        if contains(.portraitUpsideDown) {
            parts.append("Portrait (upside down)")
        }
        return parts.joined(separator: ", ")
    }

}
