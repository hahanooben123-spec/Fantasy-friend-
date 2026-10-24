import SwiftUI

/// Native, rounded toy graphics shared by navigation and children's tools.
struct StorybookIcon:View {
    let symbol:String
    var body:some View {
        Group {
            switch symbol {
            case "paintbrush.fill","paintbrush.pointed.fill","paintpalette.fill":ToyGlyph(kind:.brush)
            case "heart.fill":ToyGlyph(kind:.heart)
            case "music.note","music.note.list":ToyGlyph(kind:.music)
            case "plus","plus.circle.fill":CreatorLineIcon(mark:.add)
            case "checkmark":CreatorLineIcon(mark:.done)
            case "xmark":CreatorLineIcon(mark:.close)
            case "arrow.uturn.backward","arrow.counterclockwise","arrow.clockwise":CreatorLineIcon(mark:.undo)
            case "shuffle":CreatorLineIcon(mark:.shuffle)
            case "trash.fill":CreatorLineIcon(mark:.trash)
            case "chevron.left","arrow.left","arrow.right","play.fill","pause.fill","ellipsis","record.circle.fill","house.fill","tray.fill","tray.and.arrow.down.fill":
                Canvas {c,size in
                    c.scaleBy(x:size.width/48,y:size.height/48)
                    let ink=StorybookStyle.teal
                    var p=Path()
                    switch symbol {
                    case "chevron.left","arrow.left":
                        p.move(to:CGPoint(x:29,y:10));p.addLine(to:CGPoint(x:15,y:24));p.addLine(to:CGPoint(x:29,y:38))
                    case "arrow.right":
                        p.move(to:CGPoint(x:19,y:10));p.addLine(to:CGPoint(x:33,y:24));p.addLine(to:CGPoint(x:19,y:38))
                    case "play.fill":
                        p.move(to:CGPoint(x:15,y:9));p.addQuadCurve(to:CGPoint(x:38,y:24),control:CGPoint(x:43,y:20))
                        p.addQuadCurve(to:CGPoint(x:15,y:39),control:CGPoint(x:28,y:35));p.closeSubpath()
                        ToyFinish.paint(c,path:p,color:StorybookStyle.mint,edge:2);return
                    case "pause.fill":
                        for x in [CGFloat(11),CGFloat(29)] {
                            ToyFinish.paint(c,path:Path(roundedRect:CGRect(x:x,y:9,width:9,height:30),cornerRadius:4),color:ink,edge:1)
                        };return
                    case "record.circle.fill":
                        ToyFinish.paint(c,path:Path(ellipseIn:CGRect(x:8,y:8,width:32,height:32)),color:StorybookStyle.coral,edge:2);return
                    case "ellipsis":
                        for x in [CGFloat(8),CGFloat(21),CGFloat(34)] {
                            c.fill(Path(ellipseIn:CGRect(x:x,y:20,width:7,height:8)),with:.color(ink))
                        };return
                    default:
                        let box=Path(roundedRect:CGRect(x:7,y:23,width:34,height:19),cornerRadius:6)
                        ToyFinish.paint(c,path:box,color:StorybookStyle.honey,edge:2)
                        p.move(to:CGPoint(x:6,y:24));p.addLine(to:CGPoint(x:24,y:8));p.addLine(to:CGPoint(x:42,y:24))
                        if symbol == "house.fill" {
                            c.fill(Path(roundedRect:CGRect(x:20,y:29,width:9,height:13),cornerRadius:4),with:.color(ink))
                        }
                    }
                    c.stroke(p,with:.color(ink),style:StrokeStyle(lineWidth:6,lineCap:.round,lineJoin:.round))
                }
            default:Image(systemName:symbol).font(.system(size:23,weight:.heavy)).foregroundColor(StorybookStyle.teal)
            }
        }.accessibilityHidden(true)
    }
}
