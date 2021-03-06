import Cocoa

protocol WidgetDelegate {
    func displayWidgets()
    func hasFocus() -> Bool
}

enum WidgetKind { case integer,float,legend,boolean }

var alterationSpeed:Float = 1

struct WidgetData {
    var kind:WidgetKind = .float
    var legend:String = ""
    var valuePtr:UnsafeMutableRawPointer! = nil
    var delta:Float = 0
    var range = simd_float2()
    var showValue:Bool = false
    
    func alterValue(_ direction:Int) -> Bool {
        var value:Float = valuePtr.load(as:Float.self)
        let oldValue = value
        let amt:Float = delta * alterationSpeed
        
        value += direction > 0 ? amt : -amt
        value = max( min(value, range.y), range.x)

        if value != oldValue {
            valuePtr.storeBytes(of:value, as:Float.self)
            return true
        }
        
        return false
    }
    
    func setValue(_ v:Float) {
        if valuePtr != nil {
            valuePtr.storeBytes(of:v, as:Float.self)
        }
    }
    
    func ensureValueIsInRange() {
        if valuePtr != nil {
            var value:Float = valuePtr.load(as:Float.self)
            value = max( min(value, range.y), range.x)
            valuePtr.storeBytes(of:value, as:Float.self)
        }
    }
    
    func valueString() -> String {
        if kind == .boolean {
            let value:Bool = valuePtr.load(as:Bool.self)
            return value ? "Yes" : "No"
        }

        let value:Float = valuePtr.load(as:Float.self)
        if kind == .integer { return String(format:"%d", Int(value)) }
        return value.debugDescription
    }
    
    func displayString() -> String {
        var s:String = legend
        if showValue { s = s + " : " + valueString() }
        return s
    }

    func valuePercent() -> Int {
        let value:Float = valuePtr.load(as:Float.self)
        return Int((value - range.x) * 100 / (range.y - range.x))
    }
    
    func isAtLimit() -> Bool {
        let value:Float = valuePtr.load(as:Float.self)
        return value == range.x || value == range.y
    }
}

class Widget {
    var delegate:WidgetDelegate?
    var ident:Int = 0
    var data:[WidgetData] = []
    var focus:Int = 0
    var previousFocus:Int = 0

    var shiftKeyDown = Bool()
    var optionKeyDown = Bool()

    init(_ id:Int, _ d:WidgetDelegate) {
        ident = id
        delegate = d
        reset()
    }
    
    func reset() {
        data.removeAll()
        focus = 0
        previousFocus = focus
    }
    
    func gainFocus() {
        focus = previousFocus
        focusChanged()
    }
    
    func loseFocus() {
        if focus >= 0 { previousFocus = focus }
        focus = -1
        focusChanged()
    }
    
    func addEntry(_ nLegend:String,
                  _ nValuePtr:UnsafeMutableRawPointer,
                  _ minValue:Float, _ maxValue:Float, _ nDelta:Float,
                  _ nKind:WidgetKind = .float,
                  _ nShowValue:Bool = false) {
        var w = WidgetData()
        w.legend = nLegend
        w.valuePtr = nValuePtr
        w.range.x = minValue
        w.range.y = maxValue
        w.delta = nDelta
        w.kind = nKind
        w.showValue = nShowValue
        w.ensureValueIsInRange()
        data.append(w)
    }

    func addLegend(_ legend:String = "") {
        var w = WidgetData()
        w.kind = .legend
        w.legend = legend
        data.append(w)
    }
    
    func addBoolean(_ legend:String, _ nValuePtr:UnsafeMutableRawPointer) {
        var w = WidgetData()
        w.legend = legend
        w.valuePtr = nValuePtr
        w.kind = .boolean
        w.showValue = true
        data.append(w)
    }
    
    func focusChanged() {
        delegate?.displayWidgets()
        vc.updateWindowTitle()
    }
    
    func moveFocus(_ direction:Int) {
        if data.count > 1 {
            focus += direction
            if focus < 0 { focus = data.count-1 }
            if focus >= data.count { focus = 0 }
            
            if data[focus].kind == .legend || data[focus].kind == .boolean { moveFocus(direction) }
            
            focusChanged()
        }
    }
    
    func focusDirect(_ index:Int) {
        if index < 0 || index >= data.count { return }
        if data[index].kind == .float {
            focus = index
            focusChanged()
        }
    }

    func updateAlterationSpeed(_ event:NSEvent) {
        let rv = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        shiftKeyDown  = rv & (1 << 17) != 0
        optionKeyDown = rv & (1 << 19) != 0

        alterationSpeed = 1
        if shiftKeyDown && optionKeyDown { alterationSpeed = 50 } else
        if shiftKeyDown { alterationSpeed = 0.1 } else if optionKeyDown { alterationSpeed = 10 }
    }
    
    func keyPress(_ event:NSEvent) -> Bool {
        updateAlterationSpeed(event)
        
        switch Int32(event.keyCode) {
        case LEFT_ARROW :
            if !(delegate?.hasFocus())! { return false }
            
            if data[focus].alterValue(-1) {
                if ident == 0 {
                    vc.flagViewToRecalcFractal()
                    if data[focus].showValue { delegate?.displayWidgets() }
                }
                return true
            }
        case RIGHT_ARROW :
            if !(delegate?.hasFocus())! { return false }

            if data[focus].alterValue(+1) {
                if ident == 0 {
                    vc.flagViewToRecalcFractal()
                    if data[focus].showValue { delegate?.displayWidgets() }
                }
                return true
            }
        case DOWN_ARROW :   moveFocus(+1); return true
        case UP_ARROW :     moveFocus(-1); return true
        default : break
        }
        
        return false
    }
    
    func focusString() -> String {
        if focus < 0 { return "" }
        return data[focus].displayString()
    }
    
    func addinstructionEntries(_ str:NSMutableAttributedString) {
        for i in 0 ..< data.count {
            switch data[i].kind {
            case .integer, .float :
                str.colored(data[i].displayString(), i == focus ? .red : .white)
            case .legend :
                str.normal(data[i].legend != "" ? data[i].legend : "-------------")
            case .boolean :
                str.normal(data[i].displayString())
            }
        }
    }
}
