//
//  TweetTableViewController.swift
//  Smashtag
//
//  Created by CS193p Instructor.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit
import Twitter

class TweetTableViewController: UITableViewController, UITextFieldDelegate
{
    // MARK: Model

    var tweets = [Array<Twitter.Tweet>](){
        didSet {
            tableView.reloadData()
        }
    }
   
    var searchText: String? = RecentSearches.searches.first ?? "#stanford"{
        didSet {
            lastTwitterRequest = nil
            searchTextField?.text = searchText
            tweets.removeAll()
            searchForTweets()
            title = searchText
            RecentSearches.add(searchText!)
        }
    }
    
    // MARK: Fetching Tweets
    
    private var twitterRequest: Twitter.Request? {
        if lastTwitterRequest == nil {
            if let query = searchText where !query.isEmpty {
                return Twitter.Request(search: query + " -filter:retweets", count: 100)
            }
        }
        return lastTwitterRequest?.requestForNewer
    }
    
    private var lastTwitterRequest: Twitter.Request?

    @IBAction private func searchForTweets(sender: UIRefreshControl?)
    {
        if let request = twitterRequest {
            lastTwitterRequest = request
            request.fetchTweets { [weak weakSelf = self] newTweets in
                dispatch_async(dispatch_get_main_queue()) {
                    if request == weakSelf?.lastTwitterRequest {
                        if !newTweets.isEmpty {
                            weakSelf?.tweets.insert(newTweets, atIndex: 0)
                             weakSelf?.tableView.reloadData()
                            sender?.endRefreshing()
                            }
                    }
                    sender?.endRefreshing()
                }
            }
        } else {
            sender?.endRefreshing()
        }
    }
    
    
    private func searchForTweets () {
        refreshControl?.beginRefreshing()
        searchForTweets(refreshControl)
    }
    
    // MARK: UITableViewDataSource

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(tweets.count - section)"
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tweets.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets[section].count
    }
    
    // MARK: Constants
    
    private struct Storyboard {
        static let TweetCellIdentifier = "Tweet"
        static let MentionsIdentifier = "Show Mentions"
         static let ImagesIdentifier = "Show Images"
    }

    override func tableView(tableView: UITableView,
                            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.TweetCellIdentifier,
                                                                       forIndexPath: indexPath)

        let tweet = tweets[indexPath.section][indexPath.row]
        
        if let tweetCell = cell as? TweetTableViewCell {
            tweetCell.tweet = tweet
        }
    
        return cell
    }
    
    
    // MARK: Outlets

    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
            searchTextField.text = searchText
        }
    }
    
    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchText = textField.text
        return true
    }
    
    // MARK: View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if tweets.count == 0 {
            searchForTweets()
        }
        if RecentSearches.searches.first == nil {
            RecentSearches.add(searchText!)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //------- Stop Button--------
        let imageButton = UIBarButtonItem(barButtonSystemItem: .Camera,
                          target: self,
                          action: #selector(TweetTableViewController.showImages(_:)))
        navigationItem.rightBarButtonItems = [imageButton]
        if navigationController?.viewControllers.count > 1 {
            
            let stopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop,
                            target: self,
                            action: #selector(TweetTableViewController.toRootViewController(_:)))

            if let rightBarButtonItem = navigationItem.rightBarButtonItem {
                navigationItem.rightBarButtonItems = [stopBarButtonItem, rightBarButtonItem]
            } else {
                navigationItem.rightBarButtonItem = stopBarButtonItem
            }
        }
        //-----------
    }
    
    func toRootViewController(sender: UIBarButtonItem) {
        navigationController?.popToRootViewControllerAnimated(true)
     
    }
    
    func showImages(sender: UIBarButtonItem) {
        performSegueWithIdentifier(Storyboard.ImagesIdentifier, sender: sender)
    }

    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String?,
                                                   sender: AnyObject?) -> Bool {
        if identifier == Storyboard.MentionsIdentifier {
            if let tweetCell = sender as? TweetTableViewCell {
                if tweetCell.tweet!.hashtags.count + tweetCell.tweet!.urls.count +
                   tweetCell.tweet!.userMentions.count +
                   tweetCell.tweet!.media.count == 0 {
                    return false
                }
            }
        }
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if identifier == Storyboard.MentionsIdentifier,
                let mtvc = segue.destinationViewController as? MentionsTableViewController,
                let tweetCell = sender as? TweetTableViewCell {
                mtvc.tweet = tweetCell.tweet
                
            } else if identifier == Storyboard.ImagesIdentifier {
                if let icvc = segue.destinationViewController as? ImageCollectionViewController {
                    icvc.tweets = tweets
                    icvc.title = "Images: \(searchText!)"
                }
            }
        }
    }
}
