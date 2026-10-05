//
//  ShareSheet.swift
//  Pulse
//
//  UIKit share sheet wrapper used to hand generated export files
//  to the system share destinations (Files, AirDrop, Mail, etc.).
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
