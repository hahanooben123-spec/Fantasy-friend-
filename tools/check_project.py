"""Portable integrity checks. These are NOT a Swift compiler or iOS UI tests."""
from pathlib import Path
import json
import plistlib
import re
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

def check():
    project = (ROOT / 'FantasiVen.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
    sources = sorted(p for p in (ROOT/'FantasiVen.swiftpm').rglob('*.swift') if p.name != 'Package.swift')
    for source in sources:
        assert project.count(f'path = "{source.relative_to(ROOT).as_posix()}"') == 1, source
        assert 'import ' in source.read_text(encoding='utf-8'), source
    definitions = set(re.findall(r'^([A-F0-9]{24}) = ', project, re.M))
    references = set(re.findall(r'\b[A-F0-9]{24}\b', project))
    assert references == definitions, references - definitions
    for path in [ROOT/'Configuration/Info.plist', ROOT/'FantasiVen.swiftpm/Resources/PrivacyInfo.xcprivacy']:
        with path.open('rb') as file:
            plistlib.load(file)
    ET.parse(ROOT/'FantasiVen.xcodeproj/xcshareddata/xcschemes/FantasiVen.xcscheme')
    for contents in (ROOT/'FantasiVen.swiftpm/Resources').rglob('Contents.json'):
        data = json.loads(contents.read_text())
        for image in data.get('images', []):
            assert (contents.parent/image['filename']).is_file()
    icon = (ROOT/'FantasiVen.swiftpm/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png').read_bytes()
    assert icon[:8] == b'\x89PNG\r\n\x1a\n'
    assert struct.unpack('>II', icon[16:24]) == (1024, 1024)
    words = (ROOT/'FantasiVen.swiftpm/Localization/Words.swift').read_text(encoding='utf-8')
    keys = re.findall(r'^\s*"([A-Za-z]+)":', words, re.M)
    # Several entries share a line; parse every key at its dictionary separator.
    keys = re.findall(r'"([A-Za-z]+)":\s*\(', words)
    assert len(keys) == len(set(keys)), 'Duplicate localization key'
    for source in sources:
        text = source.read_text(encoding='utf-8')
        for key in re.findall(r'\bt\("([A-Za-z]+)"\)', text):
            assert key in keys, (source, key)
        for forbidden in ['URLSession', 'WKWebView', 'StoreKit', 'AdSupport', 'AppTrackingTransparency']:
            assert forbidden not in text, (source, forbidden)
    info = plistlib.loads((ROOT/'Configuration/Info.plist').read_bytes())
    assert not any('UsageDescription' in key for key in info)
    assert info['UISupportedInterfaceOrientations'] == ['UIInterfaceOrientationPortrait']
    print(f'PASS: {len(sources)} Swift source references, project object references, shared scheme, plists, icon and {len(keys)} bilingual keys')
    print('Swift compilation, XCTest and UI rendering must still run on macOS / iOS.')

if __name__ == '__main__':
    check()
