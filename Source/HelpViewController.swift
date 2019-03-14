import Cocoa

var helpIndex:Int = 0
let helpFilename:[String] = [ "help.txt","help2.txt" ]

class HelpViewController: NSViewController {
    
    @IBOutlet var scrollView: NSScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.resignFirstResponder()
        let textView = scrollView.documentView as? NSTextView
        
        do {
            textView!.string = try String(contentsOfFile: Bundle.main.path(forResource: helpFilename[helpIndex], ofType: "")!)
        } catch {
            fatalError("\n\nload help text failed\n\n")
        }
    }
}
