//
//  View+Extension.swift
//
//  Created by 灰桑 on 2021/3/5.
//  Copyright © 2021 灰桑. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: 视图大小

extension View {
    /// 让 View 尽可能撑大容器
    func flexibleFrame(_ flexibleAxis: Axis.Set = [.horizontal, .vertical],
                       alignment: Alignment = .center) -> some View
    {
        return frame(
            maxWidth: flexibleAxis.contains(.horizontal) ? .infinity : nil,
            maxHeight: flexibleAxis.contains(.vertical) ? .infinity : nil,
            alignment: alignment
        )
    }

    /// onPreferenceChange helper
    func readPreference<K>(
        _ key: K.Type = K.self,
        to binding: Binding<K.Value>
    ) -> some View where K: PreferenceKey, K.Value: Equatable {
        onPreferenceChange(key) { value in
            binding.wrappedValue = value
        }
    }

    /// 获取当前视图大小
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: proxy.frame(in: .named("readSizeChange")).size)
                    .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
            }

            self
        }
        .frame(maxWidth: .infinity)
        .coordinateSpace(name: "readSizeChange")
    }

    /// TextFiled Placehold Color
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct SingleAxisGeometryReader<Content: View>: View {
    private struct SizeKey: PreferenceKey {
        static var defaultValue: CGFloat { 10 }
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    @State private var size: CGFloat = SizeKey.defaultValue

    var axis: Axis = .horizontal
    var alignment: Alignment = .center
    let content: (CGFloat) -> Content

    var body: some View {
        ZStack {
            sizeReader
                .onPreferenceChange(SizeKey.self, perform: onSizeChange)
            content(size)
        }
        .frame(maxWidth: axis == .horizontal ? .infinity : nil,
               maxHeight: axis == .vertical ? .infinity : nil,
               alignment: alignment)
        .coordinateSpace(name: "singleAxisGeometryReader")
    }

    var sizeReader: some View {
        GeometryReader {
            proxy in
            Color.clear
                .preference(key: SizeKey.self, value: axis == .horizontal ? proxy.frame(in: .named("singleAxisGeometryReader")).size.width : proxy.frame(in: .named("singleAxisGeometryReader")).size.height)
        }
    }

    func onSizeChange(size: CGFloat) {
        if self.size != size {
            self.size = min(max(0, size), 10000)
        }
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// MARK: 其他

extension View {
    /// 简化 NavigationLink 层级， 使用 Bool 跳转
    func navigate<Destination: View>(
        titleKey: LocalizedStringKey = "",
        isActive: Binding<Bool>,
        destination: Destination
    ) -> some View {
        background(NavigationLink(titleKey, destination: destination, isActive: isActive))
    }

    /// 简化 AnyView 包装层级
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }

    /// 简化 Button 包装层级
    func insideButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            self.contentShape(Rectangle())
        })
    }
}

// MARK: 版本适配

extension View {
    /// iOS 14 输入框获取焦点后， view 会自动上移，需要处理
    @available(
        iOS, introduced: 13, deprecated: 14,
        message: "Use .ignoresSafeArea(.keyboard) directly"
    )
    @ViewBuilder
    func ignoreKeyboard() -> some View {
        if #available(iOS 14.0, *) {
            ignoresSafeArea(.keyboard)
        } else {
            self
        }
    }

    @ViewBuilder
    func disableKeyboardAvoidIniOS14() -> some View {
        if #available(iOS 14.0, *) {
            GeometryReader { _ in
                self
            }
        } else {
            self
        }
    }

    /// iOS 14 最后一个Cell底部有分割线
    @ViewBuilder
    func fixListRowInsets() -> some View {
        if #available(iOS 14.0, *) {
            listRowInsets(EdgeInsets(.init(top: -1, leading: -1, bottom: -1, trailing: -1)))
        } else {
            listRowInsets(EdgeInsets())
        }
    }

    //  隐藏下划线

    @ViewBuilder
    func hiddenListRowSeparator() -> some View {
        if #available(iOS 15.0, *) {
            self.listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .fixListRowInsets()
        } else {
            listRowBackground(Color.clear)
                .fixListRowInsets()
        }
    }

    /// iOS 14 Section Header 字母会自动变大写
    @ViewBuilder
    func noUppercaseStyle() -> some View {
        if #available(iOS 14, *) {
            textCase(.none)
        } else {
            self
        }
    }

    /// iOS 14 List Group 样式
    @available(
        iOS, introduced: 13, deprecated: 14,
        message: "Use .listStyle(InsetGroupedListStyle()) directly"
    )
    @ViewBuilder
    func adjustGroupStyle() -> some View {
        if #available(iOS 14, *) {
            listStyle(InsetGroupedListStyle())
        } else {
            listStyle(GroupedListStyle())
                .environment(\.horizontalSizeClass, .regular)
        }
    }

    /// 混合渐变颜色
    func gradientForeground(colors: [Color]) -> some View {
        overlay(LinearGradient(gradient: .init(colors: colors),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
        ).mask(self)
    }

    @ViewBuilder
    func sheetFullScreenInIos14<Content>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View where Content: View {
        if #available(iOS 14.0, *) {
            fullScreenCover(isPresented: isPresented) {
                content()
            }
        } else {
            sheet(isPresented: isPresented) {
                content()
            }
        }
    }
}

// MARK: 圆角处理

/// 头像圆角比例
let continueRate: CGFloat = 0.45
extension View {
    /// 圆角位置选择
    func cornersRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    /// 连续圆角
    @ViewBuilder
    func continuesCorner(_ cornerRadius: CGFloat,
                         borderWidth: CGFloat = 0,
                         spacing: CGFloat = 0,
                         color: Color = Color(UIColor.systemBackground),
                         continueRate: CGFloat = 1) -> some View
    {
        if borderWidth > 0 {
            if spacing == 0 {
                clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(color, lineWidth: borderWidth * 2)
                    )
            } else {
                clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .padding(spacing + borderWidth / 2.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius + (spacing + borderWidth / 2.0) * continueRate, style: .continuous)
                            .stroke(color, lineWidth: borderWidth)
                    )
            }
        } else {
            clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    /// 据点的圆角
    func nodeContinuesCorner(
        _ width: CGFloat,
        borderWidth: CGFloat = 0,
        spacing: CGFloat = 0,
        color: Color = Color(UIColor.systemBackground),
        continueRate: CGFloat = continueRate
    ) -> some View {
        continuesCorner(width * continueRate, borderWidth: borderWidth, spacing: spacing, color: color, continueRate: continueRate)
    }

    /// 圆角背景
    func continuesBackground(_ radius: CGFloat, color: Color = Color(UIColor.systemBackground)) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(color)
        )
    }
}

/// 通过贝塞尔曲线制定圆角位置
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: 截图

extension View {
    /// View 生成 图片
    func snapshot(size: CGSize? = nil) -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = size != nil ? size! : controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    /// View 生成 图片
    func getSize(size: CGSize? = nil) -> CGSize {
        let controller = UIHostingController(rootView: self)
        let targetSize = size != nil ? size! : controller.view.intrinsicContentSize
        return targetSize
    }
}

// MARK: - -  通过判断可选值是否显示 view 的优雅实现

extension View {
    @ViewBuilder
    func ifLet<V, Transform: View>(
        _ value: V?,
        transform: (Self, V) -> Transform
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

/// reference: https://www.swiftbysundell.com/tips/optional-swiftui-views/
struct Unwrap<Value, Content: View>: View {
    private let value: Value?
    private let contentProvider: (Value) -> Content

    init(_ value: Value?,
         @ViewBuilder content: @escaping (Value) -> Content)
    {
        self.value = value
        self.contentProvider = content
    }

    var body: some View {
        value.map(contentProvider)
    }
}

@available(iOS, deprecated: 15.0, message: "Use the built-in APIs instead")
extension View {
    func background<T: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> T
    ) -> some View {
        background(Group(content: content), alignment: alignment)
    }

    func overlay<T: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> T
    ) -> some View {
        overlay(Group(content: content), alignment: alignment)
    }
}
