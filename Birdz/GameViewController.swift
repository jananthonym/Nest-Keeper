//
//  GameViewController.swift
//  Birdz
//
//  Created by Jan Anthony Miranda on 6/30/15.
//  Copyright (c) 2015 Jan Anthony Miranda. All rights reserved.
//

import UIKit
import SpriteKit
import iAd
import GoogleMobileAds
import StoreKit

extension SKNode {
    class func unarchiveFromFile(file : String) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            let sceneData = try! NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
            let archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController, ADInterstitialAdDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    var Scene: SKScene?
    var showedAd = false
    var showedGAd = false
    var retry = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        gInterstitial = createAndLoadAd()
        if !showedAd && !showedGAd {
            if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
                Scene = scene
                // Configure the view.
                let skView = self.originalContentView as! SKView
                //skView.showsFPS = true
                //skView.showsNodeCount = true
                //skView.showsPhysics = true
                /* Sprite Kit applies additional optimizations to improve rendering performance */
                skView.ignoresSiblingOrder = true
                
                /* Set the scale mode to scale to fit the window */
                scene.scaleMode = .ResizeFill
                scene.size = skView.bounds.size
                
                skView.presentScene(scene)
            }
            
            if(SKPaymentQueue.canMakePayments()) {
                print("IAP is enabled, loading")
                let productID:NSSet = NSSet(objects: "nkNoAds")
                let request: SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>)
                request.delegate = self
                request.start()
            } else {
                print("please enable IAPS")
            }
            
            cycleInterstitial()
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "presentInterlude", name: "ad", object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "Pause", name: UIApplicationWillResignActiveNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "Resume", name: UIApplicationWillEnterForegroundNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "Resume", name: UIApplicationDidBecomeActiveNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "btnRemoveAds", name: "removeAd", object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "RestorePurchases", name: "restore", object: nil)

        } else {
            close()
            showedAd = false
            showedGAd = false
        }
    }
    
    func Pause() {
        let skView = self.view as! SKView
        skView.paused = true
    }
    func Resume() {
        let skView = self.view as! SKView
        skView.paused = false
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //iAD interstitial definition with custom placeHolderView and close button
    //you do not need to add anything to interface builder. All is done with code
    
    var interstitial:ADInterstitialAd!
    var placeHolderView:UIView!
    var closeButton:UIButton!
    
    //Full Implemantation of iAD interstitial and delegate methods
    
    func cycleInterstitial(){
        if retry == 3 {
            return
        }
        let defaults1 = NSUserDefaults.standardUserDefaults()
        let ad = defaults1.objectForKey("ad")
        if let Ad = ad as? Bool {
            if !Ad {
                return
            }
        }
        print("getting new interstitial")
        // create a new interstitial. We set the delegate so that we can be notified
        interstitial = ADInterstitialAd()
        interstitial.delegate = self
        
    }
    
    func presentInterlude(){
        let defaults1 = NSUserDefaults.standardUserDefaults()
        let ad = defaults1.objectForKey("ad")
        if let Ad = ad as? Bool {
            if !Ad {
                NSNotificationCenter.defaultCenter().postNotificationName("Start", object: self)
                return
            }
        }
        print("notified")
        // If the interstitial managed to load, then we'll present it now.
        if (interstitial.loaded) {
            showedAd = true
            showedGAd = false
            placeHolderView = UIView(frame: self.view.frame)
            self.view.addSubview(placeHolderView)
            
            closeButton = UIButton(frame: CGRect(x: 5, y:  5, width: 40, height: 40))
            //add a cross shaped graphics into your project to use as close button
            closeButton.setBackgroundImage(UIImage(named: "cross.png"), forState: UIControlState.Normal)
            closeButton.addTarget(self, action: Selector("close"), forControlEvents: UIControlEvents.TouchDown)
            self.view.addSubview(closeButton)
            
            
            interstitial.presentInView(placeHolderView)
        } else if gInterstitial.isReady {
            showedGAd = true
            showedAd = false
            gInterstitial.presentFromRootViewController(self)
            gInterstitial = createAndLoadAd()
            
        } else {
            print("ad not loaded")
            NSNotificationCenter.defaultCenter().postNotificationName("Start", object: self)
            showedGAd = false
            showedAd = false
            cycleInterstitial()
            gInterstitial = createAndLoadAd()
        }
        retry = 0

    }
    
    // iAd Delegate Mehtods
    
    // When this method is invoked, the application should remove the view from the screen and tear it down.
    // The content will be unloaded shortly after this method is called and no new content will be loaded in that view.
    // This may occur either when the user dismisses the interstitial view via the dismiss button or
    // if the content in the view has expired.
    
    func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!){
        print("unload")
        if placeHolderView != nil {
            placeHolderView.removeFromSuperview()
            closeButton.removeFromSuperview()
            //interstitial = nil
        }
        
        cycleInterstitial()
    }
    
    func interstitialAdActionDidFinish(_interstitialAd: ADInterstitialAd!){
        if placeHolderView != nil {
            placeHolderView.removeFromSuperview()
            closeButton.removeFromSuperview()
            cycleInterstitial()
            print("called just before dismissing - action finished", terminator: "")
        }
        
    }
    
    // This method will be invoked when an error has occurred attempting to get advertisement content.
    // The ADError enum lists the possible error codes.
    func interstitialAd(interstitialAd: ADInterstitialAd!,
        didFailWithError error: NSError!){
            print("ad failed")
            retry++
            cycleInterstitial()
    }
    
    
    //Load iAd interstitial
    func dislayiAdInterstitial() {
        //iAd interstitial
        presentInterlude()
    }
    
    
    func close() {
        print("ad closed")
        NSNotificationCenter.defaultCenter().postNotificationName("Start", object: self)
        if !showedGAd {
            placeHolderView.removeFromSuperview()
            closeButton.removeFromSuperview()
            interstitial = nil
            cycleInterstitial()
        }
    }
    
    // ADMob ///////////////////////////////////////////////////////////////////////////////////////
    var gInterstitial: GADInterstitial!
    
    func createAndLoadAd() -> GADInterstitial {
        
        let ad = GADInterstitial(adUnitID: "ca-app-pub-4409172322766542/2932606913")
        
        let request = GADRequest()
        
        //request.testDevices = ["2077ef9a63d2b398840261c8221a0c9b"]
        ad.loadRequest(request)
        
        return ad
    }
    var list = [SKProduct]()
    var p = SKProduct()
    
    // 2
    func btnRemoveAds() {
        if !list.isEmpty {
            print("buying")
            for product in list {
                let prodID = product.productIdentifier
                if(prodID == "nkNoAds") {
                    p = product
                    buyProduct()
                    break;
                }
            }
        } else if(SKPaymentQueue.canMakePayments()) {
            NSNotificationCenter.defaultCenter().postNotificationName("error", object: self)
            print("IAP is enabled, loading")
            let productID:NSSet = NSSet(objects: "nkNoAds")
            let request: SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>)
            request.delegate = self
            request.start()
        } else {
            print("please enable IAPS")
            NSNotificationCenter.defaultCenter().postNotificationName("error", object: self)
        }
    }
    
    
    // 4
    func removeAds() {
        print("ads removed")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "ad", object: nil)
        if let s = Scene as? GameScene {
            s.adBtn.hidden = true
            s.restoreBtn.hidden = true
            s.showAd = false
        }
        let defaults1 = NSUserDefaults.standardUserDefaults()
        defaults1.setBool(false, forKey: "ad")
    }
    
    
    // 6
    func RestorePurchases() {
        print("restore")
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    // 2
    func buyProduct() {
        print("buy " + p.productIdentifier)
        let pay = SKPayment(product: p)
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        SKPaymentQueue.defaultQueue().addPayment(pay as SKPayment)
    }
    
    //3
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        print("product request")
        let myProduct = response.products
        
        for product in myProduct {
            print("product added")
            print(product.productIdentifier)
            print(product.localizedTitle)
            print(product.localizedDescription)
            //println(String(product.price))
            
            list.append(product )
        }
    }
    
    // 4
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        print("transactions restored")
        
        var purchasedItemIDS = []
        for transaction in queue.transactions {
            let t: SKPaymentTransaction = transaction 
            
            let prodID = t.payment.productIdentifier as String
            
            switch prodID {
            case "nkNoAds":
                print("remove ads")
                removeAds()
            default:
                print("IAP not setup")
            }
            
        }
    }
    
    // 5
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("paymentQueue")
        
        for transaction:AnyObject in transactions {
            let trans = transaction as! SKPaymentTransaction
            print(trans.error)
            
            switch trans.transactionState {
                
            case .Purchased:
                print("purchased")
                //println(p.productIdentifier)
                
                /*let prodID = p.productIdentifier as String
                switch prodID {
                case "dgeNoAds":
                println("remove ads")
                removeAds()
                default:
                println("IAP not setup")
                }*/
                print("remove ads")
                removeAds()
                
                queue.finishTransaction(trans)
            case .Restored:
                print("restored")
                
                /*let prodID = p.productIdentifier as String
                switch prodID {
                case "dgeNoAds":
                println("remove ads")
                removeAds()
                default:
                println("IAP not setup")
                }*/
                print("remove ads")
                removeAds()
                
                queue.finishTransaction(trans)
            case .Failed:
                print("buy error")
                NSNotificationCenter.defaultCenter().postNotificationName("error", object: self)
                queue.finishTransaction(trans)
            default:
                print("default")
                
            }
        }
    }
}
