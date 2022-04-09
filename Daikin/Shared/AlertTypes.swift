////
////  AlertTypes.swift
////  Daikin
////
////  Created by Lothar Heinrich on 04.01.22.
////
//
//import Foundation
//import SwiftUI
//
//
//// https://betterprogramming.pub/swiftui-enums-and-alerts-8b5d75d81e78
//enum AlertTypes: Identifiable {
//    
//    case defaultButton(title: String,
//                       message: String? = nil)
//    
//    case singleButton(title: String,
//                      message: String? = nil,
//                      dismissButton: Alert.Button)
//    
//    case twoButton(title: String,
//                      message: String? = nil,
//                      primaryButton: Alert.Button,
//                      secondaryButton: Alert.Button)
//    
//    var alert: Alert {
//        switch self {
//        case .defaultButton(title: let title,
//                            message: let message):
//            
//            return Alert(title: Text(title),
//                         message: message != nil ? Text(message!) : nil)
//            
//        case .singleButton(title: let title,
//                           message: let message,
//                           dismissButton: let dismissButton):
//            
//            return Alert(title: Text(title),
//                         message: message != nil ? Text(message!) : nil,
//                         dismissButton: dismissButton)
//            
//        case .twoButton(title: let title,
//                         message: let message,
//                         primaryButton: let primaryButton,
//                         secondaryButton: let secondaryButton):
//            
//            return Alert(title: Text(title),
//                         message: message != nil ? Text(message!) : nil,
//                         primaryButton: primaryButton,
//                         secondaryButton: secondaryButton)
//        }
//    }
//    
//    var id: String {
//        switch self {
//        case .defaultButton:
//            return "ok"
//        case .singleButton:
//            return "singleButton"
//        case .twoButton:
//            return "twoButton"
//        }
//    }
//    
//}
