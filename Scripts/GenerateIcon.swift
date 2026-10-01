import AppKit
let root=URL(fileURLWithPath:CommandLine.arguments[1])
let output=root.appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
func render(_ dimension:Int, mac:Bool)->Data {
 let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:dimension,pixelsHigh:dimension,bitsPerSample:8,samplesPerPixel:mac ? 4 : 3,hasAlpha:mac,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
 let transform=NSAffineTransform();transform.scale(by:CGFloat(dimension)/1024);transform.concat()
 NSColor(calibratedRed:0.19,green:0.34,blue:0.52,alpha:1).setFill()
 if mac { NSBezierPath(roundedRect:NSRect(x:40,y:40,width:944,height:944),xRadius:200,yRadius:200).fill() }
 else { NSBezierPath(rect:NSRect(x:0,y:0,width:1024,height:1024)).fill() }
 NSColor.white.setFill();NSColor.white.setStroke();NSBezierPath.defaultLineWidth=48
 let arch=NSBezierPath();arch.move(to:NSPoint(x:260,y:490));arch.curve(to:NSPoint(x:764,y:490),controlPoint1:NSPoint(x:260,y:820),controlPoint2:NSPoint(x:764,y:820));arch.stroke()
 for x in [240.0,720.0] { NSBezierPath(roundedRect:NSRect(x:x,y:330,width:90,height:200),xRadius:35,yRadius:35).fill() }
 let tail=NSBezierPath();tail.move(to:NSPoint(x:764,y:360));tail.curve(to:NSPoint(x:530,y:240),controlPoint1:NSPoint(x:764,y:240),controlPoint2:NSPoint(x:630,y:240));tail.stroke()
 NSBezierPath(roundedRect:NSRect(x:460,y:200,width:150,height:70),xRadius:35,yRadius:35).fill()
 NSGraphicsContext.restoreGraphicsState()
 return bitmap.representation(using:.png,properties:[:])!
}
var entries:[[String:String]]=[]
for size in [16,32,128,256,512] { for scale in [1,2] { let name="icon-\(size)-\(scale).png";try render(size*scale,mac:true).write(to:output.appendingPathComponent(name));entries.append(["idiom":"mac","size":"\(size)x\(size)","scale":"\(scale)x","filename":name]) } }
try render(1024,mac:false).write(to:output.appendingPathComponent("icon-ios.png"));entries.append(["idiom":"universal","platform":"ios","size":"1024x1024","filename":"icon-ios.png"])
try JSONSerialization.data(withJSONObject:["images":entries,"info":["version":1,"author":"xcode"]],options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("Contents.json"))
