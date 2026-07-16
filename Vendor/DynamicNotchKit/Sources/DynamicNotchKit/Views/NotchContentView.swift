//
//  NotchContentView.swift
//  DynamicNotchKit
//
//  Created by Kai Azim on 2025-04-19.
//

import SwiftUI

struct NotchContentView<Expanded, CompactLeading, CompactTrailing>: View where Expanded: View, CompactLeading: View, CompactTrailing: View {
    @ObservedObject private var dynamicNotch: DynamicNotch<Expanded, CompactLeading, CompactTrailing>
    @Namespace private var namespace
    private let style: DynamicNotchStyle

    init(dynamicNotch: DynamicNotch<Expanded, CompactLeading, CompactTrailing>, style: DynamicNotchStyle) {
        self.dynamicNotch = dynamicNotch
        self.style = style
    }

    private var shadowOpacity: CGFloat {
        dynamicNotch.state == .expanded ? 0.5 : 0.0
    }

    private var shadowRadius: CGFloat {
        dynamicNotch.state == .hidden ? 0 : 10
    }

    var body: some View {
        ZStack {
            if style.isNotch {
                NotchView(dynamicNotch: dynamicNotch)
                    .foregroundStyle(.white)
            } else {
                NotchlessView(dynamicNotch: dynamicNotch)
            }
        }
        .shadow(
            color: .black.opacity(shadowOpacity),
            radius: shadowRadius
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .environment(\.notchStyle, style)
        .onAppear {
            if dynamicNotch.namespace == nil {
                dynamicNotch.namespace = namespace
            }
        }
    }
}
