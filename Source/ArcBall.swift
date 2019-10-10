import Cocoa

var arcBall = ArcBall()

class ArcBall {
    var transformMatrix = float4x4()
    var startPosition = float3x3()
    var endPosition = float3x3()
    var startVertex = SIMD3<Float>()
    var endVertex = SIMD3<Float>()
    var adjustWidth = Float()
    var adjustHeight = Float()
    var width = Float()
    var height = Float()
    
    func initialize(_ newWidth:Float, _ newHeight:Float) {
        width = newWidth
        height = newHeight
        transformMatrix = float4x4(diagonal:[1,1,1,1])
        startPosition = matrix3fSetIdentity()
        endPosition = matrix3fSetIdentity()
        transformMatrix = copyMatrixToQuaternion(transformMatrix,endPosition)
        adjustWidth  = 1 / ((newWidth  - 1) * 0.5)
        adjustHeight = 1 / ((newHeight - 1) * 0.5)
    }
    
    func quaternionToMatrix(_ q1:SIMD4<Float>) -> float3x3 {
        let n:Float = (q1.x * q1.x) + (q1.y * q1.y) + (q1.z * q1.z) + (q1.w * q1.w)
        let s:Float = (n > 0) ? (2 / n) : 0
        let xs:Float = q1.x * s
        let ys:Float = q1.y * s
        let zs:Float = q1.z * s
        let wx:Float = q1.w * xs
        let wy:Float = q1.w * ys
        let wz:Float = q1.w * zs
        let xx:Float = q1.x * xs
        let xy:Float = q1.x * ys
        let xz:Float = q1.x * zs
        let yy:Float = q1.y * ys
        let yz:Float = q1.y * zs
        let zz:Float = q1.z * ys
        
        let c0 = SIMD3<Float>(1 - (yy + zz),xy + wz,xz - wy)
        let c1 = SIMD3<Float>(xy - wz,1 - (xx + zz),yz + wx)
        let c2 = SIMD3<Float>(xz + wy,yz - wx,1 - (xx + yy))
        
        var ans = float3x3()
        ans.columns = (c0,c1,c2)
        return ans
    }
    
    func copyMatrixToQuaternion(_ oldQuat:float4x4,_ m1:float3x3) -> float4x4 {
        var ans = oldQuat
        for i in 0 ..< 3 {
            ans[i].x = m1[i].x;
            ans[i].y = m1[i].y;
            ans[i].z = m1[i].z;
        }
        
        return ans
    }
    
    func mapToSphere(_ cgPt:CGPoint) -> SIMD3<Float> {
        var tempPt = SIMD2<Float>(Float(cgPt.x),Float(cgPt.y))
        tempPt.x  = (tempPt.x * adjustWidth ) - 1
        tempPt.y  = -((tempPt.y * adjustHeight) - 1)
        
        let length:Float = (tempPt.x * tempPt.x) + (tempPt.y * tempPt.y)
        
        var ans = SIMD3<Float>()
        
        if(length > 1) {
            let norm:Float = 1 / sqrtf(length)
            ans.x = tempPt.x * norm
            ans.y = tempPt.y * norm
            ans.x = 0
        }
        else {   // Else it's on the inside
            ans.x = tempPt.x
            ans.y = tempPt.y
            ans.z = sqrtf(1 - length)
        }
        
        return ans
    }
    
    func vector3fCross(_ v1 :SIMD3<Float>, _ v2:SIMD3<Float>) -> SIMD3<Float> {
        var ans = SIMD3<Float>()
        ans.x = (v1.y * v2.z) - (v1.z * v2.y)
        ans.y = (v1.z * v2.x) - (v1.x * v2.z)
        ans.z = (v1.x * v2.y) - (v1.y * v2.x)
        return ans
    }
    
    func matrix3fSetIdentity()  -> float3x3 { return float3x3.init(diagonal: SIMD3<Float>(1,1,1)) }
    func vector3fDot(_ v1 :SIMD3<Float>, _ v2:SIMD3<Float>) -> Float {  return Float(v1.x*v2.x + v1.y*v2.y + v1.z*v2.z) }
    func vector3fLengthSquared(_ v:SIMD3<Float>) -> Float { return Float(v.x*v.x + v.y*v.y + v.z*v.z) }
    func vector3fLength(_ v:SIMD3<Float>) -> Float { return sqrtf( vector3fLengthSquared(v)) }
    
    func mouseDown(_ cgPt:CGPoint) {
        startVertex = mapToSphere(cgPt)
        startPosition = endPosition
        //Swift.print("ArcBall down = ",cgPt.x,cgPt.y)
    }
    
    let Epsilon = Float(0.00001)
    
    func mouseMove(_ cgPt:CGPoint) {
        endVertex = mapToSphere(cgPt)
        
        //Swift.print("ArcBall move = ",cgPt.x,cgPt.y)
        
        let Perp = vector3fCross(startVertex,endVertex)
        
        var newRot = SIMD4<Float>()
        
        if vector3fLength(Perp) > Epsilon {
            newRot.x = Perp.x
            newRot.y = Perp.y
            newRot.z = Perp.z
            newRot.w = vector3fDot(startVertex,endVertex)
        }
        
        endPosition = quaternionToMatrix(newRot) * startPosition
        transformMatrix = copyMatrixToQuaternion(transformMatrix,endPosition)
    }
}

