//
//  LoadingOverlay.swift
//  READY
//
//  Created by Admin on 04/03/16.
//  Copyright © 2016 Andrei. All rights reserved.
//

import UIKit
import Foundation


open class LoadingOverlay{
    
    var overlayView = UIView()
    var activityIndicator = UIActivityIndicatorView()

    class var shared: LoadingOverlay {
        struct Static {
            static let instance: LoadingOverlay = LoadingOverlay()
        }
        return Static.instance
    }
    
    open func showOverlay(_ view: UIView!) {
        overlayView = UIView(frame: UIScreen.main.bounds)
        overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        activityIndicator.center = overlayView.center
        overlayView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        view.addSubview(overlayView)
    }
    
    open func hideOverlayView() {
        activityIndicator.stopAnimating()
        overlayView.removeFromSuperview()
    }
}
