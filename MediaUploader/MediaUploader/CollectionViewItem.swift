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
    var currentSection: Int?
    override func menu(for event: NSEvent) -> NSMenu? {
        clickedIndex = nil

        let point = convert(event.locationInWindow, from: nil)
        for section in 0..<numberOfSections {
            for index in 0..<numberOfItems(inSection: section) {
                let frame = layoutAttributesForItem(at: IndexPath(item: index, section: section))?.frame ?? .zero
                if NSMouseInRect(point, frame, isFlipped) {
                    clickedIndex = index
                    currentSection = section
                    break
                }
            }
        }
        if clickedIndex == nil {
            return nil
        }
        let indexPath = IndexPath(item: clickedIndex!, section: currentSection!)
        guard let it = self.item(at: indexPath) as? CollectionViewItem else { return nil }
        guard let node = it.node else { return nil}
        
        let menu = NSMenu()
        menu.autoenablesItems = false
        let menuItem = NSMenuItem(title: String(format: NSLocalizedString("context upload string", comment: ""), node.title),
                                  action: #selector(upload(_:)), keyEquivalent: "")
        menuItem.representedObject = node
        menu.addItem(menuItem)
        menuItem.isEnabled = node.is_upload_allowed
        return menu
    }
    
    @objc func upload(_ item: NSMenuItem) {
        if(uploadSettingsViewController == nil) {
            uploadSettingsViewController = UploadSettingsViewController()
            guard let node = item.representedObject as? Node else { return }
            
            uploadSettingsViewController.showId = node.identifier // showId
            
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            guard let uploadSettingsWindowController = storyboard.instantiateController(withIdentifier: "UploadSettingsWindow") as? NSWindowController else { return }
            if let uploadSettingsWindow = uploadSettingsWindowController.window {
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
            
            uploadSettingsViewController.showNameField.stringValue = node.title
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
}
