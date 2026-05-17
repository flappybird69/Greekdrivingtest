import SwiftUI

// MARK: - Custom Shapes

struct OctagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let d = s * 0.293
        let ox = (rect.width - s) / 2
        let oy = (rect.height - s) / 2
        var p = Path()
        p.move(to:    CGPoint(x: ox + d,     y: oy))
        p.addLine(to: CGPoint(x: ox + s - d, y: oy))
        p.addLine(to: CGPoint(x: ox + s,     y: oy + d))
        p.addLine(to: CGPoint(x: ox + s,     y: oy + s - d))
        p.addLine(to: CGPoint(x: ox + s - d, y: oy + s))
        p.addLine(to: CGPoint(x: ox + d,     y: oy + s))
        p.addLine(to: CGPoint(x: ox,         y: oy + s - d))
        p.addLine(to: CGPoint(x: ox,         y: oy + d))
        p.closeSubpath()
        return p
    }
}

struct TriangleShape: Shape {
    var inverted = false
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if inverted {
            p.move(to:    CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        } else {
            p.move(to:    CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        p.closeSubpath()
        return p
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Main Traffic Sign View

struct TrafficSignView: View {
    let signType: TrafficSignType
    var size: CGFloat = 120

    var body: some View {
        Group {
            switch signType {
            case .stop:                stopSign
            case .giveWay:             giveWaySign
            case .priorityRoad:        priorityRoadSign
            case .endPriorityRoad:     endPriorityRoadSign
            case .noEntry:             noEntrySign
            case .speedLimit(let n):   speedLimitSign(n)
            case .endSpeedLimit(let n): endSpeedLimitSign(n)
            case .noOvertaking:        noOvertakingSign
            case .noParking:           noParkingSign
            case .noStopping:          noStoppingSign
            case .endRestrictions:     endRestrictionsSign
            case .endNoOvertaking:     endNoOvertakingSign
            case .roundabout:          roundaboutSign
            case .mandatoryRight:      mandatoryDirectionSign(angle: 0)
            case .mandatoryLeft:       mandatoryDirectionSign(angle: 180)
            case .mandatoryStraight:   mandatoryDirectionSign(angle: 90)
            case .minSpeed(let n):     minSpeedSign(n)
            case .motorway:            motorwaySign
            case .endMotorway:         endMotorwaySign
            case .oneWay:              oneWaySign
            case .parking:             parkingSign
            case .priorityOverOncoming: priorityOverOncomingSign
            case .giveWayToOncoming:   giveWayToOncomingSign
            case .pedestrianOnly:      pedestrianOnlySign
            case .mandatoryBicycle:    bicycleOnlySign
            case .noHorns:             noHornsSign
            default:                   warningSign(for: signType)
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Warning Signs (triangle)
    @ViewBuilder
    private func warningSign(for type: TrafficSignType) -> some View {
        ZStack {
            TriangleShape()
                .fill(Color.white)
                .overlay(TriangleShape().stroke(Color.red, lineWidth: size * 0.07))
                .frame(width: size * 0.92, height: size * 0.92)
            warningContent(for: type)
                .frame(width: size * 0.42, height: size * 0.42)
                .offset(y: size * 0.06)
        }
    }

    @ViewBuilder
    private func warningContent(for type: TrafficSignType) -> some View {
        switch type {
        case .warningGeneral:
            Text("!").font(.system(size: size * 0.32, weight: .black)).foregroundColor(.black)
        case .warningCrossroads:
            Image(systemName: "plus").font(.system(size: size * 0.25, weight: .bold)).foregroundColor(.black)
        case .warningPedestrian:
            Image(systemName: "figure.walk").font(.system(size: size * 0.25, weight: .medium)).foregroundColor(.black)
        case .warningSlippery:
            Image(systemName: "car.fill").font(.system(size: size * 0.22)).foregroundColor(.black)
        case .warningTwoWay:
            Image(systemName: "arrow.up.arrow.down").font(.system(size: size * 0.22, weight: .bold)).foregroundColor(.black)
        case .warningRailway:
            Image(systemName: "tram.fill").font(.system(size: size * 0.22)).foregroundColor(.black)
        case .warningCurveLeft:
            Image(systemName: "arrow.turn.up.left").font(.system(size: size * 0.25, weight: .bold)).foregroundColor(.black)
        case .warningCurveRight:
            Image(systemName: "arrow.turn.up.right").font(.system(size: size * 0.25, weight: .bold)).foregroundColor(.black)
        case .warningNarrowRoad:
            Image(systemName: "arrow.left.and.right").font(.system(size: size * 0.22, weight: .bold)).foregroundColor(.black)
        case .warningRoadworks:
            Image(systemName: "hammer.fill").font(.system(size: size * 0.22)).foregroundColor(.black)
        case .warningAnimals:
            Image(systemName: "pawprint.fill").font(.system(size: size * 0.24)).foregroundColor(.black)
        case .warningChildren:
            Image(systemName: "person.2.fill").font(.system(size: size * 0.20)).foregroundColor(.black)
        default:
            Text("!").font(.system(size: size * 0.28, weight: .black)).foregroundColor(.black)
        }
    }

    // MARK: - STOP
    private var stopSign: some View {
        ZStack {
            OctagonShape().fill(Color.red)
            OctagonShape().stroke(Color.white, lineWidth: size * 0.05)
                .padding(size * 0.07)
            Text("STOP")
                .font(.system(size: size * 0.22, weight: .black, design: .default))
                .foregroundColor(.white)
                .tracking(1)
        }
    }

    // MARK: - Give Way
    private var giveWaySign: some View {
        ZStack {
            TriangleShape(inverted: true)
                .fill(Color.white)
                .overlay(TriangleShape(inverted: true).stroke(Color.red, lineWidth: size * 0.09))
        }
        .frame(width: size * 0.92, height: size * 0.82)
    }

    // MARK: - Priority Road
    private var priorityRoadSign: some View {
        DiamondShape()
            .fill(Color.yellow)
            .overlay(DiamondShape().stroke(Color.black, lineWidth: size * 0.025))
            .frame(width: size * 0.70, height: size * 0.70)
    }

    // MARK: - End Priority Road
    private var endPriorityRoadSign: some View {
        ZStack {
            DiamondShape()
                .fill(Color.white)
                .overlay(DiamondShape().stroke(Color.black, lineWidth: size * 0.025))
                .frame(width: size * 0.70, height: size * 0.70)
            Rectangle()
                .fill(Color.black)
                .frame(width: size * 0.50, height: size * 0.06)
                .rotationEffect(.degrees(45))
        }
    }

    // MARK: - No Entry
    private var noEntrySign: some View {
        ZStack {
            Circle().fill(Color.red)
            Rectangle()
                .fill(Color.white)
                .frame(width: size * 0.60, height: size * 0.18)
                .cornerRadius(size * 0.04)
        }
    }

    // MARK: - Speed Limit
    private func speedLimitSign(_ limit: Int) -> some View {
        ZStack {
            Circle().fill(Color.white)
            Circle().stroke(Color.red, lineWidth: size * 0.10)
            Text("\(limit)")
                .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                .foregroundColor(.black)
        }
    }

    // MARK: - End Speed Limit
    private func endSpeedLimitSign(_ limit: Int) -> some View {
        ZStack {
            Circle().fill(Color.white)
            Circle().stroke(Color.gray, lineWidth: size * 0.06)
            Text("\(limit)")
                .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                .foregroundColor(.gray)
            // Diagonal stripes overlay
            ForEach(0..<4) { i in
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: size * 0.7, height: size * 0.025)
                    .rotationEffect(.degrees(-45))
                    .offset(y: CGFloat(i - 1) * size * 0.14)
            }
        }
        .clipShape(Circle())
    }

    // MARK: - No Overtaking
    private var noOvertakingSign: some View {
        ZStack {
            Circle().fill(Color.white)
            Circle().stroke(Color.red, lineWidth: size * 0.09)
            HStack(spacing: size * 0.02) {
                Circle().fill(Color.red).frame(width: size * 0.22, height: size * 0.22)
                Circle().fill(Color.black).frame(width: size * 0.22, height: size * 0.22)
                    .offset(x: -size * 0.08)
            }
            // Red diagonal slash
            Rectangle()
                .fill(Color.red)
                .frame(width: size * 0.7, height: size * 0.07)
                .rotationEffect(.degrees(-30))
        }
    }

    // MARK: - No Parking
    private var noParkingSign: some View {
        ZStack {
            Circle().fill(Color.white)
            Circle().stroke(Color.blue, lineWidth: size * 0.09)
            Text("P")
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundColor(.blue)
            Rectangle()
                .fill(Color.red)
                .frame(width: size * 0.7, height: size * 0.07)
                .rotationEffect(.degrees(-45))
        }
    }

    // MARK: - No Stopping
    private var noStoppingSign: some View {
        ZStack {
            Circle().fill(Color.blue)
            Circle().stroke(Color.white, lineWidth: size * 0.03)
                .padding(size * 0.06)
            // X mark
            Group {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: size * 0.55, height: size * 0.10)
                    .rotationEffect(.degrees(45))
                Rectangle()
                    .fill(Color.red)
                    .frame(width: size * 0.55, height: size * 0.10)
                    .rotationEffect(.degrees(-45))
            }
        }
    }

    // MARK: - End Restrictions
    private var endRestrictionsSign: some View {
        ZStack {
            Circle().fill(Color.white)
            Circle().stroke(Color.gray, lineWidth: size * 0.05)
            // Multiple diagonal stripes
            ForEach(Array(stride(from: -3, through: 3, by: 1)), id: \.self) { i in
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: size * 0.7, height: size * 0.025)
                    .rotationEffect(.degrees(-45))
                    .offset(y: CGFloat(i) * size * 0.13)
            }
        }
        .clipShape(Circle())
    }

    // MARK: - End No Overtaking
    private var endNoOvertakingSign: some View {
        ZStack {
            Circle().fill(Color.white)
            Circle().stroke(Color.gray, lineWidth: size * 0.06)
            HStack(spacing: size * 0.02) {
                Circle().fill(Color.gray).frame(width: size * 0.20, height: size * 0.20)
                Circle().fill(Color.gray.opacity(0.5)).frame(width: size * 0.20, height: size * 0.20)
                    .offset(x: -size * 0.08)
            }
            ForEach(0..<3) { i in
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: size * 0.70, height: size * 0.025)
                    .rotationEffect(.degrees(-45))
                    .offset(y: CGFloat(i - 1) * size * 0.14)
            }
        }
        .clipShape(Circle())
    }

    // MARK: - Roundabout
    private var roundaboutSign: some View {
        ZStack {
            Circle().fill(Color.blue)
            Circle().stroke(Color.white, lineWidth: size * 0.03).padding(size * 0.06)
            Image(systemName: "arrow.clockwise")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Mandatory Direction
    private func mandatoryDirectionSign(angle: Double) -> some View {
        ZStack {
            Circle().fill(Color.blue)
            Image(systemName: "arrow.up")
                .font(.system(size: size * 0.40, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(angle))
        }
    }

    // MARK: - Minimum Speed
    private func minSpeedSign(_ speed: Int) -> some View {
        ZStack {
            Circle().fill(Color.blue)
            Text("\(speed)")
                .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    // MARK: - Motorway
    private var motorwaySign: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(Color.blue)
            VStack(spacing: 1) {
                Image(systemName: "car.fill")
                    .font(.system(size: size * 0.22))
                    .foregroundColor(.white)
                Text("AUTO")
                    .font(.system(size: size * 0.13, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size * 0.80, height: size * 0.65)
    }

    // MARK: - End Motorway
    private var endMotorwaySign: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: size * 0.12).stroke(Color.gray, lineWidth: size * 0.04))
            VStack(spacing: 1) {
                Image(systemName: "car.fill")
                    .font(.system(size: size * 0.22))
                    .foregroundColor(.gray)
                Text("AUTO")
                    .font(.system(size: size * 0.13, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: size * 0.80, height: size * 0.65)
    }

    // MARK: - One Way
    private var oneWaySign: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.10).fill(Color.blue)
            Image(systemName: "arrow.right")
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size * 0.55)
    }

    // MARK: - Parking
    private var parkingSign: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12).fill(Color.blue)
            Text("P")
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size * 0.72, height: size * 0.72)
    }

    // MARK: - Priority Over Oncoming
    private var priorityOverOncomingSign: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.10)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: size * 0.10).stroke(Color.black, lineWidth: size * 0.025))
            HStack(spacing: size * 0.06) {
                Image(systemName: "arrow.down").foregroundColor(.red).font(.system(size: size * 0.20, weight: .bold))
                Image(systemName: "arrow.up").foregroundColor(.black).font(.system(size: size * 0.28, weight: .bold))
            }
        }
        .frame(width: size, height: size * 0.55)
    }

    // MARK: - Give Way to Oncoming
    private var giveWayToOncomingSign: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.10)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: size * 0.10).stroke(Color.black, lineWidth: size * 0.025))
            HStack(spacing: size * 0.06) {
                Image(systemName: "arrow.down").foregroundColor(.black).font(.system(size: size * 0.28, weight: .bold))
                Image(systemName: "arrow.up").foregroundColor(.red).font(.system(size: size * 0.20, weight: .bold))
            }
        }
        .frame(width: size, height: size * 0.55)
    }

    // MARK: - Pedestrian Only
    private var pedestrianOnlySign: some View {
        ZStack {
            Circle().fill(Color.blue)
            Image(systemName: "figure.walk")
                .font(.system(size: size * 0.40, weight: .medium))
                .foregroundColor(.white)
        }
    }

    // MARK: - Bicycle Only
    private var bicycleOnlySign: some View {
        ZStack {
            Circle().fill(Color.blue)
            Image(systemName: "bicycle")
                .font(.system(size: size * 0.38))
                .foregroundColor(.white)
        }
    }

    // MARK: - No Horns
    private var noHornsSign: some View {
        ZStack {
            Circle().fill(Color.white)
            Circle().stroke(Color.red, lineWidth: size * 0.09)
            Image(systemName: "speaker.slash.fill")
                .font(.system(size: size * 0.32))
                .foregroundColor(.black)
            Rectangle()
                .fill(Color.red)
                .frame(width: size * 0.70, height: size * 0.07)
                .rotationEffect(.degrees(-30))
        }
    }
}

// MARK: - Question Visual View

struct QuestionVisualView: View {
    let visual: QuestionVisual
    var size: CGFloat = 130

    var body: some View {
        switch visual {
        case .none:
            EmptyView()
        case .trafficSign(let type):
            signContainer(content: TrafficSignView(signType: type, size: size))
        case .scenario(let symbol, let colorName):
            scenarioView(symbol: symbol, colorName: colorName)
        }
    }

    private func signContainer<C: View>(content: C) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .frame(width: size + 56, height: size + 56)
                .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
                .frame(width: size + 56, height: size + 56)
            content
        }
    }

    private func scenarioView(symbol: String, colorName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(scenarioColor(colorName).opacity(0.15))
                .frame(width: size + 40, height: size + 40)
            Image(systemName: symbol)
                .font(.system(size: size * 0.55))
                .foregroundColor(scenarioColor(colorName))
        }
    }

    private func scenarioColor(_ name: String) -> Color {
        switch name {
        case "blue":   return .catBlue
        case "orange": return .catOrange
        case "red":    return .catRed
        case "green":  return .catGreen
        case "purple": return .catPurple
        case "yellow": return .yellow
        default:       return .greekBlue
        }
    }
}
