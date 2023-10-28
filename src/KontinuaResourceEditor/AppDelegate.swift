//
//  AppDelegate.swift
//  KontinuaResourceEditor
//
//  Created by Aaron Hillegass on 10/18/23.
//

import Cocoa
import os

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        os_log("Checking for untitled")
        return false
    }
}

