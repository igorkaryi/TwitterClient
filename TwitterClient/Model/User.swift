//
//  User.swift
//  TwitterClient
//
//  Created by Igor Karyi on 15.04.2018.
//  Copyright © 2018 Igor Karyi. All rights reserved.
//

import UIKit

class User: NSObject {
    
    // stored properties
    var name: String?
    var screenName: String?
    var profileURL: URL?
    var userDescription: String?
    
    var tweets: Int = 0
    var following: Int = 0
    var followers: Int = 0
    
    
    var dictionary: NSDictionary?
    
    // deserialize
    init(dictionary: NSDictionary){
        name = dictionary["name"] as? String
        screenName = dictionary["screen_name"] as? String
        if let profileURLString = dictionary["profile_image_url_https"] as? String {
            profileURL = URL(string: profileURLString)
        }
        userDescription = dictionary["description"] as? String
        // TODO FIx
        tweets = (dictionary["statuses_count"] as? Int) ?? 0
        following = (dictionary["friends_count"] as? Int) ?? 0
        followers = (dictionary["followers_count"] as? Int) ?? 0
        self.dictionary = dictionary
    }
    
    static let userDidLogoutNotification = "UserDidLogout"
    static var _currentUser: User?
    
    // computed property
    class var currentUser: User? {
        get {
            if _currentUser == nil {
                let defaults = UserDefaults.standard
                let userData = defaults.object(forKey: "currentUserData") as? Data
                if let userData = userData {
                    let dictionary = try! JSONSerialization.jsonObject(with: userData, options: []) as! NSDictionary
                    _currentUser = User(dictionary: dictionary)
                }
            }
            return _currentUser
        }
        
        set(user) {
            _currentUser = user
            let defaults = UserDefaults.standard
            if let user = user {
                let data = try! JSONSerialization.data(withJSONObject: user.dictionary!, options: [])
                defaults.set(data, forKey: "currentUserData")
            } else {
                // defaults.removeObject(forKey: "currentUser")
                defaults.set(nil, forKey: "currentUser")
            }
            // saves to disk
            defaults.synchronize()
        }
    }
}
