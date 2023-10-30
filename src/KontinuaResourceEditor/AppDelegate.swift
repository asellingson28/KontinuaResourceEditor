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
    
    // All the topic ids
    public var topicList:[String]
    // The details about each topic
    public var topicDict:[String:Topic]

    override init() {
        self.topicDict = [:]
        self.topicList = []
    }
  
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let defaults = UserDefaults()
        // The user can have the latest topic_index
        var path = defaults.value(forKeyPath: PrefsController.pathKey) as? String
        
        // Or use the one in the app wrapper
        if path == nil {
            path = Bundle.main.path(forResource:"topic_index", ofType: "json")
        }

        do {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: path!))
            let decoder = JSONDecoder()
            topicDict = try decoder.decode([String:Topic].self, from: jsonData)
            topicList = Array(topicDict.keys)
        } catch {
            os_log("Parsing error: \(error)")
        }
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
    
    // Bring the Preferences Panel on screen
    @IBAction func showPrefs(_ sender:Any) {
        let prefs = PrefsController()
        prefs.showWindow(nil)
    }
}

