import Cocoa
import MetalKit

var vcLight:WinLightViewController! = nil

class WinLightViewController: NSViewController, NSWindowDelegate, WidgetDelegate {
    var widget:Widget! = nil
    var lightIndex:Float = 1
    
    @IBOutlet var instructions: NSTextField!
    @IBOutlet var instructionsG: InstructionsG!
    
    @IBAction func resetButtonPressed(_ sender: NSButton) {
        resetAllLights()
        vc.control.OrbitStrength = 0
        vc.control.Cycles = 0
        vc.control.orbitStyle = 0
        vc.control.fog = 0

        displayWidgets()
        vc.flagViewToRecalcFractal()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vcLight = self
        widget = Widget(2,self)
        instructionsG.initialize(widget)
    }
    
    override func viewDidAppear() {
        view.window?.delegate = self
        
        updateLayoutOfChildViews()
        defineWidgets()
        showHelpDialog()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        vc.setWindowFocusToMainWindow(false)
    }
    
    //MARK: -
    
    func updateLayoutOfChildViews() {
        let widgetPanelHeight:Int = 700
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
        widget.addEntry("Spread",lightPower(i),0.001,100,0.1)
        widget.addLegend(" ")
        widget.addEntry("X Position",lightX(i),-20,20,0.2)
        widget.addEntry("Y",lightY(i),-20,20,0.2)
        widget.addEntry("Z",lightZ(i),-10,20,0.2)
        widget.addLegend(" ")
        widget.addEntry("R Color",lightR(i),0,1,0.1)
        widget.addEntry("G",lightG(i),0,1,0.1)
        widget.addEntry("B",lightB(i),0,1,0.1)
        
        // ----------------------------
        widget.addLegend("")
        widget.addEntry("Fog Amount",&vc.control.fog,0,12,0.1)
        widget.addEntry("R",&vc.control.fogR,0,1,0.1)
        widget.addEntry("G",&vc.control.fogG,0,1,0.1)
        widget.addEntry("B",&vc.control.fogB,0,1,0.1)
        
        // ----------------------------
        widget.addLegend("")
        widget.addLegend("Orbit Trap --")
        widget.addEntry("O Strength",&vc.control.OrbitStrength,0,1,0.1)
        widget.addEntry("Cycles",&vc.control.Cycles,0,100,0.5)
        widget.addEntry("X Weight",&vc.control.xWeight,-5,5,0.1)
        widget.addEntry("Y",&vc.control.yWeight,-5,5,0.1)
        widget.addEntry("Z",&vc.control.zWeight,-5,5,0.1)
        widget.addEntry("R",&vc.control.rWeight,-5,5,0.1)
        widget.addEntry("X Color",&vc.control.xIndex,0,255,10)
        widget.addEntry("Y",&vc.control.yIndex,0,255,10)
        widget.addEntry("Z",&vc.control.zIndex,0,255,10)
        widget.addEntry("R",&vc.control.rIndex,0,255,10)
        widget.addEntry("Fixed Trap",&vc.control.orbitStyle,0,2,1,.integer,true)
        widget.addEntry("X",&vc.control.otFixedX,-10,10,0.1)
        widget.addEntry("Y",&vc.control.otFixedY,-10,10,0.1)
        widget.addEntry("Z",&vc.control.otFixedZ,-10,10,0.1)
        
        displayWidgets()
    }
    
    func displayWidgets() {
        let str = NSMutableAttributedString()
        widget.addinstructionEntries(str)
        instructions.attributedStringValue = str
        instructionsG.refresh()
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
            vc.toggleWindowFocus()
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

