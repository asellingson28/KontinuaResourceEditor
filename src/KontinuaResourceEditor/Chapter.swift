//
//  Chapter.swift
//  KontinuaResourceEditor
//
//  Created by Aaron Hillegass on 10/18/23.
//

import Foundation

class Objective:Codable {
    var id: String  = ""
    var desc: String
    var videos: [String]
    var references: [String]
    
    init() {
        desc = ""
        videos = []
        references = []
    }
}

struct Chapter: Codable {
    var files: [String]
    var requires: [String]
    var covers: [Objective]
}
