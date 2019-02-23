import Cocoa

class HelpViewController: NSViewController {

    @IBOutlet var scrollView: NSScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.resignFirstResponder()
        let textView = scrollView.documentView as? NSTextView

        do {
            textView!.string = try String(contentsOfFile: Bundle.main.path(forResource: "help.txt", ofType: "")!)
        } catch {
            fatalError("\n\nload help text failed\n\n")
        }
    }
}
