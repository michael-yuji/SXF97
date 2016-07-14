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

public struct HTTPVersion {
    public var mainVersion: Int
    public var subVersion: Int
    
    public var stringVal: String {
        return "HTTP/\(mainVersion).\(subVersion)"
    }
    
    public init?(str: String) {
        var copy = str
        
        if copy.hasPrefix("HTTP/") {
            copy.removeSubrange(Range(copy.startIndex..<copy.index(copy.startIndex, offsetBy: 5)))
            let versions = copy.components(separatedBy: ".")
            guard let main = Int(versions[0]) else {return nil}
            guard let sub = Int(versions[1]) else {return nil}
            (self.mainVersion, self.subVersion) = (main, sub)
        } else {
            return nil
        }
    }
    
    public static let `default` = HTTPVersion(mainVersion: 1, subVersion: 1)
    
    public init(mainVersion: Int, subVersion: Int) {
        (self.mainVersion, self.subVersion) = (mainVersion, subVersion)
    }
}
