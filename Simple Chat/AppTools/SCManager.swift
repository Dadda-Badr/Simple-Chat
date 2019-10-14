//
//  SCManager.swift
//  Simple Chat
//
//  Created by Badr Dadda on 11/10/2019.
//  Copyright © 2019 Adria. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD


class SCManager: NSObject {
    
    class func switchRootViewController(rootViewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let window = UIApplication.shared.keyWindow else { return } 
        if animated {
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                let oldState: Bool = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(false)
                window.rootViewController = rootViewController
                UIView.setAnimationsEnabled(oldState)
            }, completion: { (finished: Bool) -> () in
                if (completion != nil) {
                    completion!()
                }
            })
        } else {
            window.rootViewController = rootViewController
        }
    }
    
    class func addProgressHUDToView(parentView : UIView,title : String?,message : String?) -> Void {
        
        let spinnerActivity = MBProgressHUD.showAdded(to: parentView, animated: true)
        spinnerActivity.backgroundView.color = UIColor.black.withAlphaComponent(0.05)
        
        if let uTitle = title
        {
            spinnerActivity.label.text = uTitle
        }
        
        if let uMessage = message
        {
            spinnerActivity.detailsLabel.text = uMessage
        }
    }
    
    class func removeProgressHUDFromView(parentView : UIView) -> Void {
        MBProgressHUD.hide(for: parentView, animated: true)
    }
     
    class func showAlert(title : String,message : String, okString : String, cancelString : String?,parent : UIViewController, completion: ((Bool) -> Void)?) {
        let alert = UIAlertController(title:title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okString, style: .default, handler: { action in
            if let safeCompletion = completion
            {
                safeCompletion(true)
            }
        }))
        if cancelString != nil
        {
            alert.addAction(UIAlertAction(title: cancelString, style: .cancel, handler:  { action in
                if let safeCompletion = completion
                {
                    safeCompletion(false)
                }
            }))
        }
        parent.present(alert, animated: true)
    }
    
}
