import Foundation

struct CoLocate {
    static let compilationRequirements: [CompilationRequirement] = [
        MinimumOSCompilationRequirement.macOS10_15_4,
        MinimumXcodeCompilationRequirement.xcode11,
        MinimumPlatformCompilationRequirement.ios13,
        CompilerCompilationRequirement.clang1,
        PlatformCompilationRequirement.iOSDevice,
    ]
}
