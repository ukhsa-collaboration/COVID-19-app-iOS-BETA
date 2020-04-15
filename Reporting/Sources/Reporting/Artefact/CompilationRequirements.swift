import Foundation

protocol CompilationRequirement {
    var displayTitle: String { get }
    func passes(for info: AppInfo) -> Bool
}

protocol MinimumVersionCompilationRequirement: CompilationRequirement {
    func comparisonResults(for info: AppInfo) -> [ComparisonResult]
}

extension MinimumVersionCompilationRequirement {
    func passes(for info: AppInfo) -> Bool {
        return !comparisonResults(for: info).contains(.orderedAscending)
    }
}

struct MinimumOSCompilationRequirement: MinimumVersionCompilationRequirement {
    
    var displayTitle: String
    var minimumBuild: String
    
    func comparisonResults(for info: AppInfo) -> [ComparisonResult] {
        let build = info.value(for: \.buildMachineOS) ?? "0"
        return [
            build.compare(minimumBuild, options: .numeric),
        ]
    }
    
    static let macOS10_15_4 = MinimumOSCompilationRequirement(
        displayTitle: "Built on macOS 10.15.4 or newer",
        minimumBuild: "19E287"
    )
    
}

struct MinimumXcodeCompilationRequirement: MinimumVersionCompilationRequirement {
    
    var displayTitle: String
    var minimumVersion: String
    var minimumBuild: String
    
    func comparisonResults(for info: AppInfo) -> [ComparisonResult] {
        let version = info.value(for: \.xcode) ?? "0"
        let build = info.value(for: \.xcodeBuild) ?? "0"
        return [
            version.compare(minimumVersion, options: .numeric),
            build.compare(minimumBuild, options: .numeric),
        ]
    }
    
    static let xcode11 = MinimumXcodeCompilationRequirement(
        displayTitle: "Built with Xcode 11.4 or newer",
        minimumVersion: "1140",
        minimumBuild: "11E146"
    )
    
}

struct MinimumPlatformCompilationRequirement: MinimumVersionCompilationRequirement {
    
    var displayTitle: String
    var minimumVersion: String
    var minimumBuild: String
    var minimumSdkBuild: String
    
    func comparisonResults(for info: AppInfo) -> [ComparisonResult] {
        let version = info.value(for: \.platformVersion) ?? "0"
        let build = info.value(for: \.platformBuild) ?? "0"
        let sdkBuild = info.value(for: \.sdkBuild) ?? "0"
        return [
            version.compare(minimumVersion, options: .numeric),
            build.compare(minimumBuild, options: .numeric),
            sdkBuild.compare(minimumSdkBuild, options: .numeric),
        ]
    }

    static let ios13 = MinimumPlatformCompilationRequirement(
        displayTitle: "Built with iOS SDK 13.0 or newer",
        minimumVersion: "13.4",
        minimumBuild: "17E255",
        minimumSdkBuild: "17E255"
    )
    
}

struct CompilerCompilationRequirement: CompilationRequirement {
    
    var displayTitle: String
    var compiler: String
    
    func passes(for info: AppInfo) -> Bool {
        return info.value(for: \.compiler) == compiler
    }
    
    static let clang1 = CompilerCompilationRequirement(
        displayTitle: "Built with Clang 1.0",
        compiler: "com.apple.compilers.llvm.clang.1_0"
    )
    
}

struct PlatformCompilationRequirement: CompilationRequirement {
    
    var displayTitle: String
    var verify: (AppInfo) -> Bool
    
    func passes(for info: AppInfo) -> Bool {
        return verify(info)
    }
    
    static let iOSDevice = PlatformCompilationRequirement(displayTitle: "Built for iOS") { info in
        let bundleSupportedPlatforms = info.value(for: \.bundleSupportedPlatforms) ?? []
        return info.value(for: \.requiresIPhoneOS) == true &&
            info.value(for: \.platformName) == "iphoneos" &&
            bundleSupportedPlatforms.contains("iPhoneOS")
    }
    
    static let iOSSimulator = PlatformCompilationRequirement(displayTitle: "Built for iOS Simulator") { info in
        let bundleSupportedPlatforms = info.value(for: \.bundleSupportedPlatforms) ?? []
        return info.value(for: \.requiresIPhoneOS) == true &&
            info.value(for: \.platformName) == "iOSSimulator" &&
            bundleSupportedPlatforms.contains("iPhoneSimulator")
    }
    
    static let iOSDeviceOrSimulator = PlatformCompilationRequirement(displayTitle: "Built for iOS (Device or Simulator)") { info in
        return [
            PlatformCompilationRequirement.iOSDevice,
            PlatformCompilationRequirement.iOSSimulator,
            ].contains { $0.passes(for: info) }
    }
    
}
