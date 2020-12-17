//
//  CollectionViewItem.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa



class ClickedCollectionView: NSCollectionView {
    var clickedIndex: Int?
    var uploadSettingsViewController : UploadSettingsViewController!
    
    override func menu(for event: NSEvent) -> NSMenu? {
        clickedIndex = nil

        let point = convert(event.locationInWindow, from: nil)
        for index in 0..<numberOfItems(inSection: 0) {
            let frame = frameForItem(at: index)
            if NSMouseInRect(point, frame, isFlipped) {
                clickedIndex = index
                break
            }
        }
        if clickedIndex == nil {
            return nil
        }
        let indexPath = IndexPath(item: clickedIndex!, section: 0)
        let node = (self.item(at: indexPath) as! CollectionViewItem).node
        let uploadItemFormat = NSLocalizedString("context upload string", comment: "")
        let uploadMenuItemTitle = String(format: uploadItemFormat, node!.title)
        let menu = NSMenu()
        let item = NSMenuItem(title: uploadMenuItemTitle, action: #selector(upload(_:)), keyEquivalent: "")
        item.representedObject = node
        menu.addItem(item)
        return menu
    }
    
    @objc func upload(_ item: NSMenuItem) {
        if(uploadSettingsViewController == nil) {
            uploadSettingsViewController = UploadSettingsViewController()
            uploadSettingsViewController.showId = (item.representedObject as? Node)!.identifier // showId
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let uploadSettingsWindowController = storyboard.instantiateController(withIdentifier: "UploadSettingsWindow") as? NSWindowController
            if let uploadSettingsWindow = uploadSettingsWindowController!.window {
                //let application = NSApplication.shared
                //application.runModal(for: downloadWindow)
                uploadSettingsWindow.level = NSWindow.Level.modalPanel
                let controller =  NSWindowController(window: uploadSettingsWindow)
                uploadSettingsWindow.contentViewController = uploadSettingsViewController
                controller.showWindow(self)
                
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(resetViewController(_:)),
                    name: Notification.Name(WindowViewController.NotificationNames.DismissUploadSettingsDialog),
                    object: nil)
            }
            uploadSettingsViewController.showNameField.stringValue = (item.representedObject as? Node)!.title
            //uploadSettingsViewController.shootDate.dateValue = Date()
        }
    }
    
    @objc func resetViewController(_ sender: Any)
    {
        uploadSettingsViewController = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.DismissUploadSettingsDialog),
            object: nil)
    }
}


class CollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    var node: Node? {
        didSet {
            guard isViewLoaded else { return }
            if let node = node {
                imageView?.image = node.nodeIconResized
                textField?.stringValue = node.title
            } else {
                imageView?.image = nil
                textField?.stringValue = ""
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
    }
    
    func setHighlight(selected: Bool) {
        self.view.layer?.backgroundColor = isSelected ? NSColor.gray.cgColor : NSColor.clear.cgColor
    }
}
