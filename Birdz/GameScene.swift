//
//  GameScene.swift
//  Birdz
//
//  Created by Jan Anthony Miranda on 6/30/15.
//  Copyright (c) 2015 Jan Anthony Miranda. All rights reserved.
//

import SpriteKit
import GameKit
import iAd
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate, GKGameCenterControllerDelegate, ADBannerViewDelegate {
    
    var UIiAd: ADBannerView = ADBannerView()
    
    //labels/buttons
    let scoreLabel = SKLabelNode(fontNamed: "AppleSpice")
    let bestScoreLabel = SKLabelNode(fontNamed: "AppleSpice")
    
    let endGameLabel = SKSpriteNode(imageNamed: "gameOver.png")
    let pauseCountLabel = SKLabelNode(fontNamed: "AppleSpice")
    let guide = SKLabelNode(fontNamed: "AppleSpice")
    
    //buttons
    let playBtn = SKSpriteNode(imageNamed: "startBtn.png")
    let scoreBtn = SKSpriteNode(imageNamed: "scoreBtn.png")
    let pauseBtn = SKSpriteNode(imageNamed: "pauseBtn.png")
    let soundBtn = SKSpriteNode(imageNamed: "soundTrue.png")
    let homeBtn = SKSpriteNode(imageNamed: "homeBtn.png")
    let endBtn = SKSpriteNode(imageNamed: "endBtn.png")
    let adBtn = SKSpriteNode(imageNamed: "adBtn.png")
    let restoreBtn = SKSpriteNode(imageNamed: "restoreBtn.png")
    
    let waves = SKSpriteNode(imageNamed: "wavesBtn.png")
    let contin = SKSpriteNode(imageNamed: "continBtn.png")
    
    let scoreBox = SKSpriteNode(imageNamed: "scoreBox.png")
    let bestBox = SKSpriteNode(imageNamed: "bestBox.png")
    
    //node containg sprites
    let gameNode = SKSpriteNode()
    
    //home
    var home1: SKSpriteNode?
    var home2: SKSpriteNode?
    var home3: SKSpriteNode?
    var home4: SKSpriteNode?
    var home5: SKSpriteNode?
    
    var started = false
    var pause = false
    var pause2 = false
    var stopped: Bool = false
    var waiting = false
    var pauseCounter = -1
    
    var score = 0
    var endScore = 0
    
    var movingBird: Bird?
    
    //timer
    var birdSpawnTimer: NSTimeInterval = 0
    var dt: NSTimeInterval = 0.0
    var lastUpdateTime: NSTimeInterval = 0
    var scoreTimer: NSTimeInterval = 0
    var cloudTimer: NSTimeInterval = 0
    var resumeTimer: NSTimeInterval = 0
    
    var lastSpawn = 0
    var isSpawned = false
    
    var birdSpeedInitial: CGFloat = 55
    var birdSpeedFinal: CGFloat = 110
    var birdSpeedIncrease: CGFloat = 0
    var minSpawnInterval: Double = 0
    
    var life1: SKSpriteNode?
    var life2: SKSpriteNode?
    var life3: SKSpriteNode?
    var life4: SKSpriteNode?
    var life5: SKSpriteNode?
    var lives = 5
    
    let BG = SKSpriteNode(imageNamed: "start.png")
    let bird = SKSpriteNode(imageNamed: "startBird.png")
    let pauseBg = SKSpriteNode(imageNamed: "bg.png")
    
    var mode = 0
    var play = true
    
    var birdSpawnInterval: Double = 0;
    
    var second = false
    
    var touching = false
    var scoreHeight: CGFloat = 0
    
    var hasAd = false
    var showAd = true
    
    override func didMoveToView(view: SKView) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions:AVAudioSessionCategoryOptions.DefaultToSpeaker)
        } catch _ {
        }
        setUpScene()
        self.addChild(gameNode)
        gameNode.position = CGPointMake(0, 0)
        gameNode.size = self.frame.size
        
        self.physicsWorld.gravity = CGVectorMake(0.0, -10)
        self.physicsWorld.contactDelegate = self
        
        authenticatePlayer()
        loadAd(true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "Pause", name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "Start", name: "Start", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "error", name: "error", object: nil)
    }
    
    func error() {
        print("err")
        let err = SKLabelNode(fontNamed: "AppleSpice")
        err.fontSize = self.frame.size.height * 30/320
        err.text = "iTunes Store Connection Error"
        err.fontColor = UIColor.blackColor()
        err.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        err.zPosition = 300
        err.alpha = 0
        let action = SKAction.sequence([SKAction.fadeInWithDuration(0.2), SKAction.waitForDuration(2), SKAction.fadeOutWithDuration(0.2), SKAction.removeFromParent()])
        err.runAction(action)
        self.addChild(err)
    }
    
    func Start() {
        if waiting {
            started = true
            placeLives()
            placeNests()

            let fade = SKAction.fadeOutWithDuration(1)
            guide.runAction(SKAction.sequence([SKAction.waitForDuration(2), fade, SKAction.removeFromParent()]))
            guide.removeFromParent()
            self.addChild(guide)
        }
    }
    
    func setUpScene(){
        pauseBtn.texture = SKTexture(imageNamed: "pauseBtn.png")
        playBtn.position = CGPointMake(self.frame.size.width/2 - playBtn.size.width, self.frame.size.height/7)
        self.addChild(playBtn)
        
        scoreBtn.position = CGPointMake(self.frame.size.width/2 + playBtn.size.width, self.frame.size.height/7)
        self.addChild(scoreBtn)
        
        waves.position = CGPointMake(self.frame.size.width/2 - playBtn.size.width - self.frame.size.width, self.frame.size.height/7)
        self.addChild(waves)
        
        contin.position = CGPointMake(self.frame.size.width/2 + playBtn.size.width - self.frame.size.width, self.frame.size.height/7)
        self.addChild(contin)
        
        adBtn.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/7 + adBtn.size.height/2)
        restoreBtn.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/7 - adBtn.size.height/2)
        adBtn.zPosition = 50
        let defaults1 = NSUserDefaults.standardUserDefaults()
        let ad = defaults1.objectForKey("ad")
        if let Ad = ad as? Bool {
            if Ad {
                self.addChild(adBtn)
                self.addChild(restoreBtn)
            }
        } else {
            self.addChild(adBtn)
            self.addChild(restoreBtn)
        }
        waiting = false
        
        score = 0
        endScore = 0
        
        started = false
        pause = false
        pause2 = false
        stopped = false
        waiting = false
        pauseCounter = -1
        
        birdSpawnTimer = 0
        dt = 0
        lastUpdateTime = 0
        scoreTimer = 0
        cloudTimer = 0
        resumeTimer = 0
        
        birdSpeedIncrease = 0
        
        lastSpawn = 1
        
        lives = 5
        
        mode = 0
        play = true
        
        birdSpawnInterval = 3.5
        
        second = false
        
        touching = false
        
        guide.fontSize = self.frame.size.height * 20/320
        guide.text = "Guide the Birds Back to their Nests"
        guide.zPosition = 99
        guide.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        
        pauseCountLabel.fontColor = UIColor.whiteColor()
        pauseCountLabel.fontSize = 70
        pauseCountLabel.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        pauseCountLabel.zPosition = 202
        
        birdSpeedInitial = self.frame.height * (50/320)
        birdSpeedFinal = self.frame.width * (250/480)
        minSpawnInterval = 1.4 + Double(self.frame.size.height) * (0.2/320)
        print("min \(minSpawnInterval)")
        
        BG.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        BG.zPosition = -10
        BG.size = self.frame.size
        self.addChild(BG)
        
        bird.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        bird.zPosition = 10
        bird.xScale = 0.8
        bird.yScale = 0.8
        let action = SKAction.repeatActionForever(SKAction.sequence([SKAction.moveToY(bird.position.y + 2, duration: 0.3), SKAction.moveToY(bird.position.y - 2, duration: 0.3)]))
        bird.runAction(action)
        self.addChild(bird)
    }
    
    func Pause() {
        if started && !pause && !stopped {
            print("pausing")
            pauseBtn.texture = SKTexture(imageNamed: "resumeBtn.png")
            
            pauseBg.size = self.size
            pauseBg.zPosition = 201
            pauseBg.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2)
            pauseBg.alpha = 0
            let act = SKAction.fadeAlphaTo(0.8, duration: 0.3)
            pauseBg.runAction(act)
            self.addChild(pauseBg)
            
            gameNode.paused = true
            pause = true
            //sound?.pause()
            pause2 = true
            dt = 0.0
            
            endBtn.position = CGPointMake(self.frame.size.width/2, -endBtn.size.height)
            endBtn.zPosition = 202
            let upAction = SKAction.moveToY(self.frame.size.height/2, duration: 0.3)
            endBtn.runAction(upAction)
            self.addChild(endBtn)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if touching {
            //return
        }
        touching = true

        for touch in (touches ) {
            let location = touch.locationInNode(self)
            
            if started && !stopped && !paused {

                let node = nodeAtPoint(location)
                
                if let bird = node as? Bird {
                    //let bird = node as! Bird
                    bird.clearWayPoints()
                    bird.addPoint(location)
                    movingBird = bird
                }
                //}
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in (touches ) {
            let location = touch.locationInNode(self)
            if let bird = movingBird {
                if !bird.dead {
                    bird.addPoint(location)
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        touching = false
        movingBird = nil
        for touch in (touches ) {
            let location = touch.locationInNode(self)
            let prev = touch.previousLocationInNode(self)
            if(!started && playBtn.containsPoint(location)) {
                play = true
                let action = SKAction.moveByX(self.frame.size.width, y: 0, duration: 0.2)
                playBtn.runAction(action)
                scoreBtn.runAction(action)
                contin.runAction(action)
                waves.runAction(action)
                second = true
            } else if(!started && (waves.containsPoint(location) || contin.containsPoint(location))){
                if contin.containsPoint(location) {
                    mode = 1
                } else {
                    mode = 0
                }
                if play {
                    waiting = true
                    /*var defaults1 = NSUserDefaults.standardUserDefaults()
                    var ad = defaults1.objectForKey("ad")
                    if let Ad = ad as? Bool {
                        if !Ad {
                            Start()
                        }
                    }*/
                    Start()
                    //NSNotificationCenter.defaultCenter().postNotificationName("ad", object: self)
                    //remove start label
                    scoreBtn.removeFromParent()
                    playBtn.removeFromParent()
                    BG.removeFromParent()
                    bird.removeAllActions()
                    bird.removeFromParent()
                    contin.removeFromParent()
                    waves.removeFromParent()
                    adBtn.removeFromParent()
                    restoreBtn.removeFromParent()
                    /*for node in self.children {
                    node.removeFromParent()
                    }*/
                    
                    pauseBtn.xScale = 0.8
                    pauseBtn.yScale = 0.8
                    pauseBtn.position = CGPointMake(pauseBtn.size.width/2, self.frame.size.height - pauseBtn.size.height/2)
                    pauseBtn.zPosition = 202
                    self.addChild(pauseBtn)
                    
                    soundBtn.zPosition = 202
                    soundBtn.xScale = 0.8
                    soundBtn.yScale = 0.8
                    soundBtn.position = CGPointMake(self.frame.size.width - soundBtn.size.width/2, self.frame.size.height - soundBtn.size.width/2)
                    gameNode.addChild(soundBtn)
                    
                    let defaults = NSUserDefaults.standardUserDefaults()
                    let ssound = defaults.boolForKey("sound")
                    if !ssound {
                        soundBtn.texture = SKTexture(imageNamed: "soundFalse.png")
                    }
                    
                    scoreLabel.fontSize = self.frame.size.height * 30/320
                    scoreLabel.position = CGPointMake(self.frame.width/2, self.frame.size.height - scoreLabel.fontSize)
                    scoreLabel.text = String(score)
                    scoreLabel.fontColor = UIColor.whiteColor()
                    gameNode.addChild(scoreLabel)
                    
                    //placeNests()
                    //placeLives()
                    let bg = SKSpriteNode(imageNamed: "bg.png")
                    bg.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
                    bg.size = self.frame.size
                    bg.zPosition = -110
                    gameNode.addChild(bg)
                } else {
                    showLeader()
                    let action = SKAction.moveByX(-self.frame.size.width, y: 0, duration: 0.2)
                    playBtn.runAction(action)
                    scoreBtn.runAction(action)
                    contin.runAction(action)
                    waves.runAction(action)
                    second = false
                }
            } else if started && !stopped {
                if pauseBtn.containsPoint(location) && pauseBtn.containsPoint(prev) {
                    if(!pause){ //pause
                        pauseBtn.texture = SKTexture(imageNamed: "resumeBtn.png")
                        gameNode.paused = true
                        pause = true
                        //sound?.pause()
                        
                        pauseBg.size = self.size
                        pauseBg.zPosition = 201
                        pauseBg.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2)
                        pauseBg.alpha = 0
                        let act = SKAction.fadeAlphaTo(0.8, duration: 0.3)
                        pauseBg.runAction(act)
                        self.addChild(pauseBg)
                        
                        endBtn.position = CGPointMake(self.frame.size.width/2, -endBtn.size.height)
                        endBtn.zPosition = 202
                        let upAction = SKAction.moveToY(self.frame.size.height/2, duration: 0.3)
                        endBtn.runAction(upAction)
                        self.addChild(endBtn)
                        //NSNotificationCenter.defaultCenter().postNotificationName("pauseAdShow", object: self)
                    }else if pauseCounter == -1 { //unpause
                        self.addChild(pauseCountLabel)
                        
                        endBtn.removeAllActions()
                        endBtn.removeFromParent()
                        
                        pauseCounter = 3
                        
                    }
                }
                if soundBtn.containsPoint(location) {
                    let defaults = NSUserDefaults.standardUserDefaults()
                    let ssound = defaults.boolForKey("sound")
                    if !ssound {
                        soundBtn.texture = SKTexture(imageNamed: "soundTrue.png")
                        defaults.setBool(true, forKey: "sound")
                        //playSound()
                    } else {
                        soundBtn.texture = SKTexture(imageNamed: "soundFalse.png")
                        //sound?.stop()
                        defaults.setBool(false, forKey: "sound")
                    }
                }
            }else if(stopped){
                if homeBtn.containsPoint(location) {
                    for node in gameNode.children {
                        node.removeFromParent()
                    }
                    setUpScene()
                    NSNotificationCenter.defaultCenter().postNotificationName("ad", object: self)
                    
                }
            }else if scoreBtn.containsPoint(location) {
                play = false
                //showLeader()
                let action = SKAction.moveByX(self.frame.size.width, y: 0, duration: 0.2)
                playBtn.runAction(action)
                scoreBtn.runAction(action)
                contin.runAction(action)
                waves.runAction(action)
                second = true
            } else if second {
                let action = SKAction.moveByX(-self.frame.size.width, y: 0, duration: 0.2)
                playBtn.runAction(action)
                scoreBtn.runAction(action)
                contin.runAction(action)
                waves.runAction(action)
                second = false
            } else if adBtn.containsPoint(location) {
                NSNotificationCenter.defaultCenter().postNotificationName("removeAd", object: self)
            } else if restoreBtn.containsPoint(location) {
                NSNotificationCenter.defaultCenter().postNotificationName("restore", object: self)
            }
            if pause && endBtn.containsPoint(location) {
                //NSNotificationCenter.defaultCenter().postNotificationName("pauseAdRemove", object: self)
                removeAd(true)
                print("restart \(score)")
                pause = false
                gameNode.paused = false
                endBtn.removeAllActions()
                endBtn.removeFromParent()
                pauseBg.removeFromParent()
                endGame()
            }
            
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        if pause && hasAd && showAd {
            print("showing ad")
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(1)
            UIiAd.alpha = 1
            UIView.commitAnimations()
            hasAd = false
        }
        if stopped && fabs(scoreLabel.position.y - scoreHeight) < 2 && endScore < score {
            if currentTime - scoreTimer > 0.01 {
                scoreTimer = currentTime
                scoreLabel.text = String(++endScore)
            }
        }
        if started && !pause && !stopped {
            drawLines()
            if !pause2 {
                dt = currentTime - lastUpdateTime
            }else{
                pause2 = false
            }
            lastUpdateTime = currentTime
            
            gameNode.enumerateChildNodesWithName("bird", usingBlock: {node, stop in
                let bird = node as! Bird
                bird.move(self.dt)
                
            })
            
            //spawn birds
            if mode == 0 {
                if !isSpawned {
                    spawnBirds()
                    isSpawned = true
                }else{
                    isSpawned = false
                    gameNode.enumerateChildNodesWithName("bird", usingBlock: {node, stop in
                        let bird = node as! Bird
                        if bird.frame.intersects(self.frame) {
                            self.isSpawned = true
                        }
                    })
                }
            } else {
                if currentTime - birdSpawnTimer > birdSpawnInterval {
                    spawnBirds()
                    print(String(stringInterpolationSegment: birdSpawnInterval))
                    birdSpawnTimer = currentTime
                    if birdSpawnInterval > minSpawnInterval {
                        birdSpawnInterval -= 0.015 + Double(self.frame.size.height) * (0.010/320)
                    }
                }
            }
            
            //clouds
            if currentTime - cloudTimer > 3 {
                cloudTimer = currentTime
                spawnCloud()
            }
        } else if pause {
            if !pause2 {
                dt = currentTime - lastUpdateTime
                pause2 = true
            }
            if pauseCounter != -1 && currentTime - resumeTimer > 1 {
                resumeTimer = currentTime
                
                if pauseCounter == 0 {
                    
                    pauseCounter--
                    pauseBtn.texture = SKTexture(imageNamed: "pauseBtn.png")
                    gameNode.paused = false
                    pause = false
                    pauseBg.removeAllActions()
                    pauseBg.removeFromParent()
                    //playSound()
                    pauseCountLabel.removeFromParent()
                    removeAd(true)
                } else {
                    pauseCountLabel.text = String(pauseCounter--)
                }
            }
        }
        
    }
    
    func spawnCloud() {
        let should = Int(arc4random_uniform(3))
        if should == 1 || should == 2 {
            let which = Int(arc4random_uniform(4)) + 1
            let cloud = SKSpriteNode(imageNamed: "cloud\(which).png")
            switch Int(arc4random_uniform(3)) {
            case 0:
                cloud.position = CGPointMake(self.frame.size.width + cloud.size.width/2, self.frame.size.height/1.2)
            case 1:
                cloud.position = CGPointMake(self.frame.size.width + cloud.size.width/2, self.frame.size.height/2 )
            case 2:
                cloud.position = CGPointMake(self.frame.size.width + cloud.size.width/2, self.frame.size.height/5)
            default:
                cloud.position = CGPointMake(self.frame.size.width + 100, self.frame.size.height/2 - 100)
            }
            
            cloud.zPosition = -10
            if Int(arc4random_uniform(2)) == 0 {
                cloud.xScale = -cloud.xScale
            }
            //cloud.xScale = 0.5
            //cloud.yScale = 0.5
            let action = SKAction.moveToX(-cloud.size.width/2, duration: Double(self.frame.size.width) * (10/480))
            let sequence = SKAction.sequence([action, SKAction.removeFromParent()])
            cloud.runAction(sequence)
            gameNode.addChild(cloud)
        }
        
    }
    
    func incrementScore() {
        score++
        scoreLabel.text = String(score)
        
        let defaults1 = NSUserDefaults.standardUserDefaults()
        let ssound = defaults1.boolForKey("sound")
        if ssound {
            self.runAction(SKAction.playSoundFileNamed("home.mp3", waitForCompletion: false))
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        //1
        let firstNode = contact.bodyA.node;
        let secondNode = contact.bodyB.node;
        
        let a = firstNode as! Bird
        let b = secondNode as! Bird
        if a.removing || b.removing || a.dead || b.dead {
            return
        }
        a.dead = true
        b.dead = true
        
        a.clearWayPoints()
        b.clearWayPoints()
        
        a.physicsBody?.dynamic=true
        a.physicsBody?.applyImpulse(CGVectorMake(0, 10))
        a.physicsBody?.affectedByGravity = true
        
        b.physicsBody?.dynamic=true
        b.physicsBody?.applyImpulse(CGVectorMake(0, 10))
        b.physicsBody?.affectedByGravity = true
        
        removeLife()
    }
    
    func spawnBirds() {
        if mode == 1{
            let speed = 20 + self.frame.size.height * (5/320)
            let side = Int(arc4random_uniform(4))
            switch side {
            case 0:
                leftSpawn(speed)
            case 1:
                rightSpawn(speed)
            case 2:
                upSpawn(speed)
            case 3:
                downSpawn(speed)
            default:
                leftSpawn(speed)
            }
        } else {
            var speed = birdSpeedInitial + birdSpeedIncrease
            if speed > birdSpeedFinal {
                speed = birdSpeedFinal
            }
            birdSpeedIncrease += 3 + self.frame.size.width *  (1/480)
            print(speed)
            switch lastSpawn {
            case 0:
                diagonalSpawn(speed)
            case 1:
                arrowSpawn(speed)
            case 2:
                diagonalSpawn2(speed)
            case 3:
                arrowSpawn2(speed)
            default:
                arrowSpawn(speed)
            }
            lastSpawn = ++lastSpawn % 4
        }
    }
    
    func drawLines() {
        //1
        gameNode.enumerateChildNodesWithName("line", usingBlock: {node, stop in
            node.removeFromParent()
        })
        
        //2
        gameNode.enumerateChildNodesWithName("bird", usingBlock: {node, stop in
            //3
            let bird = node as! Bird
            if let path = bird.createPathToMove() {
                let shapeNode = SKShapeNode()
                shapeNode.path = path
                shapeNode.name = "line"
                
                shapeNode.lineWidth = 2
                shapeNode.zPosition = 11
                
                switch bird.getType() {
                case 1:
                    shapeNode.strokeColor = UIColor.redColor()
                case 2:
                    shapeNode.strokeColor = UIColor.orangeColor()
                case 3:
                    shapeNode.strokeColor = UIColor.yellowColor()
                case 4:
                    shapeNode.strokeColor = UIColor.purpleColor()
                case 5:
                    shapeNode.strokeColor = UIColor.greenColor()
                default:
                    shapeNode.strokeColor = UIColor.redColor()
                }
                
                self.gameNode.addChild(shapeNode)
            }
        })
    }
    
    func removeLife() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let ssound = defaults.boolForKey("sound")
        if ssound {
            self.runAction(SKAction.playSoundFileNamed("dead.wav", waitForCompletion: false))
        }
        
        var node:SKSpriteNode
        switch lives {
        case 5:
            node = life5!
        case 4:
            node = life4!
        case 3:
            node = life3!
        case 2:
            node = life2!
        case 1:
            node = life1!
        default:
            node = life5!
        }
        lives--
        node.physicsBody = SKPhysicsBody()
        node.physicsBody?.dynamic=true
        node.physicsBody?.applyImpulse(CGVectorMake(0, 10))
        
        if lives == 0 {
            endGame()
        }
        
    }
    
    func endGame() {
        let defaults1 = NSUserDefaults.standardUserDefaults()
        let ssound = defaults1.boolForKey("sound")
        if ssound {
            self.runAction(SKAction.playSoundFileNamed("end.mp3", waitForCompletion: false))
        }
        
        stopped = true
        gameNode.enumerateChildNodesWithName("bird", usingBlock: {node, stop in
            let bird = node as! Bird
            bird.clearWayPoints()
        })
        drawLines()
        pauseBtn.removeFromParent()
        soundBtn.removeFromParent()
        
        homeBtn.position = CGPointMake(self.frame.size.width/2, -homeBtn.size.height)
        homeBtn.zPosition = 200
        let upAction = SKAction.moveToY(self.frame.size.height/5, duration: 0.5)
        homeBtn.runAction(SKAction.sequence([SKAction.waitForDuration(0.4), upAction]))
        gameNode.addChild(homeBtn)
        
        endGameLabel.texture = SKTexture(imageNamed: "gameOver.png")
        
        let defaults = NSUserDefaults.standardUserDefaults()
        var best = defaults.integerForKey("waves")
        if mode == 1 {
            best = defaults.integerForKey("contin")
        }
        if best < score {
            //New High Score!
            print("New High Score")
            if mode == 0 {
                defaults.setInteger(score, forKey: "waves")
            } else {
                defaults.setInteger(score, forKey: "contin")
            }
            endGameLabel.texture = SKTexture(imageNamed: "highScore.png")
            best = score
        }
        endGameLabel.size = endGameLabel.texture!.size()

        
        saveHighScore()
        
        let frameW = self.frame.size.width
        let frameH = self.frame.size.height
        
        endGameLabel.position = CGPointMake(frameW/2, frameH + frameH/1.28)
        endGameLabel.zPosition = 200
        var action = SKAction.moveToY(frameH/1.28, duration: 0.5)
        endGameLabel.runAction(action)
        gameNode.addChild(endGameLabel)
        
        scoreBox.position = CGPointMake(frameW/2, frameH + frameH/2 + scoreBox.size.height/1.3)
        scoreBox.zPosition = 101
        action = SKAction.moveToY(frameH/2 + scoreBox.size.height/1.3, duration: 0.5)
        scoreBox.runAction(action)
        gameNode.addChild(scoreBox)
        
        bestBox.position = CGPointMake(frameW/2, frameH + frameH/2 - bestBox.size.height/1.3)
        bestBox.zPosition = 101
        action = SKAction.moveToY(frameH/2 - bestBox.size.height/1.3, duration: 0.5)
        bestBox.runAction(action)
        gameNode.addChild(bestBox)
        
        scoreLabel.fontSize = scoreBox.size.height * 0.8
        scoreLabel.position = CGPointMake(frameW/2 + scoreBox.size.width/3, frameH + frameH/2 + scoreBox.size.height/1.3 - scoreLabel.frame.size.height/2)
        scoreLabel.zPosition = 200
        scoreLabel.text = "0"
        scoreLabel.fontColor = UIColor.redColor()
        action = SKAction.moveToY(frameH/2 + scoreBox.size.height/1.3 - scoreLabel.frame.size.height/2, duration: 0.5)
        scoreLabel.runAction(action)
        scoreHeight = frameH/2 + scoreBox.size.height/1.3 - scoreLabel.frame.size.height/2
        
        bestScoreLabel.fontSize = scoreBox.size.height * 0.8
        bestScoreLabel.position = CGPointMake(frameW/2 + bestBox.size.width/3, frameH + frameH/2 - bestBox.size.height/1.3 - bestScoreLabel.frame.size.height/2)
        bestScoreLabel.zPosition = 200
        bestScoreLabel.fontColor = UIColor.redColor()
        bestScoreLabel.text = String(best)
        action = SKAction.moveToY(frameH/2 - bestBox.size.height/1.3 - bestScoreLabel.frame.size.height/2, duration: 0.5)
        bestScoreLabel.runAction(action)
        gameNode.addChild(bestScoreLabel)
        
    }
    
    func placeLives() {
        life1 = SKSpriteNode(imageNamed: "life.png")
        life2 = SKSpriteNode(imageNamed: "life.png")
        life3 = SKSpriteNode(imageNamed: "life.png")
        life4 = SKSpriteNode(imageNamed: "life.png")
        life5 = SKSpriteNode(imageNamed: "life.png")
        
        let midX = self.frame.size.width/2
        let x = life1?.size.width
        life1?.position = CGPointMake(midX - 2*x! - 20, -140)
        life2?.position = CGPointMake(midX - x! - 10, -110)
        life3?.position = CGPointMake(midX, -80)
        life4?.position = CGPointMake(midX + x! + 10, -50)
        life5?.position = CGPointMake(midX + 2*x! + 20, -20)
        
        let action = SKAction.moveToY(20, duration: 0.5)
        
        life1?.runAction(action)
        life2?.runAction(action)
        life3?.runAction(action)
        life4?.runAction(action)
        life5?.runAction(action)
        
        
        life1?.zPosition = 10
        life2?.zPosition = 10
        life3?.zPosition = 10
        life4?.zPosition = 10
        life5?.zPosition = 10
        
        gameNode.addChild(life1!)
        gameNode.addChild(life2!)
        gameNode.addChild(life3!)
        gameNode.addChild(life4!)
        gameNode.addChild(life5!)
    }
    
    func placeNests() {
        home1 = SKSpriteNode(imageNamed: "nestR.png")
        home2 = SKSpriteNode(imageNamed: "nestO.png")
        home3 = SKSpriteNode(imageNamed: "nestY.png")
        home4 = SKSpriteNode(imageNamed: "nestP.png")
        home5 = SKSpriteNode(imageNamed: "nestG.png")
        
        let y = self.frame.size.height
        print(y)
        let x = self.frame.size.width
        
        if mode == 0 {
            home1!.position = CGPointMake(self.frame.width - 50, y/1.14)
            home2!.position = CGPointMake(self.frame.width - 50, y/1.45)
            home3!.position = CGPointMake(self.frame.width - 50, y/2)
            home4!.position = CGPointMake(self.frame.width - 50, y/3.2)
            home5!.position = CGPointMake(self.frame.width - 50, y/8)
        } else {
            home1!.position = CGPointMake(x * 0.369, y * 0.531) //red
            home2!.position = CGPointMake(x * 0.465, y * 0.563) // orange
            home3!.position = CGPointMake(x * 0.594, y * 0.422) // yellow
            home4!.position = CGPointMake(x * 0.694, y * 0.459) // purple
            home5!.position = CGPointMake(x * 0.598, y * 0.709) //green
            
            home1!.xScale = 0.7
            home1?.yScale = 0.7
            home2!.xScale = 0.7
            home2?.yScale = 0.7
            home3!.xScale = 0.7
            home3?.yScale = 0.7
            home4!.xScale = 0.7
            home4?.yScale = 0.7
            home5!.xScale = 0.7
            home5?.yScale = 0.7
 
        }
        
        home1!.zPosition = 10
        home2!.zPosition = 10
        home3!.zPosition = 10
        home4!.zPosition = 10
        home5!.zPosition = 10
        
        home1?.alpha = 0
        home2?.alpha = 0
        home3?.alpha = 0
        home4?.alpha = 0
        home5?.alpha = 0
        
        let action = SKAction.fadeInWithDuration(0.5)
        home1?.runAction(action)
        home2?.runAction(action)
        home3?.runAction(action)
        home4?.runAction(action)
        home5?.runAction(action)
        
        gameNode.addChild(home1!)
        gameNode.addChild(home2!)
        gameNode.addChild(home3!)
        gameNode.addChild(home4!)
        gameNode.addChild(home5!)
    }
    
    func leftSpawn(speed: CGFloat) {
        let type = Int(arc4random_uniform(5)) + 1
        let bird = Bird(type: type, speed: speed)
        let y = CGFloat(arc4random_uniform(UInt32(self.frame.size.height - 100))) + 50
        bird.position = CGPoint(x: -40, y: y)
        bird.zPosition = 100
        bird.dir = 1
        bird.xScale = 0.8
        bird.yScale = 0.8
        gameNode.addChild(bird)
    }
    func rightSpawn(speed: CGFloat) {
        let type = Int(arc4random_uniform(5)) + 1
        let bird = Bird(type: type, speed: speed)
        let y = CGFloat(arc4random_uniform(UInt32(self.frame.size.height - 100))) + 50
        bird.position = CGPoint(x: self.frame.size.width + 40, y: y)
        bird.zPosition = 100
        bird.dir = 2
        bird.xScale = 0.8
        bird.yScale = 0.8
        gameNode.addChild(bird)
    }
    func upSpawn(speed: CGFloat) {
        let type = Int(arc4random_uniform(5)) + 1
        let bird = Bird(type: type, speed: speed)
        let x = CGFloat(arc4random_uniform(UInt32(self.frame.size.width - 140))) + 70
        bird.position = CGPoint(x: x, y: self.frame.size.height + 40)
        bird.zPosition = 100
        bird.dir = 3
        bird.xScale = 0.8
        bird.yScale = 0.8
        gameNode.addChild(bird)
    }
    func downSpawn(speed: CGFloat) {
        let type = Int(arc4random_uniform(5)) + 1
        let bird = Bird(type: type, speed: speed)
        let x = CGFloat(arc4random_uniform(UInt32(self.frame.size.width - 140))) + 70
        bird.position = CGPoint(x: x, y: -40)
        bird.zPosition = 100
        bird.dir = 4
        bird.xScale = 0.8
        bird.yScale = 0.8
        gameNode.addChild(bird)
    }
    
    func arrowSpawn(speed: CGFloat) {
        let y = self.frame.size.height
        var type = Int(arc4random_uniform(5)) + 1
        let bird = Bird(type: type, speed: speed)
        bird.position = CGPoint(x: -5 * bird.size.width/2, y: y/1.14)
        bird.zPosition = 100
        gameNode.addChild(bird)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird2 = Bird(type: type, speed: speed)
        bird2.position = CGPoint(x: -3 * bird.size.width/2, y: y/1.45)
        bird2.zPosition = 100
        gameNode.addChild(bird2)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird3 = Bird(type: type, speed: speed)
        bird3.position = CGPoint(x: -bird.size.width/2, y: y/2)
        bird3.zPosition = 100
        gameNode.addChild(bird3)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird4 = Bird(type: type, speed: speed)
        bird4.position = CGPoint(x: -3 * bird.size.width/2, y: y/3.2)
        bird4.zPosition = 100
        gameNode.addChild(bird4)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird5 = Bird(type: type, speed: speed)
        bird5.position = CGPoint(x: -5 * bird.size.width/2, y: y/8)
        bird5.zPosition = 100
        gameNode.addChild(bird5)
    }
    
    func arrowSpawn2(speed: CGFloat) {
        let y = self.frame.size.height
        var type = Int(arc4random_uniform(5)) + 1
        let bird = Bird(type: type, speed: speed)
        bird.position = CGPoint(x: -bird.size.width/2, y: y/1.14)
        bird.zPosition = 100
        gameNode.addChild(bird)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird2 = Bird(type: type, speed: speed)
        bird2.position = CGPoint(x: -3 * bird.size.width/2, y: y/1.45)
        bird2.zPosition = 100
        gameNode.addChild(bird2)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird3 = Bird(type: type, speed: speed)
        bird3.position = CGPoint(x: -5 * bird.size.width/2, y: y/2)
        bird3.zPosition = 100
        gameNode.addChild(bird3)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird4 = Bird(type: type, speed: speed)
        bird4.position = CGPoint(x: -3 * bird.size.width/2, y: y/3.2)
        bird4.zPosition = 100
        gameNode.addChild(bird4)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird5 = Bird(type: type, speed: speed)
        bird5.position = CGPoint(x: -bird.size.width/2, y: y/8)
        bird5.zPosition = 100
        gameNode.addChild(bird5)
    }
    
    func diagonalSpawn(speed: CGFloat) {
        let y = self.frame.size.height
        var type = Int(arc4random_uniform(5)) + 1
        let bird = Bird(type: type, speed: speed)
        bird.position = CGPoint(x: -9 * bird.size.width/2, y: y/1.14)
        bird.zPosition = 100
        gameNode.addChild(bird)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird2 = Bird(type: type, speed: speed)
        bird2.position = CGPoint(x: -7 * bird.size.width/2, y: y/1.45)
        bird2.zPosition = 100
        gameNode.addChild(bird2)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird3 = Bird(type: type, speed: speed)
        bird3.position = CGPoint(x: -5 * bird.size.width/2, y: y/2)
        bird3.zPosition = 100
        gameNode.addChild(bird3)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird4 = Bird(type: type, speed: speed)
        bird4.position = CGPoint(x: -3 * bird.size.width/2, y: y/3.2)
        bird4.zPosition = 100
        gameNode.addChild(bird4)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird5 = Bird(type: type, speed: speed)
        bird5.position = CGPoint(x: -bird.size.width/2, y: y/8)
        bird5.zPosition = 100
        gameNode.addChild(bird5)
    }
    
    func diagonalSpawn2(speed: CGFloat) {
        let y = self.frame.size.height
        var type = Int(arc4random_uniform(5)) + 1
        let bird = Bird(type: type, speed: speed)
        bird.position = CGPoint(x: -bird.size.width/2, y: y/1.14)
        bird.zPosition = 100
        gameNode.addChild(bird)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird2 = Bird(type: type, speed: speed)
        bird2.position = CGPoint(x: -3 * bird.size.width/2, y: y/1.45)
        bird2.zPosition = 100
        gameNode.addChild(bird2)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird3 = Bird(type: type, speed: speed)
        bird3.position = CGPoint(x: -5 * bird.size.width/2, y: y/2)
        bird3.zPosition = 100
        gameNode.addChild(bird3)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird4 = Bird(type: type, speed: speed)
        bird4.position = CGPoint(x: -7 * bird.size.width/2, y: y/3.2)
        bird4.zPosition = 100
        gameNode.addChild(bird4)
        
        type = Int(arc4random_uniform(5)) + 1
        let bird5 = Bird(type: type, speed: speed)
        bird5.position = CGPoint(x: -9 * bird.size.width/2, y: y/8)
        bird5.zPosition = 100
        gameNode.addChild(bird5)
    }
    
    func saveHighScore() {
        if(GKLocalPlayer.localPlayer().authenticated) {
            
            var scoreReporter = GKScore(leaderboardIdentifier: "nkwaves")
            if mode == 1 {
                scoreReporter = GKScore(leaderboardIdentifier: "birdzz")
            }
            
            var defaults = NSUserDefaults.standardUserDefaults()
            var best = defaults.integerForKey("waves")
            if mode == 1 {
                best = defaults.integerForKey("contin")
            }
            scoreReporter.value = Int64(best)
            
            print("Submitting: "+String(scoreReporter.value))
            
            var scoreArray: [GKScore] = [scoreReporter]
            GKScore.reportScores(scoreArray, withCompletionHandler: {(error : NSError?) -> Void in
                if error != nil {
                    print("error")
                    print(error!.localizedDescription)
                }else{
                    print("Submitted Score")
                }
            })
        }else{
            print("Not Logged In")
        }
    }
    
    func showLeader() {
        if GKLocalPlayer.localPlayer().authenticated {
            let vc = self.view?.window?.rootViewController
            let gc = GKGameCenterViewController()
            gc.gameCenterDelegate = self
            gc.viewState = GKGameCenterViewControllerState.Leaderboards
            if mode == 1 {
                gc.leaderboardIdentifier = "birdzz"
            } else {
                gc.leaderboardIdentifier = "nkwaves"
            }
            vc?.presentViewController(gc, animated: true, completion: nil)
        }
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController){
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func authenticatePlayer() {
        //log in player to game center
        var localPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(viewController, error) -> Void in
            if viewController != nil {
                var vc = self.view?.window?.rootViewController
                vc?.presentViewController(viewController!, animated: true, completion: nil)
            }else{
                print("Authenticated: " + String(stringInterpolationSegment: GKLocalPlayer.localPlayer().authenticated))
            }
        }
    }
    
    
    //iAd
    func loadAd(animated: Bool) {
        let defaults1 = NSUserDefaults.standardUserDefaults()
        let ad = defaults1.objectForKey("ad")
        if let Ad = ad as? Bool {
            if !Ad {
                return
            }
        }
        if !hasAd {
            print("loading banner ad")
            let S = UIScreen.mainScreen().bounds
            UIiAd.delegate = self
            UIiAd.frame = CGRectMake(0, S.height - UIiAd.frame.height, S.width, 0)
            //UIiAd.center = CGPoint(x: S.width/2, y: S.height/2 - UIiAd.frame.height)
            UIiAd.alpha = 0
            //UIiAd.con
            self.view?.addSubview(UIiAd)
        }
    }
    
    // 3
    func removeAd(animated: Bool) {
        UIiAd.delegate = nil
        UIiAd.removeFromSuperview()
        hasAd = false
        loadAd(true)
    }
    
    // 4
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        hasAd = true
        
        print("Ad loaded")
    }
    
    // 5
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        print(error)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0)
        UIiAd.alpha = 0
        UIView.commitAnimations()
        hasAd = false
        loadAd(true)
    }
}
