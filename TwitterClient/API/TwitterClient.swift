//
//  TwitterClient.swift
//  TwitterClient
//
//  Created by Igor Karyi on 15.04.2018.
//  Copyright © 2018 Igor Karyi. All rights reserved.
//

import UIKit
import BDBOAuth1Manager

class TwitterClient: BDBOAuth1SessionManager {
    
    static let sharedInstance = TwitterClient(baseURL: URL(string: "https://api.twitter.com"), consumerKey: "DI7JNMTTJl6nJv14dJNdYYhTf", consumerSecret: "dyjkimzK7M8okfyX98uF8VlWMODmpzD1ENk6ZAOwhx5yMGJMfp")
    
    var loginSuccess: (() -> ())?
    var loginFailure: ((Error) -> ())?
    
    var myCount = Int()
    
    @objc func catchNotification(notification:Notification) -> Void {
        guard let count = notification.userInfo!["count"] else { return }
        myCount = count as! Int
    }
    
    func homeTimeline(success: @escaping ([Tweet]) -> (), failure: @escaping (Error) -> ()){
        let params = ["count": myCount]
        
        NotificationCenter.default.addObserver(self, selector: #selector(catchNotification(notification:)), name: NSNotification.Name(rawValue: "myNotificationKey"), object: nil)
        
        get("1.1/statuses/home_timeline.json", parameters: params, progress: nil, success: { (task: URLSessionDataTask, response: Any?) -> Void in
            let dictionaries = response as! [NSDictionary]
            let tweets = Tweet.tweetsWithArray(dictionaries: dictionaries)
            
            success(tweets)
        }, failure: { (task: URLSessionDataTask?, error: Error) in
            failure(error)
        })
    }
    
    func userTweets(screenName: String, success: @escaping ([Tweet]) -> (), failure: @escaping (Error) -> ()){
        get("1.1/statuses/user_timeline.json?id=\(screenName)", parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) -> Void in
            let dictionaries = response as! [NSDictionary]
            let tweets = Tweet.tweetsWithArray(dictionaries: dictionaries)
            
            success(tweets)
        }, failure: { (task: URLSessionDataTask?, error: Error) in
            failure(error)
        })
    }
    
    func retweet(tweet: Tweet, success: @escaping (Tweet) -> (), failure: @escaping (Error) -> ()) {
        if let retweeted = tweet.retweeted {
            if retweeted != true {
                post("1.1/statuses/retweet/\(tweet.id!).json", parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) -> Void in
                    let updatedTweet = Tweet(dictionary: response as! NSDictionary)

                    success(updatedTweet)
                }, failure: { (task: URLSessionDataTask?, error: Error) in
                    print ("tc-retweet-postRetweet-error: \(error.localizedDescription)")
                })
            } else {
                post("1.1/statuses/unretweet/\(tweet.id!).json", parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) -> Void in
                    let updatedTweet = Tweet(dictionary: response as! NSDictionary)

                    success(updatedTweet)
                }, failure: { (task: URLSessionDataTask?, error: Error) in
                    print ("tc-retweet-postUnretweet-error: \(error.localizedDescription)")
                })
            }
        }
    }
    
    func favorite(tweet: Tweet, success: @escaping (Tweet) -> (), failure: @escaping (Error) -> ()) {
        if let favorited = tweet.favorited {
            if favorited != true {
                post("1.1/favorites/create.json?id=\(tweet.id!)", parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) -> Void in
                    let updatedTweet = Tweet(dictionary: response as! NSDictionary)
                    success(updatedTweet)
                }, failure: { (task: URLSessionDataTask?, error: Error) in
                    print ("error: \(error.localizedDescription)")
                })
            } else {
                post("1.1/favorites/destroy.json?id=\(tweet.id!)", parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) -> Void in
                    let updatedTweet = Tweet(dictionary: response as! NSDictionary)
                    success(updatedTweet)
                }, failure: { (task: URLSessionDataTask?, error: Error) in
                    print ("error: \(error.localizedDescription)")
                })
            }
        }
    }
    
    func login(success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        loginSuccess = success
        loginFailure = failure
        
        // clears keychain of any previous session one might have
        TwitterClient.sharedInstance?.deauthorize()
        
        // fetch request token
        TwitterClient.sharedInstance?.fetchRequestToken(withPath: "oauth/request_token", method: "GET", callbackURL: URL(string: "iktwitterclient://oauth"), scope: nil, success: { (requestToken: BDBOAuth1Credential?) in
            if let requestToken = requestToken, let token = requestToken.token, let url = URL(string: "https://api.twitter.com/oauth/authorize?oauth_token=\(token)") {
                UIApplication.shared.openURL(url)
            }
        }, failure: { (error: Error?) in
            if let error = error {
                print ("login-error: \(error.localizedDescription)")
                self.loginFailure?(error)
            }
        })
    }
    
    func tweet(tweet: String, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        post(("1.1/statuses/update.json?status=\(tweet)").addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!, parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) -> Void in
            print(response as! NSDictionary)
            success()
        }, failure: { (task: URLSessionDataTask?, error: Error) in
            print ("error: \(error.localizedDescription)")
            failure(error)
        })
    }
    func replyToTweet(tweet: String, inReplyToStatusId: String, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        post(("1.1/statuses/update.json?status=\(tweet)&in_reply_to_status_id=\(inReplyToStatusId)").addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!, parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) -> Void in
            print(response as! NSDictionary)
            success()
        }, failure: { (task: URLSessionDataTask?, error: Error) in
            print ("error: \(error.localizedDescription)")
            failure(error)
        })
    }
    
    func logout() {
        User.currentUser = nil
        deauthorize()
        NotificationCenter.default.post(name: Notification.Name(rawValue: User.userDidLogoutNotification), object: nil)
    }
    
    func handleOpenURL(url: URL){
        let requestToken = BDBOAuth1Credential(queryString: url.query)
        fetchAccessToken(withPath: "oauth/access_token", method: "POST", requestToken: requestToken, success: { (accessToken: BDBOAuth1Credential?) in
            self.currentAccount(success: { (user: User) in
                // calls setter
                User.currentUser = user
                
                self.loginSuccess?()
            }, failure: { (error: Error) in
                self.loginFailure?(error)
            })
        }, failure: { (error: Error?) in
            if let error = error {
                print("handleOpenURL-error: \(error.localizedDescription)")
                self.loginFailure?(error)
            }
        })
    }
    
    func currentAccount(success: @escaping (User) -> (), failure: @escaping (Error) -> ()) {
        get("1.1/account/verify_credentials.json", parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) -> Void in
            let userDictionary = response as! NSDictionary
            let user = User(dictionary: userDictionary)
            success(user)
        }, failure: { (task: URLSessionDataTask?, error: Error) in
            failure(error)
        })
    }
}
