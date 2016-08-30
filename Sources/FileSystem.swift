//
//    Copyright (c) 2016, yuuji
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//    The views and conclusions contained in the software and documentation are those
//    of the authors and should not be interpreted as representing official policies,
//    either expressed or implied, of the FreeBSD Project.
//

import Foundation
import spartanX
import CKit

public enum Resource {
    case available(Data?)
    case restricted(Data?)
    case notfound(Data?)
    case inavailable(Data?)
}

#if os(Linux) || os(FreeBSD)
    extension ObjCBool {
        var boolValue: Bool {
            return self
        }
    }
#endif

public struct SXResoucesConfig {
    
    public var trustedDirectory: [String]
    public var restrictedPaths: [String]
    public var root: String
    public var allowDir: Bool
    
    public func contents(at path: String, isDirectory: Bool) -> Data? {
        if isDirectory && directoryRepresentation != nil {
            return directoryRepresentation!(path)
        }
        #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        return FileManager.default.contents(atPath: path)
        #else
        return FileManager.default().contents(atPath: path)
        #endif
    }
    
    public var virtualPathPolicy: ((_ path: String) -> [String: (path: String, fullpath: Bool)])?
    public var restrictionPolicy: ((_ path: String, _ isDirectory: Bool) -> Bool)?
    
    public var restrictedResourcesRepresentation: ((_ path: String) -> Data)?
    public var resourceNotFoundRepresentation: ((_ path: String) -> Data)?
    public var directoryRepresentation: ((_ path: String) -> Data?)?
    
    public mutating func setVirtualPathPolicy(_ policy: ((_ path: String) -> [String: (path: String, fullpath: Bool)])?) {
        self.virtualPathPolicy = policy
    }
    
    public mutating func setRestrictionPolicy(_ policy: ((_ path: String, _ isDirectory: Bool) -> Bool)?) {
        self.restrictionPolicy = policy
    }
    
    public mutating func setResourceNotFoundRepresentation(_ policy: ((_ path: String) -> Data)?) {
        self.resourceNotFoundRepresentation = policy
    }
    
    public mutating func setDirectoryRepresentation(_ policy: ((_ path: String) -> Data)?) {
        self.directoryRepresentation = policy
    }
    
    public mutating func setRestrictedResoucesRepresentation(_ policy: ((_ path: String) -> Data)?) {
        self.restrictedResourcesRepresentation = policy
    }
    
    public func contentIsRestricted(at path: String, isDir: Bool) -> Bool {
        if isDir && !allowDir { return true }
        
        if let _ = restrictionPolicy {
            if restrictionPolicy!(path, isDir) {
                return true
            }
        }
        
        var trusted: Bool = false
        
        if !path.hasPrefix(root) {
            for dir in trustedDirectory {
                if path.hasPrefix(dir) {
                    trusted = true
                }
            }
        } else {
            trusted = true
        }
        
        if !trusted { return true }
        
        return false
    }
    
    public func resource(atPath path: String) -> Resource {
        
        guard let fullpath = expandToFullPath(path: root + path, virtualPathPolicy: virtualPathPolicy) ,
            fullpath != "" else { return .notfound(resourceNotFoundRepresentation?(path)) }
        
        var isDir = ObjCBool(false)
        #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        let exists = FileManager.default.fileExists(atPath: fullpath, isDirectory: &isDir)
        #else
        let exists = FileManager.default().fileExists(atPath: fullpath, isDirectory: &isDir)
        #endif
        return exists ? contentIsRestricted(at: fullpath, isDir: isDir.boolValue) ? .restricted(restrictedResourcesRepresentation?(fullpath)) : .available(contents(at: fullpath, isDirectory: isDir.boolValue)) : .notfound(resourceNotFoundRepresentation?(fullpath))
    }
    
    public init(trustedDirectory: [String], restrictedPaths: [String], root: String, allowDir: Bool) {
        self.trustedDirectory = trustedDirectory
        self.restrictedPaths = restrictedPaths
        self.root = root
        self.allowDir = allowDir
    }
    
}

public func expandToFullPath(path: String, virtualPathPolicy: ((_ path: String) -> [String: (path: String, fullpath: Bool)])?) -> String? {
    var root = "/"
    
    search: for component in path.components(separatedBy: "/") {
        
        let component = component
        
        if let virtualPathPolicy = virtualPathPolicy {
            let map = virtualPathPolicy(root)
            if map.keys.contains(component) {
                let (newpath, isFullPath) = map[component]!
                if isFullPath {
                    root = newpath
                    continue search
                } else {
                    root = root + "\(root == "/" ? "" : "/")" + newpath
                    continue search
                }
                
            }
        }
        
        if component == "" { continue }
        else if component == ".." {
            var _components = root.components(separatedBy: "/")
            _components.removeLast()
            root = ""
            for compo in _components {
                if compo != "" {
                    root = root + "/" + compo
                }
            }
            continue
        } else if component == "." {
            continue
        }
        
        guard let dirent = findFile_r(atDirPath: root , file: component) else { return "" }
        
        if dirent.type == .symbolicLink {
            var buffer = [Int8](repeating: 0, count: 1024)
            readlink(root + "/" + dirent.name, &buffer, 1024)
            root = String(cString: buffer)
        } else {
            root = root + "\(root == "/" ? "" : "/")" + component
        }
    }
    
    return root
}
