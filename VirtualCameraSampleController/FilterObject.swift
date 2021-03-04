//
//  FilterObject.swift
//  VirtualCameraSampleController
//
//  Created by Jaiten Gill on 2021-03-03.
//

class FilterObject: NSObject {
    var name: String;
    var path: String;
    var image: NSImage;
    
    init(name: String, path: String, image: NSImage) {
        self.name = name
        self.path = path
        self.image = image
    }
}
