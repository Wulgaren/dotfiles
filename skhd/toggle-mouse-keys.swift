#!/usr/bin/swift
// Toggles macOS Mouse Keys (Accessibility > Pointer Control), the built-in
// keyboard pointer control. UAMouseKeys* are the private functions the
// Settings app itself uses, because changing the `mouseDriver` pref alone
// does not activate Mouse Keys at runtime.
import Foundation

let framework = "/System/Library/PrivateFrameworks/UniversalAccess.framework/Versions/A/UniversalAccess"
guard dlopen(framework, RTLD_NOW) != nil else {
  FileHandle.standardError.write("cannot load UniversalAccess\n".data(using: .utf8)!)
  exit(1)
}

typealias IsEnabled = @convention(c) () -> Bool
typealias SetEnabled = @convention(c) (Bool) -> Void

guard
  let isSymbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "UAMouseKeysIsEnabled"),
  let setSymbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "UAMouseKeysSetEnabled")
else {
  FileHandle.standardError.write("UAMouseKeys symbols not found\n".data(using: .utf8)!)
  exit(1)
}

let enabled = unsafeBitCast(isSymbol, to: IsEnabled.self)()
unsafeBitCast(setSymbol, to: SetEnabled.self)(!enabled)
