//
//  ALESelectionViewController.swift
//  MediaUploader
//
//  Created by global on 11/02/21.
//  Copyright © 2021 Mykola Gerasymenko. All rights reserved.
//

import Cocoa
import OSLog
protocol aleFileUpdatedDelegate: class {
    func didALEFileUpdated(updatedALEFiles:[[String:Any]])
}



class ALESelectionViewController: NSViewController,SourceFileColumnSelectedDelegate,ExactContainColumnSelectedDelegate {
    
    @IBOutlet weak var tblALEList: NSTableView!
    
    var filesArray: [fileInfo?] = []
    var selectedRowIndex:Int = -1
    
    static let kSelectColumn = "Select Column"
    static let kChooseOption = "Choose Option"
    
    
    // reference to a window
    var window: NSWindow?
    
    weak var aleFileDelegate: aleFileUpdatedDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        tblALEList.delegate = self
        tblALEList.dataSource = self
        
        tblALEList.target = self
        tblALEList.sizeToFit()
        tblALEList.selectionHighlightStyle = .none
        tblALEList.backgroundColor = .clear
        
    }
    
    override func viewDidAppear() {
        // After a window is displayed, get the handle to the new window.
        window = self.view.window!
        if window != nil {
            window?.center()
        }
    }
    
    func setStructDataReference(structDataReference:[fileInfo?])
    {
        self.filesArray = structDataReference;
        tblALEList.reloadData()
    }
    
    @IBAction func dismissWIndow(_ sender: Any) {
        
        self.dismiss(self)
    }
    
    //MARK : NSPopMenu Item Delegate
    
    func didSourceFileColumnSelected(selectedRow:Int , selectedSourceName:NSPopUpButton){
        
        selectedRowIndex = selectedRow
        var updatedStruct = filesArray[selectedRow]?.aleFileDetail;
        updatedStruct?.selectedSourceFilesIndex = selectedSourceName.indexOfSelectedItem
        updatedStruct?.selectedSourceFilesName = selectedSourceName.titleOfSelectedItem
        if selectedSourceName.indexOfSelectedItem == 0 {
            updatedStruct?.selectedOptionIndex = 0
            updatedStruct?.charecterFromRight = nil
            updatedStruct?.charecterFromLeft = nil
            
        }
        filesArray[selectedRow]?.aleFileDetail = updatedStruct
        tblALEList.reloadData()
    }
    
    func didExactContainColumnSelected(selectedRow:Int , selectedSourceName:NSPopUpButton)
    {
        selectedRowIndex = selectedRow
        var updatedStruct = filesArray[selectedRowIndex]?.aleFileDetail;
        updatedStruct?.selectedOptionIndex = selectedSourceName.indexOfSelectedItem
        updatedStruct?.optionExactName = selectedSourceName.titleOfSelectedItem
        if selectedSourceName.indexOfSelectedItem == 0 || selectedSourceName.indexOfSelectedItem == 1 {
            
            updatedStruct?.charecterFromRight = nil
            updatedStruct?.charecterFromLeft = nil
            
        }
        var tempStruct = filesArray[selectedRowIndex]
        tempStruct?.aleFileDetail = updatedStruct
        
        filesArray[selectedRowIndex] = tempStruct
        tblALEList.reloadData()
    }
    
    @IBAction func btnOKClicked(_ sender: Any) {
        let(errMsg,result) = self.validateAlEFiles()
        if result {
            // GO TO Upload Files
            var dataArray = [[String: Any]]()
            dataArray = convertToDictionary()
            aleFileDelegate?.didALEFileUpdated(updatedALEFiles: dataArray)
            window?.performClose(nil)
        }else{
            showPopoverMessage(positioningView: tblALEList, msg: errMsg)
        }
    }
    
    
    func validateAlEFiles() -> (errMessage : String , result : Bool) {
        
        let errMsg = ""
        let resultValue = true;
        
        for item in filesArray {
            
            if (item?.aleFileDetail?.SourceFile == true) {
               // print("No thing to check")
                os_log("Nothing to check:", log: .default, type: .debug)
            }else{
                if(item?.aleFileDetail?.selectedSourceFilesIndex  == 0){
                    return (StringConstant().selectColumn,false)
                }else{
                    if(item?.aleFileDetail?.selectedOptionIndex  == 0){
                        return (StringConstant().selectMatchtype,false)
                    }else{
                        if((item?.aleFileDetail?.selectedOptionIndex)!  > 1){
                            
                            if(item?.aleFileDetail?.charecterFromLeft == nil || item?.aleFileDetail?.charecterFromRight == nil ){
                                return (StringConstant().enterNumberToRemove,false)
                            }
                        }
                    }
                }
            }
        }
        return(errMsg,resultValue)
    }
    
    func convertToDictionary() -> [[String : Any]] {
        
        var dictArray = [[String:Any]]()
        dictArray.removeAll()
        for item in filesArray {
            
            var dict: [String: Any] = ["checksum":item?.checksum.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", "filePath":item?.filePath.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", "name":item?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", "type":item?.type.trimmingCharacters(in: .whitespacesAndNewlines) ?? "","filesize":item?.filesize ?? "","uniqueID":item?.uniqueID ?? ""]
            
            var miscDict = [String:Any]()
            
            if let aleFileDetail = item?.aleFileDetail{
                
                if aleFileDetail.SourceFile{
                    // No need to add data in miscDict when SourceFile column is present in ale files
                    miscDict["aleFileNameField"] = StringConstant().sourceFile
                    miscDict["matchType"] = StringConstant().strMatchTypeExact
                    miscDict["truncateCharFromStart"] = 0
                    miscDict["truncateCharFromEnd"] = 0
                }else{
                    miscDict["aleFileNameField"] = aleFileDetail.selectedSourceFilesName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    miscDict["matchType"] = aleFileDetail.optionExactName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    miscDict["truncateCharFromStart"] = aleFileDetail.charecterFromLeft ?? 0
                    miscDict["truncateCharFromEnd"] = aleFileDetail.charecterFromRight ?? 0
                }
            }
            
            if (miscDict.count > 0) {
                dict["miscInfo"] = miscDict
            }else{
                dict["miscInfo"] = ""
            }
            dictArray.append(dict)
        }
        return dictArray
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        
        window?.performClose(nil)
    }
    
    override func keyUp(with event: NSEvent) {
        os_log("key code :: %hu", log: .default, type: .debug,event.keyCode)
        if (event.keyCode > 17 && event.keyCode < 30) {
            tblALEList.reloadData()
        }
    }
    
}


extension ALESelectionViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filesArray.count
    }
    
}
extension ALESelectionViewController: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let aleFilePath = "filePathCell"
        
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
       
        var text: String = ""
        var cellIdentifier: String = ""
        
        guard let item = filesArray[row] else {
            return nil
        }
        
        
        if tableColumn == tableView.tableColumns[0] {
            text = item.dirPath
            cellIdentifier = CellIdentifiers.aleFilePath
            
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = text
                return cell
            }
        } else if tableColumn == tableView.tableColumns[1] {
            var showOption = false
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CustomALECell"), owner: self) as? CustomALECell else { return nil }
            
            if (item.aleFileDetail?.SourceFile == true) {
                cell.bgView.isHidden =  true
                cell.lblPresent.isHidden = false
                cell.lblPresent.stringValue = StringConstant().lblPresent
            }else{
                cell.txtRemoveLeft.delegate = self
                let onlyIntFormatter = TextFiledTypeFormatter()
                cell.txtRemoveLeft.formatter = onlyIntFormatter
                
                let leftTag = (row*1000)+1
                let rightTag = (row*1000)+2
                cell.txtRemoveLeft.tag = leftTag
                
                if let value = item.aleFileDetail?.charecterFromLeft {
                    cell.txtRemoveLeft.stringValue = String(value)
                }else{
                    cell.txtRemoveLeft.stringValue = ""
                }
                
                cell.txtRemoveLeft.formatter = onlyIntFormatter
                cell.lblRemoveLeft.usesSingleLineMode = true
                cell.txtRemoveRight.delegate = self
                cell.txtRemoveRight.tag = rightTag
                if let value = item.aleFileDetail?.charecterFromRight {
                    cell.txtRemoveRight.stringValue = String(value)
                }else{
                    cell.txtRemoveRight.stringValue = ""
                }
                cell.txtRemoveRight.formatter = onlyIntFormatter
                
                cell.lblRemoveRight.usesSingleLineMode = true
                cell.bgView.isHidden =  false
                cell.lblPresent.isHidden = true
                
                if let optionArray = item.aleFileDetail?.otherSourceFiles {
                    cell.sourceFileDelegate = self;
                    cell.otherSourceFilesArray.removeAllItems()
                    cell.otherSourceFilesArray.insertItem(withTitle:ALESelectionViewController.kSelectColumn, at: 0)
                    cell.otherSourceFilesArray.addItems(withTitles: optionArray)
                    if cell.otherSourceFilesArray.numberOfItems > 0 {
                        cell.otherSourceFilesArray.selectItem(at:item.aleFileDetail!.selectedSourceFilesIndex!)
                    }else{
                        cell.otherSourceFilesArray.setTitle(StringConstant().noItem)
                    }
                    cell.otherSourceFilesArray.tag = row
                    if(item.aleFileDetail!.selectedSourceFilesIndex! > 0){
                        showOption = true;
                    }else{
                        showOption = false;
                    }
                }
                
                if showOption {
                    cell.ExactCancelPopUp.isHidden = false
                }else{
                    cell.ExactCancelPopUp.isHidden = true
                }
                
                if let chooseArray =  item.aleFileDetail?.optionExactContains {
                    
                    cell.exactContainDelegate = self
                    cell.ExactCancelPopUp.removeAllItems()
                    cell.ExactCancelPopUp.insertItem(withTitle:ALESelectionViewController.kChooseOption, at: 0)
                    cell.ExactCancelPopUp.addItems(withTitles: chooseArray)
                    if cell.ExactCancelPopUp.numberOfItems > 0 {
                        cell.ExactCancelPopUp.selectItem(at: item.aleFileDetail!.selectedOptionIndex!)
                    }else{
                        cell.ExactCancelPopUp.setTitle(StringConstant().noItem)
                    }
                    cell.ExactCancelPopUp.tag = row
                    
                    if(item.aleFileDetail!.selectedOptionIndex == 2 && showOption){
                        cell.ExactCancelPopUp.isHidden = false
                        cell.lblRemoveLeft.isHidden = false
                        cell.txtRemoveLeft.isHidden = false
                        cell.lblRemoveRight.isHidden = false
                        cell.txtRemoveRight.isHidden = false
                    }else{
                        if showOption {
                            cell.ExactCancelPopUp.isHidden = false
                        }else{
                            cell.ExactCancelPopUp.isHidden = true
                        }
                        cell.lblRemoveLeft.isHidden = true
                        cell.txtRemoveLeft.isHidden = true
                        cell.lblRemoveRight.isHidden = true
                        cell.txtRemoveRight.isHidden = true
                        
                    }
                }
            }
            return cell
        }
        
        return nil
    }
    
    
}
extension ALESelectionViewController: NSTextFieldDelegate {
    
    
    func controlTextDidBeginEditing(_ obj: Notification) {
       
        guard let textField = obj.object as? NSTextField else {
            return
        }
        
        let tagIndex = textField.tag
        selectedRowIndex = tagIndex/1000
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else {
            return
        }
        var tagIndex = textField.tag
        tagIndex = tagIndex % 1000
        
        if(tagIndex == 1){
            var updatedStruct = filesArray[selectedRowIndex]?.aleFileDetail;
            updatedStruct?.charecterFromLeft = Int(textField.intValue)
            filesArray[selectedRowIndex]?.aleFileDetail = updatedStruct
            tblALEList.reloadData()
        }
        else  if(tagIndex == 2){
            var updatedStruct = filesArray[selectedRowIndex]?.aleFileDetail;
            updatedStruct?.charecterFromRight = Int(textField.intValue)
            filesArray[selectedRowIndex]?.aleFileDetail = updatedStruct
            tblALEList.reloadData()
            
        }
    }
    
}
