"""Generate the dependency-free Xcode project from the shared Swift sources."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]

def ident(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()

def quote(value):
    return json.dumps(str(value), ensure_ascii=False)

def generate():
    objects = {}
    def obj(key, value):
        objects[ident(key)] = value
        return ident(key)

    source_refs, source_builds = [], []
    for source in sorted((ROOT / "FantasiVen.swiftpm").rglob("*.swift")):
        if source.name == "Package.swift":
            continue
        path = source.relative_to(ROOT).as_posix()
        ref = obj(path, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quote(path)}; sourceTree = SOURCE_ROOT;')
        build = obj("build:" + path, f'isa = PBXBuildFile; fileRef = {ref};')
        source_refs.append(ref); source_builds.append(build)

    resources = []
    for path, kind in [("FantasiVen.swiftpm/Resources/Assets.xcassets", "folder.assetcatalog"), ("FantasiVen.swiftpm/Resources/PrivacyInfo.xcprivacy", "text.xml")]:
        ref = obj(path, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {quote(path)}; sourceTree = SOURCE_ROOT;')
        resources.append(obj("build:" + path, f'isa = PBXBuildFile; fileRef = {ref};'))
        source_refs.append(ref)

    app = obj("product", 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = FantasiVen.app; sourceTree = BUILT_PRODUCTS_DIR;')
    test_app = obj("test-product", 'isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = FantasiVenTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
    test_path = "Tests/FantasiVenTests.swift"
    test_ref = obj(test_path, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quote(test_path)}; sourceTree = SOURCE_ROOT;')
    test_build = obj("build:" + test_path, f'isa = PBXBuildFile; fileRef = {test_ref};')
    products = obj("products", f'isa = PBXGroup; children = ({app}, {test_app}); name = Products; sourceTree = "<group>";')
    group = obj("root-group", f'isa = PBXGroup; children = ({", ".join(source_refs + [test_ref, products])}); sourceTree = "<group>";')
    sources = obj("sources", f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(source_builds)}); runOnlyForDeploymentPostprocessing = 0;')
    resource_phase = obj("resources", f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(resources)}); runOnlyForDeploymentPostprocessing = 0;')
    frameworks = obj("frameworks", 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
    test_sources = obj("test-sources", f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({test_build}); runOnlyForDeploymentPostprocessing = 0;')
    test_frameworks = obj("test-frameworks", 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')

    def configs(label, settings):
        refs = []
        for mode in ["Debug", "Release"]:
            values = dict(settings)
            values["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone" if mode == "Debug" else "-O"
            values["DEBUG_INFORMATION_FORMAT"] = "dwarf" if mode == "Debug" else "dwarf-with-dsym"
            if mode == "Debug":
                values["ENABLE_TESTABILITY"] = "YES"
                values["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG"
            body = " ".join(f'{k} = {quote(v)};' for k, v in values.items())
            refs.append(obj(label + mode, f'isa = XCBuildConfiguration; buildSettings = {{ {body} }}; name = {mode};'))
        return obj(label + "configs", f'isa = XCConfigurationList; buildConfigurations = ({", ".join(refs)}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')

    project_config = configs("project", {"SDKROOT": "iphoneos", "IPHONEOS_DEPLOYMENT_TARGET": "15.0", "SWIFT_VERSION": "6.0", "CLANG_ENABLE_MODULES": "YES", "SWIFT_STRICT_CONCURRENCY": "complete"})
    app_config = configs("app", {"PRODUCT_NAME": "$(TARGET_NAME)", "PRODUCT_BUNDLE_IDENTIFIER": "dk.fantasiven.app", "INFOPLIST_FILE": "Configuration/Info.plist", "TARGETED_DEVICE_FAMILY": "1", "CODE_SIGN_STYLE": "Automatic", "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon", "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator", "SUPPORTS_MACCATALYST": "NO", "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks", "SWIFT_EMIT_LOC_STRINGS": "NO"})
    test_config = configs("test", {"PRODUCT_NAME": "$(TARGET_NAME)", "PRODUCT_BUNDLE_IDENTIFIER": "dk.fantasiven.tests", "GENERATE_INFOPLIST_FILE": "YES", "TARGETED_DEVICE_FAMILY": "1", "CODE_SIGN_STYLE": "Automatic", "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/FantasiVen.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/FantasiVen", "BUNDLE_LOADER": "$(TEST_HOST)", "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks @loader_path/Frameworks"})
    target = obj("target", f'isa = PBXNativeTarget; buildConfigurationList = {app_config}; buildPhases = ({sources}, {frameworks}, {resource_phase}); buildRules = (); dependencies = (); name = FantasiVen; productName = FantasiVen; productReference = {app}; productType = "com.apple.product-type.application";')
    proxy = obj("proxy", f'isa = PBXContainerItemProxy; containerPortal = {ident("project")}; proxyType = 1; remoteGlobalIDString = {target}; remoteInfo = FantasiVen;')
    dependency = obj("dependency", f'isa = PBXTargetDependency; target = {target}; targetProxy = {proxy};')
    test_target = obj("test-target", f'isa = PBXNativeTarget; buildConfigurationList = {test_config}; buildPhases = ({test_sources}, {test_frameworks}); buildRules = (); dependencies = ({dependency}); name = FantasiVenTests; productName = FantasiVenTests; productReference = {test_app}; productType = "com.apple.product-type.bundle.unit-test";')
    project = obj("project", f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; TargetAttributes = {{ {target} = {{ CreatedOnToolsVersion = 16.0; }}; {test_target} = {{ CreatedOnToolsVersion = 16.0; TestTargetID = {target}; }}; }}; }}; buildConfigurationList = {project_config}; compatibilityVersion = "Xcode 14.0"; developmentRegion = da; knownRegions = (da, en, Base); mainGroup = {group}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = ({target}, {test_target});')
    folder = ROOT / "FantasiVen.xcodeproj"
    folder.mkdir(exist_ok=True)
    text = '// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'
    text += "\n".join(f'{key} = {{ {value} }};' for key, value in objects.items())
    text += f'\n}}; rootObject = {project}; }}\n'
    (folder / "project.pbxproj").write_text(text, encoding="utf-8")
    scheme = folder / "xcshareddata/xcschemes/FantasiVen.xcscheme"
    scheme.parent.mkdir(parents=True, exist_ok=True)
    def reference(target_id, name, product):
        return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target_id}" BuildableName="{product}" BlueprintName="{name}" ReferencedContainer="container:FantasiVen.xcodeproj"/>'
    app_ref = reference(target, "FantasiVen", "FantasiVen.app")
    test_ref_xml = reference(test_target, "FantasiVenTests", "FantasiVenTests.xctest")
    scheme.write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app_ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO" parallelizable="NO">{test_ref_xml}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugServiceExtension="internal"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''', encoding="utf-8")
    print(f"Generated Xcode project: {len(source_builds)} Swift files, application + tests")

if __name__ == "__main__":
    generate()
