/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Handles the page request to about/home/ so that the page loads and does not throw an error (404) on initialization
 */
import GCDWebServers

struct AboutHomeHandler {
    static func register(_ webServer: WebServer) {
        webServer.registerHandlerForMethod("GET", module: "about", resource: "home") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            return GCDWebServerResponse(statusCode: 200)
        }
    }
}

struct AboutLicenseHandler {
    static func register(_ webServer: WebServer) {
        webServer.registerHandlerForMethod("GET", module: "about", resource: "license") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            let path = Bundle.main.path(forResource: "Licenses", ofType: "html")
            do {
                let html = try NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue) as String
                return GCDWebServerDataResponse(html: html)
            } catch {
                debugPrint("Unable to register webserver \(error)")
            }
            return GCDWebServerResponse(statusCode: 200)
		}
	}
}

struct AboutEulaHandler {
    static func register(_ webServer: WebServer) {
        webServer.registerHandlerForMethod("GET", module: "about", resource: "eula") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            let path = Bundle.main.path(forResource: "Eula", ofType: "html")
            do {
                let html = try NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue) as String
                return GCDWebServerDataResponse(html: html)
            } catch {
                debugPrint("Unable to register webserver \(error)")
            }
            return GCDWebServerResponse(statusCode: 200)
        }
    }
}

extension GCDWebServerDataResponse {
    convenience init(XHTML: String) {
        let data = XHTML.data(using: String.Encoding.utf8, allowLossyConversion: false)
        self.init(data: data, contentType: "application/xhtml+xml; charset=utf-8")
    }
}
