//
//  ViewUtils.swift
//  WebexSDKModule
//
//  Created by Daniel Zarinski on 27/07/22.
//  Copyright © 2022 Launchcode. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func fillSuperView(padded: CGFloat = 0) {
        guard let superview = superview else { fatalError("View doesn't have a superview") }
        fill(view: superview, padded: padded)
    }
      
    func fillWidth(of view: UIView, padded: CGFloat = 0) {
        leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padded).isActive = true
        trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padded).isActive = true
    }
      
    func fillHeight(of view: UIView, padded: CGFloat = 0) {
        topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padded).isActive = true
        bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padded).isActive = true
    }
      
    func fill(view: UIView, padded: CGFloat = 0) {
        fillWidth(of: view, padded: padded)
        fillHeight(of: view, padded: padded)
    }
      
    func alignCenter(in view: UIView? = nil) {
        guard let viewB = view ?? superview else { fatalError("No View to anchor") }
        centerXAnchor.constraint(equalTo: viewB.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: viewB.centerYAnchor).isActive = true
    }
      
    func setWidth(_ width: CGFloat) {
        widthAnchor.constraint(equalToConstant: width).isActive = true
    }
      
    func setHeight(_ height: CGFloat) {
        heightAnchor.constraint(equalToConstant: height).isActive = true
    }
      
    func setSize(width: CGFloat, height: CGFloat) {
        setWidth(width)
        setHeight(height)
    }
      
    func flipX() {
        transform = CGAffineTransform(scaleX: -transform.a, y: transform.d)
    }
      
    func flipY() {
        transform = CGAffineTransform(scaleX: transform.a, y: -transform.d)
    }
}
