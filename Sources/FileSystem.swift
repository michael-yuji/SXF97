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
import LinuxFoundation
import spartanX

public enum Resource {
    case available(Data?)
    case restricted(Data?)
    case notfound(Data?)
    case inavailable(Data?)
}

public struct SXResoucesConfig {
    
    public var trustedDirectory: [String]
    public var restrictedPaths: [String]
    public var root: String
    public var allowDir: Bool
    
    public func contents(at path: String, isDirectory: Bool) -> Data? {
        if isDirectory && directoryRepresentation != nil {
            return directoryRepresentation!(path: path)
        }
        #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        return FileManager.default.contents(atPath: path)
        #else
        return FileManager.default().contents(atPath: path)
        #endif
    }
    
    public var virtualPathPolicy: ((path: String) -> [String: (path: String, fullpath: Bool)])?
    public var restrictionPolicy: ((path: String, isDirectory: Bool) -> Bool)?
    
    public var restrictedResourcesRepresentation: ((path: String) -> Data)?
    public var resouceNotFoundRepresentation: ((path: String) -> Data)?
    public var directoryRepresentation: ((path: String) -> Data?)?
    
    public mutating func setVirtualPathPolicy(_ policy: ((path: String) -> [String: (path: String, fullpath: Bool)])?) {
        self.virtualPathPolicy = policy
    }
    
    public mutating func setRestrictionPolicy(_ policy: ((path: String, isDirectory: Bool) -> Bool)?) {
        self.restrictionPolicy = policy
    }
    
    public mutating func setResouceNotFoundRepresentation(_ policy: ((path: String) -> Data)?) {
        self.resouceNotFoundRepresentation = policy
    }
    
    public mutating func setDirectoryRepresentation(_ policy: ((path: String) -> Data)?) {
        self.directoryRepresentation = policy
    }
    
    public mutating func setRestrictedResoucesRepresentation(_ policy: ((path: String) -> Data)?) {
        self.restrictedResourcesRepresentation = policy
    }
    
    public func contentIsRestricted(at path: String, isDir: Bool) -> Bool {
        if isDir && !allowDir { return true }
        
        if let _ = restrictionPolicy {
            if restrictionPolicy!(path: path, isDirectory: isDir) {
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
        
        guard let fullpath = expandToFullPath(path: root + path, virtualPathPolicy: virtualPathPolicy) where
            fullpath != "" else { return .notfound(resouceNotFoundRepresentation?(path: path)) }
        print(fullpath)
        var isDir = ObjCBool(false)
        #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        let exists = FileManager.default.fileExists(atPath: fullpath, isDirectory: &isDir)
        #else
        let exists = FileManager.default().fileExists(atPath: fullpath, isDirectory: &isDir)
        #endif
        return exists ? contentIsRestricted(at: fullpath, isDir: isDir.boolValue) ? .restricted(restrictedResourcesRepresentation?(path: fullpath)) : .available(contents(at: fullpath, isDirectory: isDir.boolValue)) : .notfound(resouceNotFoundRepresentation?(path: fullpath))
    }
    
    public init(trustedDirectory: [String], restrictedPaths: [String], root: String, allowDir: Bool) {
        self.trustedDirectory = trustedDirectory
        self.restrictedPaths = restrictedPaths
        self.root = root
        self.allowDir = allowDir
    }
    
}

public func expandToFullPath(path: String, virtualPathPolicy: ((path: String) -> [String: (path: String, fullpath: Bool)])?) -> String? {
    var root = "/"
    
    search: for component in path.components(separatedBy: "/") {
        
        let component = component
        
        if let virtualPathPolicy = virtualPathPolicy {
            let map = virtualPathPolicy(path: root)
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

public struct POSIXFileTypes : RawRepresentable, CustomStringConvertible {
    public var rawValue: Int32
    public static let unknown = POSIXFileTypes(rawValue: DT_UNKNOWN)
    public static let namedPipe = POSIXFileTypes(rawValue: DT_FIFO)
    public static let characterDevice = POSIXFileTypes(rawValue: DT_CHR)
    public static let directory = POSIXFileTypes(rawValue: DT_DIR)
    public static let blockDevice = POSIXFileTypes(rawValue: DT_BLK)
    public static let regular = POSIXFileTypes(rawValue: DT_REG)
    public static let symbolicLink = POSIXFileTypes(rawValue: DT_LNK)
    public static let socket = POSIXFileTypes(rawValue: DT_SOCK)
    #if os(OSX) || os(FreeBSD)
    public static let whiteOut = POSIXFileTypes(rawValue: DT_WHT)
    #endif
    
    public var description: String {
        #if os(OSX) || os(FreeBSD)
            switch self.rawValue {
            case POSIXFileTypes.unknown.rawValue: return "unknown"
            case POSIXFileTypes.namedPipe.rawValue: return "namedPipe"
            case POSIXFileTypes.characterDevice.rawValue: return "chracterDevice"
            case POSIXFileTypes.directory.rawValue: return "directory"
            case POSIXFileTypes.blockDevice.rawValue: return "blockDevice"
            case POSIXFileTypes.regular.rawValue: return "regular"
            case POSIXFileTypes.symbolicLink.rawValue: return "softlink"
            case POSIXFileTypes.socket.rawValue: return "socket"
            case POSIXFileTypes.whiteOut.rawValue: return "whiteout"
            default: return "Invalid val"
            }
        #else
            
            switch self.rawValue {
            case POSIXFileTypes.unknown.rawValue: return "unknown"
            case POSIXFileTypes.namedPipe.rawValue: return "namedPipe"
            case POSIXFileTypes.characterDevice.rawValue: return "chracterDevice"
            case POSIXFileTypes.directory.rawValue: return "directory"
            case POSIXFileTypes.blockDevice.rawValue: return "blockDevice"
            case POSIXFileTypes.regular.rawValue: return "regular"
            case POSIXFileTypes.symbolicLink.rawValue: return "softlink"
            case POSIXFileTypes.socket.rawValue: return "socket"
            default: return "Invalid val"
            }
        #endif
    }
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    /* for Linux */
    public init(rawValue: Int) {
        self.rawValue = Int32(rawValue)
    }
}

public struct Dirent: CustomStringConvertible {
    public var name: String
    public var ino: ino_t
    public var size: Int
    public var type: POSIXFileTypes
    
    init(d: dirent) {
        var dirent = d
        #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        self.name = String(cString: UnsafeMutablePointer<CChar>(spartanX.pointer(of: &(dirent.d_name))), encoding: .utf8)!
        #else
        self.name = String(cString: UnsafeMutablePointer<CChar>(spartanX.pointer(of: &(dirent.d_name))), encoding: .utf8)
        #endif
        self.size = Int(dirent.d_reclen)
        self.type = POSIXFileTypes(rawValue: Int32(dirent.d_type))
        self.ino = dirent.d_ino
    }
    
    public var description: String {
        get {
            return String.alignedText( strings: name, "\(ino)", "\(size)", "\(type)", spaces: [25, 10, 7, 15])
        }
    }
}

public func findFile_r(atDirPath path: String, file: String) -> Dirent? {
    guard let dfd = opendir(path.cString(using: .utf8)!) else {return nil}
    var dir: dirent = dirent()
    var result: UnsafeMutablePointer<dirent>? = nil
    
    
    repeat {
        if readdir_r(dfd, &dir, &result) != 0 {break}
        
        if result == nil { break }
        
        if Dirent(d: result!.pointee).name == file {
            closedir(dfd)
            return Dirent(d: result!.pointee)
        }
        
    } while (result != nil)
    closedir(dfd)
    return nil
}
