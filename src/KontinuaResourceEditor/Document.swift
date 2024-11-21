//
//  Document.swift
//  KontinuaResourceEditor
//
//  Created by Aaron Hillegass on 10/18/23.
//

import Cocoa
import os

class Document: NSDocument {
    
    @IBOutlet weak var videoTableView: NSTableView!
    @IBOutlet weak var objectiveTableView: NSTableView!
    @IBOutlet weak var referenceTableView: NSTableView!
    @IBOutlet weak var filesTableView: NSTableView!
    @IBOutlet weak var requiresTableView: NSTableView!
    
    @IBOutlet weak var addVideoButton: NSButton!
    @IBOutlet weak var removeVideoButton: NSButton!
    @IBOutlet weak var addObjectiveButton: NSButton!
    @IBOutlet weak var removeObjectiveButton: NSButton!
    @IBOutlet weak var addFileButton: NSButton!
    @IBOutlet weak var removeFileButton: NSButton!
    @IBOutlet weak var addRequiresButton: NSButton!
    @IBOutlet weak var removeRequiresButton: NSButton!
    @IBOutlet weak var addReferenceButton: NSButton!
    @IBOutlet weak var removeReferenceButton: NSButton!
    
    // Topic picker panel
    @IBOutlet weak var pickerWindow: NSWindow!
    @IBOutlet weak var topicTableView: NSTableView!
    
    var chapter: Chapter
    var selectedObjectiveIndex: Int

    // Initialize with an empty chapter
    override init() {
        self.chapter = Chapter(files: [], requires: [], covers: [])
        
        // Nothing selected in the objectives table view
        self.selectedObjectiveIndex = -1
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("Document")
    }

    override func data(ofType typeName: String) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        return try encoder.encode(chapter)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        let decoder = JSONDecoder()
        do {
            chapter = try decoder.decode(Chapter.self, from: data)
        } catch {
            os_log("Parsing error: \(error)")
            let a = NSAlert(error:error)
            a.runModal()
            
        }
    }

    override func windowControllerDidLoadNib(_ windowController: NSWindowController)
    {
        super.windowControllerDidLoadNib(windowController)
        self.updateButtons()
    }
}

extension Document {
    
    // Get a URL off the general pasteboard (as a string)
    func pbURL() -> String? {
        let pasteboard = NSPasteboard.general
        var read = pasteboard.pasteboardItems?.first?.string(forType:.URL)
        if read != nil {
            return read
        }
        // Check the string to see if it is URL-like
        read = pasteboard.pasteboardItems?.first?.string(forType:.string)
        if let url:String = read {
            let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            if let match = detector.firstMatch(in:url, options: [], range: NSRange(location: 0, length: url.utf16.count)) {
                // it is a link, if the match covers the whole string
                if (match.range.length == url.utf16.count) {
                    return url
                }
            }
        }
        return nil
    }
      
    // What table view is currently in the responder chain?
    func selectedTableView() -> NSTableView? {
        var r = removeFileButton.window?.firstResponder
        while let node:NSResponder = r {
            if r is NSTableView {
                return r as? NSTableView
            }
            r = node.nextResponder
        }
        return nil
    }

    // For the menu item (and keyboard equivalent)
    @IBAction func delete(_ sender: AnyObject) {
        let tv = self.selectedTableView()
        if tv == filesTableView {
            self.removeFile(sender: self)
            return
        }
        if tv == objectiveTableView {
            self.removeObjective(sender: self)
            return
        }
        if tv == requiresTableView {
            self.removeRequires(sender: self)
            return
        }
        if tv == videoTableView {
            self.removeVideo(sender: self)
            return
        }
        if tv == referenceTableView {
            self.removeReference(sender: self)
            return
        }
    }
    
    func removeFile(loc:Int) {
        filesTableView.beginUpdates()
        let toDelete = self.chapter.files[loc]
        self.undoManager?.registerUndo(withTarget: self,
                                       handler:{
            (targetSelf) in targetSelf.insertFile(file:toDelete, at:loc)
        })
        var indexSet = IndexSet()
        indexSet.insert(loc)
        self.chapter.files.remove(at: loc)
        filesTableView.removeRows(at:indexSet)
        filesTableView.endUpdates()

    }
    func insertFile(file:FileRef, at:Int) {
        filesTableView.beginUpdates()
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.removeFile(loc:at)
        })
        var indexSet = IndexSet()
        indexSet.insert(at)
        self.chapter.files.insert(file, at: at)
        filesTableView.insertRows(at: indexSet)
        filesTableView.endUpdates()
    }
    func replaceFilePath(at:Int,with newPath:String) {
        let oldValue = chapter.files[at].path
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.replaceFilePath(at: at, with: oldValue)
        })
        self.chapter.files[at].path = newPath
        var rowIndexSet = IndexSet()
        rowIndexSet.insert(at)
        var colIndexSet = IndexSet()
        colIndexSet.insert(0)
        colIndexSet.insert(1)
        filesTableView.reloadData(forRowIndexes:rowIndexSet, columnIndexes:colIndexSet)
    }
    
    func replaceFileDesc(at:Int,with newDesc:String) {
        let oldValue = chapter.files[at].desc
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.replaceFileDesc(at: at, with: oldValue)
        })
        self.chapter.files[at].desc = newDesc
        var rowIndexSet = IndexSet()
        rowIndexSet.insert(at)
        var colIndexSet = IndexSet()
        colIndexSet.insert(0)
        colIndexSet.insert(1)
        filesTableView.reloadData(forRowIndexes:rowIndexSet, columnIndexes:colIndexSet)
    }
    @IBAction func addFile(sender: AnyObject) {
        self.videoTableView.window?.endEditing(for: nil)
        let newFile = FileRef()
        newFile.path = "New"
        newFile.desc = "New"
        let loc = self.chapter.files.count
        self.insertFile(file:newFile, at: loc)
        filesTableView.selectRowIndexes(IndexSet(integer:loc), byExtendingSelection:false)
        filesTableView.editColumn(0, row:loc, with:nil, select:true)
    }
    @IBAction func removeFile(sender: AnyObject) {
        self.videoTableView.window?.endEditing(for: nil)
        let r = filesTableView.selectedRow
        if r == -1 {
            return
        }
        self.removeFile(loc:r)
    }
    
    
    func removeRequires(loc:Int) {
        requiresTableView.beginUpdates()
        let toDelete = self.chapter.requires[loc]
        self.undoManager?.registerUndo(withTarget: self,
                                       handler:{
            (targetSelf) in targetSelf.insertRequires(name:toDelete, at:loc)
        })
        var indexSet = IndexSet()
        indexSet.insert(loc)
        self.chapter.requires.remove(at: loc)
        requiresTableView.removeRows(at:indexSet)
        requiresTableView.endUpdates()

    }
    func insertRequires(name:String, at:Int) {
        requiresTableView.beginUpdates()
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.removeRequires(loc:at)
        })
        var indexSet = IndexSet()
        indexSet.insert(at)
        self.chapter.requires.insert(name, at: at)
        requiresTableView.insertRows(at: indexSet)
        requiresTableView.endUpdates()
    }
    func replaceRequires(at:Int, with:String) {
        requiresTableView.beginUpdates()
        let oldValue = chapter.requires[at]
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.replaceRequires(at: at, with: oldValue)
        })
        self.chapter.requires[at] = with
        requiresTableView.endUpdates()
    }
    
    @IBAction func cancelPicker(_ sender: AnyObject) {
        requiresTableView.window?.endSheet(pickerWindow, returnCode:NSApplication.ModalResponse.cancel)
    }
    
    @IBAction func acceptPicker(_ sender: AnyObject) {
        requiresTableView.window?.endSheet(pickerWindow, returnCode:NSApplication.ModalResponse.OK)
    }
    @IBAction func addRequires(sender: AnyObject) {
        self.videoTableView.window?.endEditing(for: nil)
        requiresTableView.window?.beginSheet(pickerWindow, completionHandler: {
            response in
            if response == NSApplication.ModalResponse.OK {
                let appDel = NSApplication.shared.delegate as! AppDelegate
                let row = self.topicTableView.selectedRow
                let key = appDel.topicList[row]
                let lastIndex = self.chapter.requires.count
                self.insertRequires(name:key, at:lastIndex)
            }
        })
    }
    @IBAction func removeRequires(sender: AnyObject) {
        self.videoTableView.window?.endEditing(for: nil)
        let r = requiresTableView.selectedRow
        if r == -1 {
            return
        }
        self.removeRequires(loc:r)
    }
    
    func removeObjective(loc:Int) {
        objectiveTableView.beginUpdates()
        let toDelete = self.chapter.covers[loc]
        self.undoManager?.registerUndo(withTarget: self,
                                       handler:{
            (targetSelf) in targetSelf.insertObjective(obj:toDelete, at:loc)
        })
        var indexSet = IndexSet()
        indexSet.insert(loc)
        self.chapter.covers.remove(at: loc)
        objectiveTableView.removeRows(at:indexSet)
        objectiveTableView.endUpdates()
        videoTableView.reloadData()
        referenceTableView.reloadData()
    }
    func insertObjective(obj:Objective, at:Int) {
        objectiveTableView.beginUpdates()
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.removeObjective(loc:at)
        })
        var indexSet = IndexSet()
        indexSet.insert(at)
        self.chapter.covers.insert(obj, at: at)
        objectiveTableView.insertRows(at: indexSet)
        objectiveTableView.endUpdates()
        videoTableView.reloadData()
        referenceTableView.reloadData()
    }
    func replaceObjectiveID(at:Int, with:String) {
        objectiveTableView.beginUpdates()
        let oldValue = chapter.covers[at].id
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.replaceObjectiveID(at: at, with: oldValue)
        })
        self.chapter.covers[at].id = with
        objectiveTableView.endUpdates()
    }
    func replaceObjectiveDesc(at:Int, with:String) {
        let oldValue = chapter.covers[at].desc
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.replaceObjectiveDesc(at: at, with: oldValue)
        })
        self.chapter.covers[at].desc = with
    }
    @IBAction func addObjective(sender: AnyObject) {
        self.videoTableView.window?.endEditing(for: nil)
        let newObj = Objective()
        newObj.id = "new"
        newObj.desc = "New"
        let last = self.chapter.covers.count;
        self.insertObjective(obj: newObj, at: last)
        objectiveTableView.selectRowIndexes(IndexSet(integer:last), byExtendingSelection: false)
        objectiveTableView.editColumn(0, row:last, with:nil, select:true)
    }
    @IBAction func removeObjective(sender: AnyObject) {
        self.videoTableView.window?.endEditing(for: nil)

        let r = objectiveTableView.selectedRow
        if r == -1 {
            return
        }
        self.removeObjective(loc:r)
    }
    
    func removeVideo(loc:Int, from obj:Objective) {
        videoTableView.beginUpdates()
        let toDelete = obj.videos[loc]
        self.undoManager?.registerUndo(withTarget: self,
                                       handler:{
            (targetSelf) in targetSelf.insertVideo(name:toDelete, at:loc, of:obj)
        })
        var indexSet = IndexSet()
        indexSet.insert(loc)
        obj.videos.remove(at: loc)
        if selectedObjectiveIndex != -1 && chapter.covers[selectedObjectiveIndex].id == obj.id {
            videoTableView.removeRows(at:indexSet)

        }
        videoTableView.endUpdates()

    }
    func insertVideo(name:String, at:Int, of obj:Objective) {
        videoTableView.beginUpdates()
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.removeVideo(loc:at, from:obj)
        })
        var indexSet = IndexSet()
        indexSet.insert(at)
        obj.videos.insert(name, at: at)
        if selectedObjectiveIndex != -1 && chapter.covers[selectedObjectiveIndex].id == obj.id {
            videoTableView.insertRows(at: indexSet)
        }
        videoTableView.endUpdates()
    }
    func replaceVideo(at:Int, with:String, of obj:Objective) {
        let oldValue = obj.videos[at]
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.replaceVideo(at: at, with: oldValue, of:obj)
        })
        obj.videos[at] = with
    }
    @IBAction func addVideo(sender: AnyObject) {
        if selectedObjectiveIndex == -1 {
            return
        }
        self.videoTableView.window?.endEditing(for: nil)
        let currentObj = chapter.covers[selectedObjectiveIndex]
        let lastIndex = currentObj.videos.count
        let url = self.pbURL()
        if url == nil {
            self.insertVideo(name:"New", at: lastIndex, of:currentObj)
            videoTableView.selectRowIndexes(IndexSet(integer:lastIndex), byExtendingSelection:false)
            videoTableView.editColumn(0, row:lastIndex, with:nil, select:true)
        } else {
            self.insertVideo(name:url!, at:lastIndex, of:currentObj)
            videoTableView.selectRowIndexes(IndexSet(integer:lastIndex), byExtendingSelection:false)
        }
    }
    @IBAction func removeVideo(sender: AnyObject) {
        if selectedObjectiveIndex == -1 {
            return
        }
        self.videoTableView.window?.endEditing(for: nil)

        let currentObj = chapter.covers[selectedObjectiveIndex]
        let r = videoTableView.selectedRow
        if r == -1 {
            return
        }
        self.removeVideo(loc: r, from:currentObj)
    }
  
    func removeReference(loc:Int, from obj:Objective) {
        referenceTableView.beginUpdates()
        let toDelete = obj.references[loc]
        self.undoManager?.registerUndo(withTarget: self,
                                       handler:{
            (targetSelf) in targetSelf.insertReference(name:toDelete, at:loc, of:obj)
        })
        var indexSet = IndexSet()
        indexSet.insert(loc)
        obj.references.remove(at: loc)
        if selectedObjectiveIndex != -1 && chapter.covers[selectedObjectiveIndex].id == obj.id {
            referenceTableView.removeRows(at:indexSet)
        }
        referenceTableView.endUpdates()

    }
    func insertReference(name:String, at:Int, of obj:Objective) {
        referenceTableView.beginUpdates()
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.removeReference(loc:at, from:obj)
        })
        var indexSet = IndexSet()
        indexSet.insert(at)
        obj.references.insert(name, at: at)
        if selectedObjectiveIndex != -1 && chapter.covers[selectedObjectiveIndex].id == obj.id {
            referenceTableView.insertRows(at: indexSet)
        }
        referenceTableView.endUpdates()
    }
    func replaceReference(at:Int, with:String, of obj:Objective) {
        let oldValue = obj.references[at]
        self.undoManager?.registerUndo(withTarget: self,
                                       handler: {
            (targetSelf) in targetSelf.replaceReference(at: at, with: oldValue, of:obj)
        })
        obj.references[at] = with
    }
    @IBAction func addReference(sender: AnyObject) {
        if selectedObjectiveIndex == -1 {
            return
        }
        self.videoTableView.window?.endEditing(for: nil)
        let currentObj = chapter.covers[selectedObjectiveIndex]
        let lastIndex = currentObj.references.count
        let url = self.pbURL()
        if url == nil {
            self.insertReference(name:"New", at:lastIndex, of:currentObj)
            referenceTableView.selectRowIndexes(IndexSet(integer:lastIndex), byExtendingSelection: false)
            referenceTableView.editColumn(0, row:lastIndex, with:nil, select:true)
        } else {
            self.insertReference(name:url!, at:lastIndex, of:currentObj)
        }
    }
    @IBAction func removeReference(sender: AnyObject) {
        if selectedObjectiveIndex == -1 {
            return
        }
        self.videoTableView.window?.endEditing(for: nil)
        let currentObj = chapter.covers[selectedObjectiveIndex]
        let r = referenceTableView.selectedRow
        if r == -1 {
            return
        }
        self.removeReference(loc: r, from:currentObj)
    }
}

extension Document: NSTableViewDelegate, NSTableViewDataSource {

    func updateButtons() {
        if selectedObjectiveIndex == -1 {
            addVideoButton.isEnabled = false
            addReferenceButton.isEnabled = false
            removeObjectiveButton.isEnabled = false
        } else {
            addVideoButton.isEnabled = true
            addReferenceButton.isEnabled = true
            removeObjectiveButton.isEnabled = true
        }
        removeRequiresButton.isEnabled = (requiresTableView.selectedRow != -1)
        removeFileButton.isEnabled = (filesTableView.selectedRow != -1)
        removeVideoButton.isEnabled = (videoTableView.selectedRow != -1)
        removeReferenceButton.isEnabled = (referenceTableView.selectedRow != -1)
    }
    

    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == topicTableView {
            let appDel = NSApplication.shared.delegate as! AppDelegate
            return appDel.topicList.count
        }
        if tableView == filesTableView {
            return chapter.files.count
        }
        if tableView == objectiveTableView {
            return chapter.covers.count
        }
        if tableView == requiresTableView {
            return chapter.requires.count
        }
        if selectedObjectiveIndex  == -1 {
            return 0
        } else {
            let obj = chapter.covers[selectedObjectiveIndex]
            if tableView == videoTableView {
                return obj.videos.count
            } else {
                return obj.references.count
            }
        }
     }
    func tableView(
        _ tableView: NSTableView,
        objectValueFor tableColumn: NSTableColumn?,
        row: Int
    ) -> Any?
    {
        if tableView == topicTableView {
            let appDel = NSApplication.shared.delegate as! AppDelegate
            let key = appDel.topicList[row]
            let identifier = (tableColumn?.identifier)!
            if identifier.rawValue  == "id" {
                return key
            } else {
                return appDel.topicDict[key]!.desc
            }
            
        }
        if tableView == filesTableView {
            let obj:FileRef = chapter.files[row]
            let key = (tableColumn?.identifier)!
            if key.rawValue  == "path" {
                return obj.path
            } else {
                return obj.desc
            }
        }
        
        if tableView == requiresTableView {
            return chapter.requires[row]
        }
        if tableView == objectiveTableView {
            let obj:Objective = chapter.covers[row]
            let key = (tableColumn?.identifier)!
            if key.rawValue  == "id" {
                return obj.id
            } else {
                return obj.desc
            }
        }
        let obj = chapter.covers[selectedObjectiveIndex]
        if tableView == videoTableView {
            if row < obj.videos.count {
                return obj.videos[row]
            } else {
                return "ERROR!"
            }
        } else {
            if row < obj.references.count {
                return obj.references[row]
            } else {
                return "ERROR!"
            }
        }
    }

    func tableView(_ tableView: NSTableView, 
                   setObjectValue object: Any?,
                   for tableColumn: NSTableColumn?,
                   row: Int)
    {
        let str = object as! String
        if tableView == filesTableView {
            let key = (tableColumn?.identifier)!
            if key.rawValue  == "path" {
                self.replaceFilePath(at: row, with: str)
            } else {
                self.replaceFileDesc(at:row, with:str)
            }
            return
        }
        if tableView == requiresTableView {
            self.replaceRequires(at:row, with:str)
            return
        }
        if tableView == objectiveTableView {
            let key = (tableColumn?.identifier)!
            if key.rawValue  == "id" {
                self.replaceObjectiveID(at: row, with: str)
            } else {
                self.replaceObjectiveDesc(at:row, with:str)
            }
            return
        }
        if tableView == videoTableView {
            if selectedObjectiveIndex == -1 {
                return
            }
            let obj = chapter.covers[selectedObjectiveIndex]
            self.replaceVideo(at: row, with: str, of: obj)
            return
        }
        if tableView == referenceTableView {
            if selectedObjectiveIndex == -1 {
                return
            }
            let obj = chapter.covers[selectedObjectiveIndex]
            self.replaceReference(at: row, with: str, of: obj)
            return
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        if notification.object as? NSTableView == objectiveTableView {
            selectedObjectiveIndex = objectiveTableView.selectedRow
            videoTableView.reloadData()
            referenceTableView.reloadData()
        }
        self.updateButtons()
    }
 
}
