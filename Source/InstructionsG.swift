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
        //let path = CGMutablePath()

        for i in 0 ..< vc.widget.data.count {
            if vc.widget.data[i].kind == .float {
                r = NSMakeRect(3,CGFloat(y),36,CGFloat(YS))
                context?.setStrokeColor(i == vc.widget.focus ? NSColor.red.cgColor : NSColor.white.cgColor)
                context?.setLineWidth(1.0)
                context?.stroke(r)
                
                let xp = CGFloat(3 + vc.widget.data[i].valuePercent() * 36 / 100)

                r = NSMakeRect(xp,CGFloat(y),2,CGFloat(YS))
                context?.setLineWidth(2.0)
                context?.stroke(r)
            }
            
            y += YHOP
        }
    }
    
    func refresh() {
        setNeedsDisplay(NSMakeRect(-30,0,140,700))
    }

    override var isFlipped: Bool { return true }
}
