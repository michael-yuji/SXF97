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

public struct HTTPResponseEntry {
    public static let AccessControlAllowOrigin = "Access-Control-Allow-Origin"
    public static let AcceptPatch = "Accept-Patch"
    public static let AcceptRanges = "Accept-Ranges"
    public static let Age = "Age"
    public static let Allow = "Allow"
    public static let AltSvc = "Alt-Svc"
    public static let CacheControl = "Cache-Control"
    public static let Connection = "Connection"
    public static let ContentDisposition = "Content-Disposition"
    public static let ContentEncoding = "Content-Encoding"
    public static let ContentLanguage = "Content-Language"
    public static let ContentLength = "Content-Length"
    public static let ContentLocations = "Content-Locations"
    public static let ContentMD5 = "Content-MD5"
    public static let ContentRange = "Content-Range"
    public static let ContentType = "Content-Type"
    public static let Date = "Date"
    public static let Etag = "Etag"
    public static let Expires = "Expires"
    public static let LastModified = "Last-Modified"
    public static let Link = "Link"
    public static let Location = "Location"
    public static let P3P = "P3P"
    public static let Pragma = "Pragma"
    public static let ProxyAuthenticate = "Proxy-Authenticate"
    public static let PublicKeyPins = "Public-Key-Pins"
    public static let Refresh = "Refresh"
    public static let RetryAlter = "Retry-Alter"
    public static let Server = "Server"
    public static let SetCookie = "Set-Cookie"
    public static let Status = "Status"
    public static let StrictTransportSecurity = "Strict-Transport-Security"
    public static let Trailer = "Trailer"
    public static let TransferEncoding = "Transfer-Encoding"
    public static let TSV = "TSV"
    public static let Upgrade = "Upgrade"
    public static let Vary = "Vary"
    public static let Via = "Via"
    public static let Warning = "Warning"
    public static let WWWAuthenticate = "WWW-Authenticate"
    public static let XFrameOptions = "X-Frame-Options"
}

public struct HTTPRequestEntry {
    public static let Accept = "Accept"
    public static let AccepetCharset = "Accpet-Charset"
    public static let AcceptEncoding = "Accept-Encoding"
    public static let AcceptLanguage = "Accept-Language"
    public static let AcceptDatetime = "Accept-Datetime"
    public static let Authorization = "Authorization"
    public static let CacheControl = "CacheControl"
    public static let Connection = "Connection"
    public static let Cookie = "Cookie"
    public static let ContentLength = "Content-Length"
    public static let ContentMD5 = "Content-MD5"
    public static let ContentType = "Content-Type"
    public static let Date = "Date"
    public static let Expect = "Expect"
    public static let Forwarded = "Forwarded"
    public static let From = "From"
    public static let Host = "Host"
    public static let IfMatch = "If-Match"
    public static let IfModifiedSince = "If-Modified-Since"
    public static let IfNoneMatch = "If-None-Match"
    public static let IfRange = "If-Range"
    public static let IfUnmodifiedSince = "If-Unmodified-Since"
    public static let MaxForwards = "Max-Forwards"
    public static let Origin = "Origin"
    public static let Pragma = "Pragma"
    public static let ProxyAuthorization = "Proxy-Authorization"
    public static let Range = "Range"
    public static let Referer = "Referer"
    public static let TE = "TE"
    public static let UserAgenet = "User-Agent"
    public static let Via = "Via"
    public static let Warning = "Warning"
}
