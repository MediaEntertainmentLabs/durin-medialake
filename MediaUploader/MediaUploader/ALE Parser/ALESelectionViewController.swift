//
//  ALESelectionViewController.swift
//  MediaUploader
//
//  Created by global on 11/02/21.
//  Copyright © 2021 Mykola Gerasymenko. All rights reserved.
//

import Cocoa

class ALESelectionViewController: NSViewController,SourceFileColumnSelectedDelegate,ExactContainColumnSelectedDelegate {
    
    @IBOutlet weak var tblALEList: NSTableView!
    
    var filesArray: [fileInfo?] = []
    var selectedRowIndex:Int = -1
    
    static let kSelectColumn = "Select Column"
    static let kChooseOption = "Choose Option"
    
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
        print("selected Row  during FiLeOption : \(selectedRow)")
        
        selectedRowIndex = selectedRow
        var updatedStruct = filesArray[selectedRow]?.aleFileDetail;
        updatedStruct?.selectedSourceFilesIndex = selectedSourceName.indexOfSelectedItem
        if selectedSourceName.indexOfSelectedItem == 0 {
            updatedStruct?.selectedOptionIndex = 0
            updatedStruct?.charecterFromRight = nil
            updatedStruct?.charecterFromLeft = nil
            
        }
        filesArray[selectedRow]?.aleFileDetail = updatedStruct
        //     print("updated Struct :\(String(describing: filesArray[selectedRow]?.aleFileDetail.map({ $0.selectedSourceFilesIndex })))")
        tblALEList.reloadData()
    }
    
    func didExactContainColumnSelected(selectedRow:Int , selectedSourceName:NSPopUpButton)
    {
        print("selected Row  during Option selection : \(selectedRow)   indexOfOptionItem :\(selectedSourceName.indexOfSelectedItem)")
        selectedRowIndex = selectedRow
        var updatedStruct = filesArray[selectedRowIndex]?.aleFileDetail;
        updatedStruct?.selectedOptionIndex = selectedSourceName.indexOfSelectedItem
        
        var tempStruct = filesArray[selectedRowIndex]
        tempStruct?.aleFileDetail = updatedStruct
        
        filesArray[selectedRowIndex] = tempStruct
        tblALEList.reloadData()
    }
    
    @IBAction func btnOKClicked(_ sender: Any) {
        
        for info in filesArray {
            
            print("updated Info :\(info?.aleFileDetail)")
        }
        
        self.dismiss(self)
    }
}


extension ALESelectionViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
       // print("filesArray.count : \(filesArray.count)")
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
                cell.lblPresent.stringValue = "   Present"
            }else{
                cell.txtRemoveLeft.delegate = self
                if let value = item.aleFileDetail?.charecterFromLeft {
                    cell.txtRemoveLeft.stringValue = String(value)
                }
                cell.lblRemoveLeft.usesSingleLineMode = true
                cell.txtRemoveRight.delegate = self
                
                if let value = item.aleFileDetail?.charecterFromRight {
                    cell.txtRemoveRight.stringValue = String(value)
                }
                cell.lblRemoveRight.usesSingleLineMode = true
                cell.bgView.isHidden =  false
                cell.lblPresent.isHidden = true
                
                if let optionArray = item.aleFileDetail?.otherSourceFiles {
                    cell.sourceFileDelegate = self;
                    cell.otherSourceFilesArray.removeAllItems()
                    cell.otherSourceFilesArray.insertItem(withTitle:ALESelectionViewController.kSelectColumn, at: 0)
                    cell.otherSourceFilesArray.addItems(withTitles: optionArray)
                    if cell.otherSourceFilesArray.numberOfItems > 0 {
                        cell.otherSourceFilesArray.selectItem(at:item.aleFileDetail!.selectedSourceFilesIndex)
                    }else{
                        cell.otherSourceFilesArray.setTitle("No Items")
                    }
                    cell.otherSourceFilesArray.tag = row
                    
                    //  print("item.aleFileDetail!.selectedSourceFilesIndex :\(item.aleFileDetail!.selectedSourceFilesIndex)")
                    
                    if(item.aleFileDetail!.selectedSourceFilesIndex > 0){
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
                //  print("item.aleFileDetail!.selectedOptionIndex :\(item.aleFileDetail!.selectedOptionIndex)")
                
                if let chooseArray =  item.aleFileDetail?.optionExactContains {
                  
                    cell.exactContainDelegate = self
                    cell.ExactCancelPopUp.removeAllItems()
                    cell.ExactCancelPopUp.insertItem(withTitle:ALESelectionViewController.kChooseOption, at: 0)
                    cell.ExactCancelPopUp.addItems(withTitles: chooseArray)
                    if cell.ExactCancelPopUp.numberOfItems > 0 {
                        cell.ExactCancelPopUp.selectItem(at: item.aleFileDetail!.selectedOptionIndex)
                    }else{
                        cell.ExactCancelPopUp.setTitle("No Items")
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
    func controlTextDidEndEditing(_ obj: Notification) {
        
        guard let textField = obj.object as? NSTextField else {
            return
        }
        print("controlTextDidEndEditing :\(textField.stringValue) tag ;\(textField.tag)")
        
        if(textField.tag == 100){
            var updatedStruct = filesArray[selectedRowIndex]?.aleFileDetail;
            updatedStruct?.charecterFromLeft = Int(textField.intValue)
            filesArray[selectedRowIndex]?.aleFileDetail = updatedStruct
            print("updated charecterFromLeft :\(String(describing: filesArray[selectedRowIndex]?.aleFileDetail.map({ $0.charecterFromLeft })))")
            tblALEList.reloadData()
        }
        else  if(textField.tag == 101){
            var updatedStruct = filesArray[selectedRowIndex]?.aleFileDetail;
            updatedStruct?.charecterFromRight = Int(textField.intValue)
            filesArray[selectedRowIndex]?.aleFileDetail = updatedStruct
            print("updated charecterFromRight :\(String(describing: filesArray[selectedRowIndex]?.aleFileDetail.map({ $0.charecterFromRight })))")
            tblALEList.reloadData()
        }
    }
    
}
