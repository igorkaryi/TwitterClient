//
//  Tweet.swift
//  TwitterClient
//
//  Created by Igor Karyi on 15.04.2018.
//  Copyright © 2018 Igor Karyi. All rights reserved.
//

import UIKit

class Tweet: NSObject {
    
    // stored properties
    var text: String?
    var timeStamp: Date?
    var retweetCount: Int = 0
    var favoritesCount: Int = 0
    var user: User?
    var id: String?
    var favorited: Bool?
    var retweeted: Bool?
    
    
    init(dictionary: NSDictionary){
        text = dictionary["text"] as? String
        if let timeStampString = dictionary["created_at"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE MMM d HH:mm:ss Z y"
            timeStamp = formatter.date(from: timeStampString)
        }
        //print("here is a tweet: ")
        //print(dictionary)
        retweetCount = (dictionary["retweet_count"] as? Int) ?? 0
        favoritesCount = (dictionary["favorite_count"] as? Int) ?? 0
        user = User(dictionary: (dictionary["user"] as! NSDictionary))
        id = dictionary["id_str"] as? String
        favorited = dictionary["favorited"] as? Bool
        retweeted = dictionary["retweeted"] as? Bool
    }
    
    class func tweetsWithArray(dictionaries: [NSDictionary]) -> [Tweet] {
        var tweets = [Tweet]()
        for dictionary in dictionaries{
            tweets.append(Tweet(dictionary: dictionary))
        }
        return tweets
    }
}
