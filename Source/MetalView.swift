import MetalKit

protocol MetalViewDelegate {
    func computeTexture(_ drawable:CAMetalDrawable,_ ident:Int)
}

class MetalView: MTKView {
    var delegate2:MetalViewDelegate?
    var ident = Int()
    var viewIsDirty:Bool = true

    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.framebufferOnly = false
        self.device = MTLCreateSystemDefaultDevice()
    }
    
    override func draw() {
        super.draw()
        if viewIsDirty {
            if let drawable = currentDrawable {
                delegate2?.computeTexture(drawable,ident)
                viewIsDirty = false
            }
        }
    }
    
    override var isFlipped: Bool { return true }
    override var acceptsFirstResponder: Bool { return true }
}

