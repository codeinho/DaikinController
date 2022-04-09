//
//  ViewHelper.swift
//  Daikin
//
//  Created by Lothar Heinrich on 06.01.22.
//

import Foundation
import SwiftUI

extension View {
  func emptyState<EmptyContent>(_ isEmpty: Bool,
                                emptyContent: @escaping () -> EmptyContent) -> some View where EmptyContent: View {
    modifier(EmptyStateViewModifier(isEmpty: isEmpty, emptyContent: emptyContent))
  }
}
struct EmptyStateViewModifier<EmptyContent>: ViewModifier where EmptyContent: View {
  var isEmpty: Bool
  let emptyContent: () -> EmptyContent
  
  func body(content: Content) -> some View {
    if isEmpty {
      emptyContent()
    }
    else {
      content
    }
  }
}


enum ViewVisibility: CaseIterable {
  case visible, // view is fully visible
       invisible, // view is hidden but takes up space
       gone // view is fully removed from the view hierarchy
}
extension View {
  @ViewBuilder func visibility(_ visibility: ViewVisibility) -> some View {
    if visibility != .gone {
      if visibility == .visible {
        self
      } else {
        hidden()
      }
    }
  }
}

extension View {
    func addErrorBadge(_ error: Bool = true) -> some View {
        ZStack(alignment: .topLeading) {
            self

            if error {
                Image(systemName: "exclamationmark.circle.fill")// "wifi.exclamationmark")
                    .offset(x: -4, y: -4)
                    .foregroundColor(.yellow)
            }
        }
    }
}





func systemGray6(colorScheme: ColorScheme) -> Color {
#if os(macOS)
    if colorScheme == .light {
        return Color(red: 242/255, green: 242/255, blue: 247/255, opacity: 1.0)
    } else {
        return Color(red: 28/255, green: 28/255, blue: 30/255, opacity: 1.0)
    }
#else
    return Color(.systemGray6)
#endif
}
extension Color {
//    249, 66, 58
//    public static var warmRed: Color {
//        return Color(red: 249.0 / 255.0, green: 66.0 / 255.0, blue: 58.0 / 255.0, opacity: 0.1)
//        }
    public static let warmRed = Color(red: 249.0 / 255.0, green: 66.0 / 255.0, blue: 58.0 / 255.0)//, opacity: 0.1)
    public static let coldBlue = Color(red: 108.0 / 255.0, green: 160.0 / 255.0, blue: 220.0 / 255.0)//, opacity: 0.1)

}

