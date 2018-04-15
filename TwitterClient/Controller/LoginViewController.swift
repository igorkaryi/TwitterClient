//
//  LoginViewController.swift
//  TwitterClient
//
//  Created by Igor Karyi on 13.04.2018.
//  Copyright © 2018 Igor Karyi. All rights reserved.
//

import UIKit
import BDBOAuth1Manager

class LoginViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: ACTIONS
    @IBAction func loginAction(_ sender: UIButton) {
        TwitterClient.sharedInstance?.login(success: { () -> Void in
            self.performSegue(withIdentifier: "ShowTweets", sender: nil)
            
        }, failure: { (error: Error) in
            print("onLoginButton-error: \(error.localizedDescription)")
        })
    }
    
}

