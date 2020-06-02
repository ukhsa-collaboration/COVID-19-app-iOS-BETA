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
        .storyboard("LinkingId"),
        .storyboard("Advice"),
        .storyboard("BookTest"),
        .storyboard("CheckinDrawer"),
        .storyboard("Drawer"),
        .storyboard("ReferenceCode"),
        .storyboard("RegistrationStatus"),
        .storyboard("SetStatusState"),
        .storyboard("TestingInfo"),
        .storyboard("WorkplaceGuidance"),
        .nib("LogoStrapline"),
        .nib("OnboardingLogoStrapline"),
        .nib("ErrorView"),
        .strings("Localizable"),
        .plist("GoogleService-Info"),
        .plist("URLs"),
        .bundle("Settings"),
    ]
    
    static let knownAssets = Self.requiredAssets + Self.acceptedUnwantedAssets
}
