//
//  ConstantManager.swift
//  Clinic
//
//  Created by Admin on 25/02/16.
//  Copyright © 2016 RonnieAlex. All rights reserved.
//

import Foundation
import UIKit

let TheInterfaceManager = InterfaceManager.sharedInstance
let rootViewController =  UIApplication.shared.keyWindow?.rootViewController

extension UIImageView {
    func downloadedFrom(_ link:String, contentMode mode: UIViewContentMode) {
        guard
            let url = URL(string: link)
            else {return}
        contentMode = mode
        let loadingActivity = UIActivityIndicatorView(activityIndicatorStyle: .white)
        loadingActivity.tag = 10
        loadingActivity.frame = self.frame
        self.addSubview(loadingActivity)
        loadingActivity.startAnimating()
        URLSession.shared.dataTask(with: url as URL, completionHandler: { (data, response, error) -> Void in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else
                {
                    loadingActivity.stopAnimating()
                    loadingActivity.removeFromSuperview()
                    return
                }
            DispatchQueue.main.async() { () -> Void in
                loadingActivity.stopAnimating()
                loadingActivity.removeFromSuperview()
                self.image = image
            }
        }).resume()
    }
}

let appDelegate = UIApplication.shared.delegate as! AppDelegate//Your app delegate class name.
extension UIApplication {
    class func topViewController(_ base: UIViewController? = appDelegate.window!.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}

class InterfaceManager: NSObject, UIAlertViewDelegate {
    static let sharedInstance = InterfaceManager()
    var appName:String = ""

    let mainColor:UIColor = UIColor(red: 77.0/255.0, green: 181.0/255.0, blue: 219.0/255.0, alpha: 1.0)
    let borderColor:UIColor = UIColor(red: 151.0 / 255.0, green: 151.0 / 255.0, blue: 151.0 / 255.0, alpha: 1.0)
    let naviTintColor:UIColor = UIColor(red: 252.0/255.0, green: 110.0/255.0, blue: 81.0/255.0, alpha: 1.0)
    
    override init() {
        super.init()
        let bundleInfoDict: NSDictionary = Bundle.main.infoDictionary! as NSDictionary
        appName = bundleInfoDict["CFBundleName"] as! String
    }
    
    func deviceHeight ()-> CGFloat{
        return UIScreen.main.bounds.size.height
    }
    
    func deviceWidth () -> CGFloat{
        return UIScreen.main.bounds.size.width
    }
    
    func showLocalValidationError(_ view:UIViewController, errorMessage:String)-> Void{
        let title:String = "\(appName) Error"
        
        let alert = UIAlertController(title: title, message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        view.present(alert, animated: true, completion: nil)
    }
    
    func showLocalValidationError(_ view:UIViewController, title:String, errorMessage:String)-> Void{
        
        let alert = UIAlertController(title: title, message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        view.present(alert, animated: true, completion: nil)
        
    }
    
    func showSuccessMessage (_ view:UIViewController,  successMessage:String)-> Void{
        
        let alert = UIAlertController(title: appName, message: successMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        view.present(alert, animated: true, completion: nil)
        
    }
    
    func showToastView(_ title: String) {
        JLToast.makeText(title, duration: 2.0).show()
    }
    
//    static func showLoadingView(view: UIView,	 title: String) {
//        let loadingView = MBProgressHUD.init(view: view)
//        view.addSubview(loadingView)
//        
//        loadingView.tag = 1200
//        loadingView.labelText = title
//        loadingView.labelColor = UIColor.whiteColor()
//        loadingView.labelFont = UIFont(name: Constants.MainFontNames.Regular, size: 13.0)
//        loadingView.dimBackground = true
//        
//        loadingView.show(true)
//    }
    
//    static func hideLoadingView(view: UIView) {
//        var loadingView = view.viewWithTag(1200) as? MBProgressHUD
//        if (loadingView != nil) {
//            loadingView?.hide(true)
//            loadingView?.removeFromSuperview()
//            loadingView = nil
//        }
//    }

    static func makeRadiusControl(_ view:UIView, cornerRadius radius:CGFloat, withColor borderColor:UIColor, borderSize borderWidth:CGFloat) {
        view.layer.cornerRadius = radius
        view.layer.borderWidth = borderWidth
        view.layer.borderColor = borderColor.cgColor
        view.layer.masksToBounds = true
    }
    
    static func addBorderToView(_ view:UIView, toCorner corner:UIRectCorner, cornerRadius radius:CGSize, withColor borderColor:UIColor, borderSize borderWidth:CGFloat) {
        let maskPath = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: corner, cornerRadii: radius)
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = view.bounds
        maskLayer.path  = maskPath.cgPath
        
        view.layer.mask = maskLayer
        
        let borderLayer = CAShapeLayer()
        borderLayer.frame = view.bounds
        borderLayer.path  = maskPath.cgPath
        borderLayer.lineWidth   = borderWidth
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.fillColor   = UIColor.clear.cgColor
        borderLayer.setValue("border", forKey: "name")
        
        if let sublayers = view.layer.sublayers {
            for prevLayer in sublayers {
                if let name: AnyObject = prevLayer.value(forKey: "name") as AnyObject {
                    if name as! String == "border" {
                        prevLayer.removeFromSuperlayer()
                    }
                }
            }
        }
        
        view.layer.addSublayer(borderLayer)
    }
    
    
    
}
