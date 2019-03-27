import Cocoa

let populatedCellBackgroundColor = NSColor(red:0.1,  green:0.5,  blue:0.1, alpha: 1)

protocol SLCellDelegate: class {
    func didTapButton(_ sender: NSButton)
}

class SaveLoadCell: NSTableCellView {
    weak var delegate: SLCellDelegate?
    @IBOutlet var legend: NSTextField!
    @IBOutlet var saveButton: NSButton!
    @IBAction func saveTapped(_ sender: NSButton) { delegate?.didTapButton(sender) }
    var isUnused:Bool = true
    
    override func draw(_ rect: CGRect) {
        let context = NSGraphicsContext.current?.cgContext
        context?.setFillColor(isUnused ? NSColor.darkGray.cgColor : populatedCellBackgroundColor.cgColor)
        context?.fill(rect)
        context?.setStrokeColor(NSColor.black.cgColor)
        context?.stroke(rect)
    }
}

//MARK:-

let versionNumber:Int32 = 0x55ac
let numEntries:Int = 50
var loadNextIndex:Int = -1   // first use will bump this to zero

class SaveLoadViewController: NSViewController,NSTableViewDataSource, NSTableViewDelegate,SLCellDelegate {
    @IBOutlet var legend: NSTextField!
    @IBOutlet var scrollView: NSScrollView!
    var tv:NSTableView! = nil
    var dateString:String = ""
    
    func numberOfSections(in tableView: NSTableView) -> Int { return 1 }
    func numberOfRows(in tableView: NSTableView) -> Int { return numEntries }
    
    func didTapButton(_ sender: NSButton) {
        let buttonPosition = sender.convert(CGPoint.zero, to:tv)
        saveAndDismissDialog(tv.row(at:buttonPosition))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tv = scrollView.documentView as? NSTableView
        tv.dataSource = self
        tv.delegate = self
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell:SaveLoadCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SLCell"), owner: self) as! SaveLoadCell
        var str:String = ""
        
        dateString = determineDateString(row)
        if dateString == "**" {
            str = "** unused **"
            cell.backgroundStyle = NSView.BackgroundStyle.dark
            cell.legend.backgroundColor = NSColor.black
        }
        else {
            str = String(format:"%2d    %@",row+1,dateString)
            cell.isUnused = false
        }
        
        cell.delegate = self
        cell.legend.stringValue = str
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        loadAndDismissDialog(tv.selectedRow)
    }
    
    //MARK:-
    
    var fileURL:URL! = nil
    let sz = MemoryLayout<Control>.size

    func determineURL(_ index:Int) {
        let name = String(format:"Store%d.dat",index)
        fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(name)
    }
    
    func saveAndDismissDialog(_ index:Int) {
        let alert = NSAlert()
        alert.messageText = "Save Settings"
        alert.informativeText = "Confirm overwrite of Settings storage"
        alert.addButton(withTitle: "NO")
        alert.addButton(withTitle: "YES")
        alert.beginSheetModal(for: vc.view.window!) {( returnCode: NSApplication.ModalResponse) -> Void in
            if returnCode.rawValue == 1001 {
                do {
                    self.determineURL(index)
                    vc.control.version = versionNumber
                    let data:NSData = NSData(bytes:&vc.control, length:self.sz)
                    try data.write(to: self.fileURL, options: .atomic)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    //MARK:-
    
    func determineDateString(_ index:Int) -> String {
        var dStr = String("**")
        
        determineURL(index)
        
        do {
            let key:Set<URLResourceKey> = [.creationDateKey]
            let value = try fileURL.resourceValues(forKeys: key)
            if let date = value.creationDate { dStr = date.toString() }
        } catch {
            // print(error)
        }
        
        return dStr
    }
    
    //MARK:-
    
    @discardableResult func loadData(_ index:Int) -> Bool {
        determineURL(index)
        
        let data = NSData(contentsOf: fileURL)
        if data == nil { return false } // clicked on empty entry
        
        data?.getBytes(&vc.control, length:sz)
        return true
    }
    
    func loadAndDismissDialog(_ index:Int) {
        if loadData(index) {
            if vc.control.version != versionNumber { vc.reset() }
            self.dismiss(self)
            vc.controlJustLoaded()
        }
    }
    
    //MARK:-
    
    func loadNext() {
        var numTries:Int = 0
        
        while true {
            loadNextIndex += 1
            if loadNextIndex >= numEntries { loadNextIndex = 0 }
            
            determineURL(loadNextIndex)
            let data = NSData(contentsOf: fileURL)
            
            if data != nil {
                data?.getBytes(&vc.control, length:sz)
                //Swift.print("Loaded (base 0): ",loadNextIndex.description)
                return
            }
            
            numTries += 1       // nothing found?
            if numTries >= numEntries-1 { return }
        }
    }
}

//MARK:-

extension Date {
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy hh:mm"
        return dateFormatter.string(from: self)
    }

    func toTimeStampedFilename(_ filename:String, _ extensionString:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddhhmmss"
        let ds = dateFormatter.string(from: self)
        let str:String = String.init(format: "%@_%@.%@",filename,ds,extensionString)
        return str
    }
}

