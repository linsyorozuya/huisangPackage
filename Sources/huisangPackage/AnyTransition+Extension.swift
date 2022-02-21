//
//  AnyTransition+Extension.swift
//
//  Created by 灰桑 on 2021/3/25.
//  Copyright © 2021 灰桑. All rights reserved.
//

import SwiftUI

extension AnyTransition {
    static var pivot: AnyTransition {
        .modifier(
            active: AxisXRotateModifier(amount: 90),
            identity: AxisXRotateModifier(amount: 0)
        )
    }

    static var rpivot: AnyTransition {
        .modifier(
            active: FlyModifier(pct: 0),
            identity: FlyModifier(pct: 1)
        )
    }

    static var fly: AnyTransition {
        AnyTransition.modifier(active: FlyModifier(pct: 0), identity: FlyModifier(pct: 1))
    }
}

struct CornerRotateModifier: ViewModifier {
    let amount: Double
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content.rotationEffect(.degrees(amount), anchor: anchor).clipped()
    }
}

struct AxisXRotateModifier: ViewModifier {
    let amount: Double
    func body(content: Content) -> some View {
        content.rotation3DEffect(
            .degrees(amount),
            axis: (x: 1.0, y: 0.0, z: 0.0)
        ).clipped()
    }
}

struct FlyModifier: GeometryEffect {
    var pct: Double

    var animatableData: Double {
        get {
            pct
        }
        set {
            pct = newValue
        }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let a = CGFloat(Angle(degrees: 90 * (1 - pct)).radians)

        var transform3d = CATransform3DIdentity
        transform3d.m34 = -1 / max(size.width, size.height)

        transform3d = CATransform3DRotate(transform3d, a, 1, 0, 0)
        transform3d = CATransform3DTranslate(transform3d, -size.width / 2.0, -size.width / 2.0, 0)

        let afffineTransform1 = ProjectionTransform(CGAffineTransform(translationX: size.width / 2.0, y: size.width / 2.0))
        let afffineTransform2 = ProjectionTransform(CGAffineTransform(scaleX: CGFloat(pct * 2), y: CGFloat(pct * 2)))

        if pct <= 0.5 {
            return ProjectionTransform(transform3d).concatenating(afffineTransform2).concatenating(afffineTransform1)
        } else {
            return ProjectionTransform(transform3d).concatenating(afffineTransform1)
        }
    }
}
