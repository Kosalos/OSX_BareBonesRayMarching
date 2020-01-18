import Cocoa

class InstructionsG: NSView {
    let YTOP = 5
    let YHOP = 18
    let YS = 10

    override func draw(_ rect: NSRect) {
        let context = NSGraphicsContext.current?.cgContext
        context?.setFillColor(NSColor.clear.cgColor)
        context?.fill(rect)
        
        var y = YTOP
        var r:NSRect = NSMakeRect(0,0,40,CGFloat(YS))

        for i in 0 ..< vc.widget.data.count {
            if vc.widget.data[i].kind == .float {
                r = NSMakeRect(3,CGFloat(y),36,CGFloat(YS))
                context?.setStrokeColor(i == vc.widget.focus ? NSColor.red.cgColor : NSColor.white.cgColor)
                
                // green when at limits
                let p = vc.widget.data[i].valuePercent()
                if(p == 0 || p == 100) { context?.setStrokeColor(NSColor.green.cgColor) }
                
                context?.setLineWidth(1.0)
                context?.stroke(r)
                
                let xp = CGFloat(3 + p * 36 / 100)

                r = NSMakeRect(xp,CGFloat(y),2,CGFloat(YS))
                context?.setLineWidth(2.0)
                context?.stroke(r)
            }
            
            y += YHOP
        }
    }
    
    func refresh() {
        setNeedsDisplay(NSMakeRect(-30,0,140,800))
    }

    override func mouseDown(with event: NSEvent) {
        var pt:NSPoint = event.locationInWindow
        pt.y = vc.view.frame.height - pt.y
        let index = Int(pt.y - 5)/18
        
        vc.widget.focusDirect(index)
    }
    
    override var isFlipped: Bool { return true }
}
