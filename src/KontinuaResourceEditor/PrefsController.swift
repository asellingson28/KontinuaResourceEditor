//
//  PrefsController.swift
//  KontinuaResourceEditor
//
//  Created by Aaron Hillegass on 10/29/23.
//

import Cocoa
import os


class PrefsController: NSWindowController {
    static let pathKey = "ObjectivesFilePath"
    @IBOutlet weak var pathField: NSTextField!

    override var windowNibName: String! {
        return "Prefs"
    }
    
    override func windowDidLoad(){
        let defaults = UserDefaults()
        var path = defaults.value(forKeyPath: PrefsController.pathKey) as? String
        if path == nil {
            path = ""
        }
        pathField.stringValue = path!
    }
    
    @IBAction func startPathPanel(_ sender: AnyObject) {
        os_log("Starting panel")
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin(completionHandler: { (result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                let url = openPanel.url
                if url == nil {
                    return
                }
                let path = url!.path()
                self.pathField.stringValue = path
                let defaults = UserDefaults()
                defaults.setValue(path, forKeyPath: PrefsController.pathKey)
            }
          })
    }
    
}
