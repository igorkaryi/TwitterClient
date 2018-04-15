//
//  UserTweetsViewController.swift
//  TwitterClient
//
//  Created by Igor Karyi on 15.04.2018.
//  Copyright © 2018 Igor Karyi. All rights reserved.
//

import UIKit

class UserTweetsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate  {
    
    var tweets: [Tweet]!
    var myUser = String()
    
    var keyHeight = Int()
    var boardHeight = Int()
    
    var countCharacters = 140
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tweetView: UIView!
    @IBOutlet weak var tweetTextView: UITextView!
    @IBOutlet weak var bottomViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var lastCharactersLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tap(gesture:)))
        self.view.addGestureRecognizer(tapGesture)
        
        tweetTextView.delegate = self
        tweetTextView.text = ""
        
        tableView.dataSource = self
        tableView.delegate = self
        
        TwitterClient.sharedInstance?.userTweets(screenName: myUser, success: { (tweets: [Tweet]) -> () in
            self.tweets = tweets
            self.tableView.reloadData()
        }, failure: { (error:Error) -> () in
            print("TVC-viewDidLoad-error: \(error.localizedDescription)")
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bottomViewConstraint.constant = 0
    }
    
    @objc func tap(gesture: UITapGestureRecognizer) {
        print("ererv")
        tweetTextView.resignFirstResponder()
        bottomViewConstraint.constant = 0
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let rect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            print(rect.height)
            var keyboardHeight = rect.height
            
            if #available(iOS 11.0, *) {
                let bottomInset = view.safeAreaInsets.bottom
                keyboardHeight -= bottomInset
            }
            
            boardHeight = Int(keyboardHeight)
            bottomViewConstraint.constant = -CGFloat(self.boardHeight)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        
        // Recognizes enter key in keyboard
        if numberOfChars <= 140 && text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return numberOfChars < 140
    }
    
    func checkRemainingChars() {
        let allowedChars = countCharacters
        let charsInTextView = -tweetTextView.text.count
        let remainingChars = allowedChars + charsInTextView
        if remainingChars <= allowedChars {
            lastCharactersLabel.textColor = UIColor.darkGray
        }
        if remainingChars <= 20 {
            lastCharactersLabel.textColor = UIColor.orange
        }
        if remainingChars <= 10 {
            lastCharactersLabel.textColor = UIColor.red
        }
        lastCharactersLabel.text = String(remainingChars)
        lastCharactersLabel.text = "Осталось \(remainingChars) символов"
    }
    
    func textViewDidChange(_ textView: UITextView) {
        checkRemainingChars()
    }
    
    func sendMyTweet() {
        countCharacters = 140
        self.bottomViewConstraint.constant = -CGFloat(self.boardHeight)
        //self.keyboardViewConstraint.constant = -CGFloat(self.boardHeight)
        print("send tweet - take me back")
        if tweetTextView.hasText {
            TwitterClient.sharedInstance?.tweet(tweet: tweetTextView.text, success: { () -> () in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SendTweet"), object: nil)
            }, failure: { (error: Error) -> () in
                print("tvc-retweet-failure-error: \(error.localizedDescription)")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SendTweet"), object: nil)
            })
        }
    }
    
    @IBAction func sendTweet(_ sender: UIButton) {
        sendMyTweet()
    }
    
    //MARK: ACTIONS
    @IBAction func retweet(_ sender: UIButton) {
        let buttonRow = sender.tag
        let tweet = tweets[buttonRow]
        TwitterClient.sharedInstance?.retweet(tweet: tweet, success: { (updatedTweet: Tweet) -> () in
            tweet.retweetCount = updatedTweet.retweetCount
            if let retweeted = updatedTweet.retweeted {
                tweet.retweeted = retweeted
            }
            self.tableView.reloadData()
        }, failure: { (error: Error) -> () in
            print("tvc-retweet-failure-error: \(error.localizedDescription)")
        })
    }
    
    @IBAction func favorite(_ sender: UIButton) {
        let buttonRow = sender.tag
        let tweet = tweets[buttonRow]
        TwitterClient.sharedInstance?.favorite(tweet: tweet, success: { (updatedTweet: Tweet) -> () in
            tweet.favoritesCount = updatedTweet.favoritesCount
            if let favorited = updatedTweet.favorited {
                tweet.favorited = favorited
            }
            self.tableView.reloadData()
        }, failure: { (error: Error) -> () in
            print("tvc-favorite-failure-error: \(error.localizedDescription)")
        })
    }
    
    @IBAction func onLogoutButton(_ sender: Any) {
        showLogiotAlert()
    }
    
    func showLogiotAlert() {
        // create the alert
        let uiAlert = UIAlertController(title: "Вы действительно хотите выйти?", message: "", preferredStyle: UIAlertControllerStyle.alert)
        self.present(uiAlert, animated: true, completion: nil)
        
        // add an action (YES)
        uiAlert.addAction(UIAlertAction(title: "ДА", style: .default, handler: { action in
            TwitterClient.sharedInstance?.logout()
            print("Click YES button")
        }))
        
        // add an action (cancel)
        uiAlert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { action in
            print("Click of cancel button")
        }))
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let tweets = tweets {
            return tweets.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! TweetCell
        
        cell.selectionStyle = .none
        let tweet = tweets[indexPath.row]
        cell.tweetLabel.text = tweet.text
        if let timeStamp = tweet.timeStamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            cell.timestampLabel.text = formatter.string(from: timeStamp)
        } else {
            cell.timestampLabel.text = ""
        }
        
        if let user = tweet.user, let screenName = user.screenName {
            cell.usernameLabel.text = "@\(screenName)"
            myUser = "\(screenName)"
            if let profileURL = user.profileURL {
                
                cell.viewUserButton.layer.masksToBounds = true
                cell.viewUserButton.layer.cornerRadius = 6.0
                
                let profileImage = try? Data(contentsOf: profileURL)
                if let profileImage = profileImage {
                    cell.viewUserButton.setImage(UIImage(data: profileImage), for: .normal)
                    
                } else {
                    cell.viewUserButton.setImage(UIImage(named: "profile-icon"), for: .normal)
                }
                
            }
        } else {
            cell.usernameLabel.text = ""
        }
        cell.retweetCountLabel.text = "\(tweet.retweetCount)"
        cell.favoriteCountLabel.text = "\(tweet.favoritesCount)"
        cell.favoriteButton.tag = indexPath.row
        cell.retweetButton.tag = indexPath.row
        cell.viewUserButton.tag = indexPath.row
        
        
        if let favorited = tweet.favorited, favorited == true{
            cell.favoriteButton.setImage(UIImage(named: "favor-icon-red"), for: .normal)
        } else {
            cell.favoriteButton.setImage(UIImage(named: "favor-icon"), for: .normal)
            
        }
        if let retweeted = tweet.retweeted, retweeted == true{
            cell.retweetButton.setImage(UIImage(named: "retweet-icon-green"), for: .normal)
        } else {
            cell.retweetButton.setImage(UIImage(named: "retweet-icon"), for: .normal)
        }
        return cell
    }
}
