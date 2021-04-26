//
//  UploadWindowViewController+Delegate.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

extension UploadWindowViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return uploadTasks.count
    }
}

final class CustomTableHeaderCell : NSTableHeaderCell {
    
    override init(textCell: String) {
        super.init(textCell: textCell)
        self.font = NSFont.boldSystemFont(ofSize: 11) // Or set NSFont to your choice
        self.textColor = NSColor.controlColor
        self.backgroundColor = NSColor.green
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        // skip super.drawWithFrame(), since that is what draws borders
        //NSColor.secondarySelectedControlColor.setFill()
        //cellFrame.fill()
        super.draw(withFrame: cellFrame, in: controlView)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        let titleRect = self.titleRect(forBounds: cellFrame)
        self.attributedStringValue.draw(in: titleRect)
    }
}



extension UploadWindowViewController: NSTableViewDelegate {
    
    //    enum CellIdentifiers {
    //        static let Num = "NumCellID"
    //        static let ShowName = "ShowNameCellID"
    //        static let SrcPath = "SrcPathCellID"
    //        static let DstPath = "DstPathCellID"
    //        static let Date = "DateCellID"
    //        static let Size = "SizeCellID"
    //        static let ProgressBar = "ProgressBarCellID"
    //    }
    
    enum ColumnIdentifiers {
        static let Num = "NumColumn"
        static let DateModified = "DateModifiedColumn"
        static let ShowName = "ShowNameColumn"
        static let SrcPath = "SrcPathColumn"
        static let DstPath = "DstPathColumn"
        static let Date = "DstPathColumn"
        static let Size = "SizeColumn"
        static let ProgressBar = "ProgressBarColumn"
        static let StatusColumn = "StatusColumn"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text: String = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        
        if(uploadTasks.count == 0) {
            return nil
        }
        
        let item = uploadTasks[row]
        
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: ColumnIdentifiers.Num) {
            text = "\(row+1)"
        }else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: ColumnIdentifiers.DateModified) {
            text = stringFromDate(date: item.dateModified)
        }
        else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: ColumnIdentifiers.ShowName) {
            
            text = item.showName
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: ColumnIdentifiers.SrcPath) {
            text = item.srcPath
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: ColumnIdentifiers.DstPath) {
            text = item.dstPath
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: ColumnIdentifiers.StatusColumn) {
            text = item.completionStatusString
        }
        
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: ColumnIdentifiers.ProgressBar)  {
            if let cell: CustomTableCellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? CustomTableCellView {
                cell.progress.doubleValue = item.uploadProgress
                cell.progressCompletionStatus.isHidden = true
                
                if equal(item.uploadProgress, 100.0) {
                    cell.progress.controlTint = .graphiteControlTint
                    //cell.subviews.remove(at:0)
                    cell.progress.isHidden = true
                } else {
                    cell.progress.controlTint = .blueControlTint
                    cell.progress.isHidden = false
                }
                return cell
            }
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: ColumnIdentifiers.StatusColumn) {
            if let cell : UploadStatusTableCellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? UploadStatusTableCellView {
                cell.pauseResumeDelegate = self
                cell.lblStatus?.stringValue = item.completionStatusString
                cell.btnPauseResume.tag = row
                
                if item.completionStatusString == "Completed" {
                    cell.imgStatus?.isHidden = false
                    cell.btnPauseResume?.isHidden = true;
                    cell.imgStatus?.image = NSImage(named: NSImage.statusAvailableName)
                } else if item.completionStatusString == "Failed" {
                    cell.imgStatus?.isHidden = false
                    cell.btnPauseResume?.isHidden = true;
                    cell.imgStatus?.image = NSImage(named: NSImage.statusUnavailableName)
                } else {
                    cell.imgStatus?.isHidden = true
                    cell.btnPauseResume?.isHidden = false;
                    
                    switch item.pauseResumeStatus {
                    case .none:
                        cell.btnPauseResume?.isHidden = true;
                    case .pause:
                        cell.btnPauseResume?.isHidden = false;
                        cell.btnPauseResume?.image = NSImage(named:"resume")
                        cell.btnPauseResume?.toolTip = "Resume"
                    case .resume:
                        cell.btnPauseResume?.isHidden = false;
                        cell.btnPauseResume?.image = NSImage(named:"pause")
                        cell.btnPauseResume?.toolTip = "Pause"
                    }
                }
            
                return cell
            }
        }
        else if let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        
        return nil
    }
}
