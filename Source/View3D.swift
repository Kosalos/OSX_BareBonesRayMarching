import Cocoa
import Metal

let NUMNODE:Int = Int(SIZE3D * SIZE3D)

var height:Float = 10
var vBuffer: MTLBuffer! = nil
var iBufferT: MTLBuffer! = nil

class View3D {
    var vData = Array(repeating:TVertex(), count:NUMNODE)
    var iDataT = Array<UInt16>()
    let vSize:Int = MemoryLayout<TVertex>.stride * NUMNODE
    
    func initializeBuffers() {
        let fSize = Float(SIZE3D)

        var index:Int = 0
        for z in 0 ..< SIZE3D {
            for x in 0 ..< SIZE3D {
                var v = TVertex()
                v.position.x = Float(x - SIZE3D/2)
                v.position.y = 0
                v.position.z = Float(z - SIZE3D/2)
                
                v.texture.x = Float(x) / fSize
                v.texture.y = Float(1) - Float(z) / fSize
                v.color = float4( Float(z) / fSize, Float(x) / fSize,1,1)
                
                vData[index] = v
                index += 1
            }
        }
        
        // ----------------------------------------
        // triangleStrip terrain indices
        
        let sz = Int(SIZE3D)
        var base:Int = 0
        
        func addEntry(_ v:Int) { iDataT.append(UInt16(v)) }
        
        for y in 0 ..< sz-1 {
            for x in 0 ..< sz {
                addEntry(base+x+sz)
                addEntry(base+x)
            }
            
            if y < sz-1 {
                addEntry(base+sz-1) // 2 indices = degenerate triangle to seperate this strip from the next
                base += sz
                addEntry(base+sz)
            }
        }

        vBuffer  = device.makeBuffer(bytes: vData,  length: vSize, options: MTLResourceOptions())
        iBufferT = device.makeBuffer(bytes: iDataT, length: iDataT.count * MemoryLayout<UInt16>.stride, options: MTLResourceOptions())
    }
    
    func render(_ renderEncoder:MTLRenderCommandEncoder) {
        if vData.count > 0 {
            renderEncoder.setVertexBuffer(vBuffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPrimitives(type: .triangleStrip,  indexCount: iDataT.count, indexType: MTLIndexType.uint16, indexBuffer: iBufferT!, indexBufferOffset:0)
        }
    }
}

