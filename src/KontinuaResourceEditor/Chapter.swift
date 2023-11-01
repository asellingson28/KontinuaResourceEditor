//
//  Chapter.swift
//  KontinuaResourceEditor
//
//  Created by Aaron Hillegass on 10/18/23.
//

import Foundation

class Objective:Codable {
    var id: String  = ""
    var desc: String = ""
    var videos: [String]
    var references: [String]
    
    init() {
        videos = []
        references = []
    }
}

class FileRef:Codable {
    var path:String = ""
    var desc:String = ""
}

struct Chapter: Codable {
    var files: [FileRef]
    var requires: [String]
    var covers: [Objective]
}
