import Cocoa
import MetalKit

var vcLight:WinLightViewController! = nil

class WinLightViewController: NSViewController, NSWindowDelegate, WidgetDelegate {
    var widget:Widget! = nil
    var lightIndex:Float = 1
    
    @IBOutlet var instructions: NSTextField!
    @IBOutlet var instructionsG: InstructionsG!
    
    @IBAction func resetButtonPressed(_ sender: NSButton) {
        flightReset()
        vc.flagViewToRecalcFractal()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        widget = Widget(2,self)
        instructionsG.parent = widget
    }
    
    override func viewDidAppear() {
        updateLayoutOfChildViews()
        defineWidgets()
        showHelpDialog()
    }
    
    //MARK: -
    
    func updateLayoutOfChildViews() {
        let widgetPanelHeight:Int = 500
        instructionsG.frame = CGRect(x:5, y:5, width:75, height:widgetPanelHeight)
        instructionsG.bringToFront()
        instructionsG.refresh()
        
        instructions.frame = CGRect(x:50, y:5, width:500, height:widgetPanelHeight)
        instructions.textColor = .white
        instructions.backgroundColor = .black
        instructions.bringToFront()
    }
    
    //MARK: -
    
    func defineWidgets() {
        let i = Int32(lightIndex)-1  // base 0
        
        widget.reset()
        widget.addEntry("Light#",&lightIndex,1,3,1,.integer,true)
        widget.addLegend(" ")
        widget.addEntry("Bright",lightBright(i),0,10,0.2)
        widget.addEntry("Spread",lightPower(i),0.01,100,0.2)
        widget.addLegend(" ")
        widget.addEntry("X Position",lightX(i),-20,20,0.2)
        widget.addEntry("Y",lightY(i),-20,20,0.2)
        widget.addEntry("Z",lightZ(i),-20,20,0.2)
        widget.addLegend(" ")
        widget.addEntry("R Color",lightR(i),0,1,0.1)
        widget.addEntry("G",lightG(i),0,1,0.1)
        widget.addEntry("B",lightB(i),0,1,0.1)
        
        displayWidgets()
    }
    
    func displayWidgets() {
        let str = NSMutableAttributedString()
        widget.addinstructionEntries(str)
        instructions.attributedStringValue = str
    }
    
    func hasFocus() -> Bool {
        return view.window!.isKeyWindow
    }
    
    //MARK: -
    
    func showHelpDialog() {
        if !isHelpVisible {
            helpIndex = 3
            presentPopover("HelpVC")
        }
    }
    
    func presentPopover(_ name:String) {
        let mvc = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let vc = mvc.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(name)) as! NSViewController
        self.present(vc, asPopoverRelativeTo: view.bounds, of: view, preferredEdge: .minX, behavior: .transient)
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.charactersIgnoringModifiers!.uppercased() {
        case "L" :
            vc.view.window!.makeKeyAndOrderFront(nil)
            return
        default : break
        }
        
        switch Int32(event.keyCode) {
        case PAGE_UP :
            showHelpDialog()
            return
        default : break
        }
        
        if widget.keyPress(event) {
            if widget.focus == 0 { defineWidgets() }
            displayWidgets()
            instructionsG.refresh()
            
            if widget.focus != 0 && event.keyCode != UP_ARROW && event.keyCode != DOWN_ARROW {
                vc.setShaderToFastRender()
                vc.flagViewToRecalcFractal()
            }
        }
        else {
            vc.keyDown(with:event)
        }
    }
    
    override func keyUp(with event: NSEvent) {
        vc.keyUp(with:event)
    }
}

class BaseNSView2: NSView {
    override var isFlipped: Bool { return true }
    override var acceptsFirstResponder: Bool { return true }
    
    override func draw(_ rect: NSRect) {
        NSColor(red:0, green:0, blue:0, alpha:1).set()
        NSBezierPath(rect:bounds).fill()
    }
}

