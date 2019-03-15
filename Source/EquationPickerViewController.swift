import Cocoa

class EquationPickerViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet var scrollView: NSScrollView!
    var tv:NSTableView! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        tv = scrollView.documentView as? NSTableView
        tv.dataSource = self
        tv.delegate = self
        
        let iset:IndexSet = [ Int(vc.control.equation) ]
        tv.selectRowIndexes(iset, byExtendingSelection:false)
    }
    
    func numberOfSections(in tableView: NSTableView) -> Int { return 1 }
    func numberOfRows(in tableView: NSTableView) -> Int { return vc.titleString.count }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat { return CGFloat(20) }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let str = Int(row + 1).description + ": " + vc.titleString[row]
        let view = NSTextField(string:str)
        view.isEditable = false
        view.isBordered = false
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        vc.control.equation = Int32(row)
        vc.controlJustLoaded()
        return true
    }
}
