/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebImage
import XCGLogger

private let log = Logger.browserLogger

class TestAppDelegate: AppDelegate {
    override func getProfile(_ application: UIApplication) -> Profile {
        if let profile = self.profile {
            return profile
        }

        let profile = BrowserProfile(localName: "testProfile", app: application)
        if ProcessInfo.processInfo.arguments.contains(LaunchArguments.ClearProfile) {
            // Use a clean profile for each test session.
            _ = try? profile.files.removeFilesInDirectory()
            profile.prefs.clearAll()

            // Don't show the What's New page.
            profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)

            // Skip the intro when requested by for example tests or automation
            if AppConstants.SkipIntro {
                profile.prefs.setInt(1, forKey: IntroViewControllerSeenProfileKey)
            }
        }

        self.profile = profile
        return profile
    }

    override func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // If the app is running from a XCUITest reset all settings in the app
        if ProcessInfo.processInfo.arguments.contains(LaunchArguments.ClearProfile) {
            resetApplication()
        }

        return super.application(application, willFinishLaunchingWithOptions: launchOptions)
    }

    /**
     Use this to reset the application between tests.
     **/
    func resetApplication() {
        log.debug("Wiping everything for a clean start.")

        // Clear image cache
        SDImageCache.shared().clearDisk()
        SDImageCache.shared().clearMemory()

        // Clear the cookie/url cache
        URLCache.shared.removeAllCachedResponses()
        let storage = HTTPCookieStorage.shared
        if let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }

        // Clear the documents directory
        var rootPath: String = ""
        if let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier(), let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedContainerIdentifier) {
            rootPath = url.path
        } else {
            rootPath = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0])
        }
        let manager = FileManager.default
        let documents = URL(fileURLWithPath: rootPath)
        let docContents = try! manager.contentsOfDirectory(atPath: rootPath)
        for content in docContents {
            do {
                try manager.removeItem(at: documents.appendingPathComponent(content))
            } catch {
                log.debug("Couldn't delete some document contents.")
            }
        }
    }

}
