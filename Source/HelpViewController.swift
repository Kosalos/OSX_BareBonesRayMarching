import Cocoa

var helpIndex:Int = 0
let helpFilename:[String] = [ "help.txt","help2.txt","help3.txt" ]
var isHelpVisible:Bool = false

class HelpViewController: NSViewController {
    
    @IBOutlet var scrollView: NSScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.resignFirstResponder()
        let textView = scrollView.documentView as? NSTextView
        
        do {
            textView!.string = try String(contentsOfFile: Bundle.main.path(forResource: helpFilename[helpIndex], ofType: "")!)
            isHelpVisible = true
        } catch {
            fatalError("\n\nload help text failed\n\n")
        }
    }
    
    override func viewDidDisappear() {
        isHelpVisible = false
    }
    
    // so user can issue commands while viewing the help page
    override func keyDown(with event: NSEvent) {
        let vlist = [ vc,win3D,videoRecorderWindow ]
        vlist[helpIndex]?.keyDown(with: event)
    }
        
}
