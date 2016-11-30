//
//  bird.swift
//  Birdz
//
//  Created by Jan Anthony Miranda on 6/30/15.
//  Copyright (c) 2015 Jan Anthony Miranda. All rights reserved.
//

import Foundation
import SpriteKit

class Bird: SKSpriteNode {
    var POINTS_PER_SEC: CGFloat = 50
    var wayPoints: [CGPoint] = []
    var smoothPoints = [CGPoint]()
    var velocity = CGPoint(x: 0, y: 0)
    var removing = false
    var type: Int
    var dead = false
    var inputted = false
    var right = true
    var dir = 0
    
    init(type: Int, speed: CGFloat) {
        self.type = type
        POINTS_PER_SEC = speed
        
        var frames = [SKTexture]()
        switch type {
        case 1:
            frames.append(SKTexture(imageNamed: "birdR1.png"))
            frames.append(SKTexture(imageNamed: "birdR2.png"))
            frames.append(SKTexture(imageNamed: "birdR3.png"))
        case 2:
            frames.append(SKTexture(imageNamed: "birdO1.png"))
            frames.append(SKTexture(imageNamed: "birdO2.png"))
            frames.append(SKTexture(imageNamed: "birdO3.png"))
        case 3:
            frames.append(SKTexture(imageNamed: "birdY1.png"))
            frames.append(SKTexture(imageNamed: "birdY2.png"))
            frames.append(SKTexture(imageNamed: "birdY3.png"))
        case 4:
            frames.append(SKTexture(imageNamed: "birdP1.png"))
            frames.append(SKTexture(imageNamed: "birdP2.png"))
            frames.append(SKTexture(imageNamed: "birdP3.png"))
        case 5:
            frames.append(SKTexture(imageNamed: "birdG1.png"))
            frames.append(SKTexture(imageNamed: "birdG2.png"))
            frames.append(SKTexture(imageNamed: "birdG3.png"))
        default:
            frames.append(SKTexture(imageNamed: "birdR1.png"))
            frames.append(SKTexture(imageNamed: "birdR2.png"))
            frames.append(SKTexture(imageNamed: "birdR3.png"))
        }
        
        let texture = SKTexture(imageNamed: "birdR1.png")
        super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
        //xScale = 0.5
        //yScale = 0.5
        let delay = SKAction.waitForDuration(Double(arc4random_uniform(100) / 100))
        runAction(SKAction.sequence([delay, SKAction.repeatActionForever(SKAction.animateWithTextures(frames, timePerFrame: 0.15))]))
        name = "bird"
        //physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2.0 - 2)
        //println("width \(size.width)")
        //println("height \(size.height)")
        //physicsBody = SKPhysicsBody(circleOfRadius: size.width/2 * 0.825, center: CGPoint(x: size.width * 0.0375, y:  -size.width * 0.0375))
        physicsBody = SKPhysicsBody(circleOfRadius: size.width/2 * 0.825)
        physicsBody!.categoryBitMask = 1
        physicsBody!.contactTestBitMask = 1
        physicsBody!.collisionBitMask = 0
        physicsBody?.dynamic = true
        physicsBody?.affectedByGravity = false
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getType() -> Int {
        return type
    }
    
    func addPoint(point: CGPoint){
        wayPoints.append(point)
    }
    
    func move(dt: NSTimeInterval) {
        if dead {
            return
        }
        let currentPosition = position
        var newPosition = position
        
        //1
        if inputted && wayPoints.count == 0 {
            newPosition = CGPoint(x: currentPosition.x + velocity.x * CGFloat(dt),
                y: currentPosition.y + velocity.y * CGFloat(dt))
            position = checkBoundaries(newPosition);
        } else {
            //if wayPoints.count > -1 {
            var targetPoint: CGPoint
            if wayPoints.count == 0 {
                switch dir {
                case 0:
                    targetPoint = CGPoint(x: currentPosition.x + CGFloat(1), y: currentPosition.y)
                case 1:
                    targetPoint = CGPoint(x: currentPosition.x + CGFloat(1), y: currentPosition.y)
                case 2:
                    targetPoint = CGPoint(x: currentPosition.x - CGFloat(1), y: currentPosition.y)
                case 3:
                    targetPoint = CGPoint(x: currentPosition.x, y: currentPosition.y - CGFloat(1))
                case 4:
                    targetPoint = CGPoint(x: currentPosition.x, y: currentPosition.y + CGFloat(1))
                default:
                    targetPoint = CGPoint(x: currentPosition.x, y: currentPosition.y + CGFloat(1))
                }
            }else{
                targetPoint = wayPoints[0]
                inputted = true
            }
            
            //1
            let offset = CGPoint(x: targetPoint.x - currentPosition.x, y: targetPoint.y - currentPosition.y)
            let length = Double(sqrtf(Float(offset.x * offset.x) + Float(offset.y * offset.y)))
            let direction = CGPoint(x:CGFloat(offset.x) / CGFloat(length), y: CGFloat(offset.y) / CGFloat(length))
            velocity = CGPoint(x: direction.x * POINTS_PER_SEC, y: direction.y * POINTS_PER_SEC)
            
            //2
            newPosition = CGPoint(x:currentPosition.x + velocity.x * CGFloat(dt), y:currentPosition.y + velocity.y * CGFloat(dt))
            position = newPosition
            
            //3
            if wayPoints.count > 0 {
                if inside(currentPosition, B: targetPoint) {
                //if frame.contains(targetPoint) {
                    wayPoints.removeAtIndex(0)
                }
            }
            
            if newPosition.x - scene!.size.width > size.width/2 && dir == 0 {
                removeBird()
            }
            
        }
        
        if newPosition.x > currentPosition.x && !right {
            yScale = yScale * -1
            right = true
            
        } else if newPosition.x < currentPosition.x && right {
            yScale = yScale * -1
            right = false
            
        }
        
        zRotation = atan2(CGFloat(velocity.y), CGFloat(velocity.x))
        checkForHome()
    }
    
    func inside(A: CGPoint, B: CGPoint) -> Bool {
        if fabs(A.x - B.x) < 10 && fabs(A.y - B.y) < 10 {
            return true
        }
        return false
    }
    
    func checkBoundaries(position: CGPoint) -> CGPoint {
        if dir != 0 {
            return position
        }
        //1
        var newVelocity = velocity
        var newPosition = position
        
        //2
        let bottomLeft = CGPoint(x: 0, y: 0)
        let topRight = CGPoint(x:scene!.size.width, y:scene!.size.height)
        /*
        if !inputted {
        if position.x > topRight.x + 40 {
        removeBird()
        }else{
        return position
        }
        }*/
        
        //3
        if newPosition.x <= bottomLeft.x {
            newPosition.x = bottomLeft.x
            newVelocity.x = -newVelocity.x
        } else if newPosition.x >= topRight.x {
            newPosition.x = topRight.x
            newVelocity.x = -newVelocity.x
        }
        
        if newPosition.y <= bottomLeft.y {
            newPosition.y = bottomLeft.y
            newVelocity.y = -newVelocity.y
        } else if newPosition.y >= topRight.y {
            newPosition.y = topRight.y
            newVelocity.y = -newVelocity.y
        }
        
        velocity = newVelocity
        return newPosition
    }
    
    func removeBird() {
        
        removing = true
        
        wayPoints.removeAll(keepCapacity: false)
        removeAllActions()
        let s = scene as! GameScene
        s.removeLife()
        
        removeFromParent()
    }
    
    func checkForHome() {
        //1
        if removing || dead {
            return
        }
        
        //2
        if let s = scene as? GameScene {
            var homeNode: SKSpriteNode
            switch type {
            case 1:
                homeNode = s.home1!
            case 2:
                homeNode = s.home2!
            case 3:
                homeNode = s.home3!
            case 4:
                homeNode = s.home4!
            case 5:
                homeNode = s.home5!
            default:
                homeNode = s.home1!
            }
            
            //3
            if frame.intersects(homeNode.frame) {
                removing = true
                
                wayPoints.removeAll(keepCapacity: false)
                removeAllActions()
                
                //4
                runAction(SKAction.sequence([
                    SKAction.group([SKAction.fadeAlphaTo(0.0, duration: 0.5),
                        SKAction.moveTo(homeNode.position, duration: 0.5)]),
                    SKAction.removeFromParent()]))
                s.incrementScore()
            }
        }
    }
    
    func createPathToMove() -> CGPathRef? {
        //1
        if wayPoints.count <= 1 {
            return nil
        }
        smoothPoints = wayPoints
        smoothAll()
        //2
        let ref = UIBezierPath()
        //3
        for var i = 0; i < smoothPoints.count; ++i {
            let p = smoothPoints[i]
            
            //4
            if i == 0 {
                ref.moveToPoint(p)
            } else {
                ref.addLineToPoint(p)
            }
        }
        
        let pattern: [CGFloat] = [10.0, 10.0]
        let dashed = CGPathCreateCopyByDashingPath(ref.CGPath, nil, 0, pattern, 2);
        
        return dashed
    }
    
    func clearWayPoints() {
        wayPoints.removeAll(keepCapacity: false)
    }
    
    func smoothFront() {
        if smoothPoints.count > 2 {
            let new: CGPoint = smoothPoints[0] * 0.3 + smoothPoints[1] * 0.4 + smoothPoints[2] * 0.3
            smoothPoints[1] = new
        }
    }
    
    func smoothBack() {
        if smoothPoints.count > 2 {
            let end = smoothPoints.count
            let new: CGPoint = smoothPoints[end - 3] * 0.3 + smoothPoints[end - 2] * 0.4 + smoothPoints[end - 1] * 0.3
            smoothPoints[end - 2] = new
        }
    }
    
    func smoothAt(index: Int) {
        if smoothPoints.count > 4 && index - 2 >= 0 && index + 2 < smoothPoints.count {
            let new: CGPoint = smoothPoints[index - 2] * 0.1 + smoothPoints[index - 1] * 0.15 + smoothPoints[index] * 0.5
            let new2: CGPoint = new  + smoothPoints[index + 1] * 0.15 + smoothPoints[index + 2] * 0.1
            smoothPoints[index] = new2
        }
    }
    
    func smoothAll() {
        if smoothPoints.count > 4 {
            for var index = 2; index < smoothPoints.count - 2; index++ {
                smoothAt(index)
            }
            smoothFront()
            smoothBack()
        }
    }
    
}

func *(point: CGPoint, factor: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * factor, y: point.y * factor)
}
func +(a: CGPoint, b: CGPoint) -> CGPoint {
    return CGPoint(x: a.x + b.x, y: a.y + b.y)
}