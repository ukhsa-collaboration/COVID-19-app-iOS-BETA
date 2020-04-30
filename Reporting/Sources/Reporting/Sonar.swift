import Foundation

struct Sonar {
    static let compilationRequirements: [CompilationRequirement] = [
        MinimumOSCompilationRequirement.macOS10_15_4,
        MinimumXcodeCompilationRequirement.xcode11,
        MinimumPlatformCompilationRequirement.ios13,
        CompilerCompilationRequirement.clang1,
        PlatformCompilationRequirement.iOSDevice,
    ]
    
    #warning("These need to be removed.")
    // These assets ideally should not be part of the final artefact
    // We’re accepting their existence for now
    static let acceptedUnwantedAssets: [Asset] = [
        .storyboard("Debug"),
    ]
    
    static let requiredAssets: [Asset] = [
        .storyboard("Onboarding"),
        .storyboard("SelfDiagnosis"),
        .storyboard("Status"),
        .nib("LogoStrapline"),
        .nib("OnboardingLogoStrapline"),
        .strings("Localizable"),
        .plist("GoogleService-Info"),
    ]
    
    static let knownAssets = Self.requiredAssets + Self.acceptedUnwantedAssets
}
