import Cocoa

class InstructionsG: NSView {
    var parent:Widget! = nil
    let YTOP = 5
    let YHOP = 18
    let YS = 10

    func initialize(_ parentPtr:Widget) { parent = parentPtr }
    
    override func draw(_ rect: NSRect) {
        if parent == nil { print("Need to initialze instructionsG");  exit(0) }
        let context = NSGraphicsContext.current?.cgContext
        context?.setFillColor(NSColor.clear.cgColor)
        context?.fill(rect)
        
        var y = YTOP
        var r:NSRect = NSMakeRect(0,0,40,CGFloat(YS))

        for i in 0 ..< parent.data.count {
            if parent.data[i].kind == .float {
                r = NSMakeRect(3,CGFloat(y),36,CGFloat(YS))
                context?.setStrokeColor(i == parent.focus ? NSColor.red.cgColor : NSColor.white.cgColor)
                
                // green when at limits
                if parent.data[i].isAtLimit() { context?.setStrokeColor(NSColor.green.cgColor) }
                
                context?.setLineWidth(1.0)
                context?.stroke(r)
                
                let p = parent.data[i].valuePercent()
                let xp = CGFloat(3 + p * 36 / 100)

                r = NSMakeRect(xp,CGFloat(y),2,CGFloat(YS))
                context?.setLineWidth(2.0)
                context?.stroke(r)
            }
            
            y += YHOP
        }
    }
    
    func refresh() {
        setNeedsDisplay(NSMakeRect(-30,0,140,frame.height))
    }

    override func mouseDown(with event: NSEvent) {
        var pt:NSPoint = event.locationInWindow
        pt.y = (parent.delegate as! NSViewController).view.frame.height - pt.y
        let index = Int(pt.y - 5)/18
        
        parent.focusDirect(index)
    }
    
    override var isFlipped: Bool { return true }
}
