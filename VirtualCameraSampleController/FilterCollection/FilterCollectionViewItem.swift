//
//  FilterCollectionViewItem.swift
//  VirtualCameraSampleController
//
//  Created by Jaiten Gill on 2021-03-03.
//

class FilterCollectionViewItem: NSCollectionViewItem {


    var name: String? {
        didSet {
            guard isViewLoaded else {return}
            if let name = name {
                textField?.stringValue = name
            }
        }
    }
    
    var image: NSImage? {
        didSet {
            guard isViewLoaded else {return}
            if let image = image {
                imageView?.image = image
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
    }
}
