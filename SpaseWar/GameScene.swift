//
//  GameScene.swift
//  SpaseWar
//
//  Created by Andriu on 04.03.2022.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Створюємо бітове число щоб розрізняти до чого наш корабель доторкнувся:
    let spaseShipCategory: UInt32 = 0x1 << 0
    let asteroidCategory: UInt32 = 0x1 << 1
    
    var spaceShip: SKSpriteNode!
    var score = 0
    var scoreLabel: SKLabelNode!
    var background: SKSpriteNode!
    var asteroidLayer: SKNode!
    var starsLayer: SKNode!
    let starsEmitter = SKEmitterNode(fileNamed: "Stars.sks")
    var spaceShiplayer: SKNode!
    
    //Pause:
    var gameIsPaused: Bool = false
    func pauseTheGame() {
        gameIsPaused = true
        self.asteroidLayer.isPaused = true
        self.starsEmitter?.isPaused = true
        physicsWorld.speed = 0
    }
    
    func pauseButton(sender: AnyObject) {
        if !gameIsPaused {
            pauseTheGame()
        } else {
            unpauseTheGame()
        }
    }
    
    //No pause:
    func unpauseTheGame() {
        gameIsPaused = false
        self.asteroidLayer.isPaused = false
        self.starsEmitter?.isPaused = false
        physicsWorld.speed = 1
    }
    
    func resetTheGame() {
        score = 0
        scoreLabel.text = "Score: \(score)"
        
        gameIsPaused = false
        self.asteroidLayer.isPaused = false
        physicsWorld.speed = 1
    }
    
    override func didMove(to view: SKView) {
        
        //Підпишемось під делегат:
        physicsWorld.contactDelegate = self
        //Насцільки сильне буде фізичне тіло;
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -1.8)
        
        //Створюємо фон:
        background = SKSpriteNode(imageNamed: "spaseBackground")
        //Розтягуємо наш фон по всьому екрану:
        background.size = CGSize(width: UIScreen.main.bounds.width * 2.1 , height: UIScreen.main.bounds.width * 3.8)
        background.zPosition = 0
        //Добавляємо на сцену:
        addChild(background)
        
        //Сніг який паде:
        
        starsEmitter?.zPosition = 0
        starsEmitter?.position = CGPoint(x: frame.midX, y: frame.height)
        starsEmitter?.particlePositionRange.dx = frame.width
        starsEmitter?.advanceSimulationTime(10)
        
        starsLayer = SKNode()
        starsLayer.zPosition = 1
        addChild(starsLayer)
        
        starsLayer.addChild(starsEmitter!)
        
        //Створюємо самольот:
        spaceShip = SKSpriteNode(imageNamed: "Image")
        //Маштабуєм корабель:
        spaceShip.setScale(1.7)
        //Робим фізичне тіло самольота:
        spaceShip.physicsBody = SKPhysicsBody(texture: spaceShip.texture!, size: spaceShip.size)
        //Так щоб самольот не падав в низ:
        spaceShip.physicsBody?.isDynamic = false
        //spaceShip.zPosition = 1
        
        spaceShip.physicsBody?.categoryBitMask = spaseShipCategory
        spaceShip.physicsBody?.collisionBitMask = asteroidCategory
        spaceShip.physicsBody?.contactTestBitMask = asteroidCategory
        
        //Щоб самольот моргав кольорами:
        let colorAction = SKAction.colorize(with: .yellow, colorBlendFactor: 1, duration: 1)
        let coloeAction2 = SKAction.colorize(with: .gray, colorBlendFactor: 0, duration: 1)
        
        let colorSequenceAnimation = SKAction.sequence([colorAction, coloeAction2])
        let colorActionRepeat = SKAction.repeatForever(colorSequenceAnimation)

        
        spaceShip.run(colorActionRepeat)
        
        //Додаємо на екран його:
        //addChild(spaceShip)
        
        //Створюємо слой для вогня:
        spaceShiplayer = SKNode()
        spaceShiplayer.addChild(spaceShip)
        spaceShiplayer.zPosition = 3
        spaceShip.zPosition = 1
        spaceShiplayer.position = CGPoint(x: frame.midX, y: frame.height / 4)
        addChild(spaceShiplayer)
        
        //Вогонь
        let fireEmitter = SKEmitterNode(fileNamed: "Fire.sks")
        fireEmitter?.zPosition = 0
        fireEmitter?.position.y = -40
        fireEmitter?.targetNode = self
        spaceShiplayer.addChild(fireEmitter!)
        
        
        asteroidLayer = SKNode()
        asteroidLayer.zPosition = 1
        addChild(asteroidLayer)
        
        //Створемо настройки астероїда:
        let asteroidCreate = SKAction.run {
            let asteroid = self.createAsteroid()
            self.asteroidLayer.addChild(asteroid)
        }
        //Скільки астероїдів в секунду:
        let asteroidPerSecond: Double = 1
        let asteroidCreationDelay = SKAction.wait(forDuration: 1.0 / asteroidPerSecond, withRange: 0.5)
        let asteroidSequeAction = SKAction.sequence([asteroidCreate, asteroidCreationDelay])
        let asteroidRunAction = SKAction.repeatForever(asteroidSequeAction)
        
        asteroidLayer.run(asteroidRunAction)
        scoreLabel = SKLabelNode(text: "Score: \(score)")
        scoreLabel.position = CGPoint(x: frame.size.width / scoreLabel.frame.size.width,
                                      y: 500)
        scoreLabel.fontSize = 80
        addChild(scoreLabel)
    }
    
    //Метод відповідає за доторкання до екрану:
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameIsPaused {
        if let touch = touches.first {
            //Координати доторку:
            let touchLocation = touch.location(in: self)
            //Дізнаємось дистанцію:
            let distance = distanceCalc(a: spaceShip.position, b: touchLocation)
            //Оприділяємо швидкість:
            let speed: CGFloat = 800
            //Оприділяємо час:
            let time = timeToTravelDistance(distance: distance, speed: speed)
            //Куди буде переміщуватись літак:
            let moveAction = SKAction.move(to: touchLocation, duration: time)
            //Зробим так щоб самольот не так різко рухався:
            moveAction.timingMode = SKActionTimingMode.easeInEaseOut

            //Передаємо дію(екшин):
            spaceShiplayer.run(moveAction)
            
            let bgMoveAction = SKAction.move(to: CGPoint(x: -touchLocation.x / 100,
                                                         y: -touchLocation.y / 100), duration: time)
            background.run(bgMoveAction)
        }
        }
        
    }
    
    //Метод для вичислення дистанції та швидкості переміщення корабля:
    func distanceCalc(a: CGPoint, b: CGPoint) -> CGFloat {
        return sqrt((b.x - a.x)*(b.x - a.x) + (b.y - a.y)*(b.y - a.y))
    }
    
    //Метод який буде шукати час:
    func timeToTravelDistance(distance: CGFloat, speed: CGFloat) -> TimeInterval {
        let time = distance / speed
        return TimeInterval(time)
    }
    
    
    //Створюємо метод для астероїд:
    func createAsteroid() -> SKSpriteNode {
        //Створюємо астероїд:
        let asteroid = SKSpriteNode(imageNamed: "acteroidImage")
        
        //Рандомні розміра астероїдів:
        let distribution = GKRandomDistribution(lowestValue: 5, highestValue: 13)
        //Згенероване число ділимо на 10
        let randomNumber = CGFloat(distribution.nextInt()) / 10
        //Маштабуємо астероїд:
        asteroid.setScale(randomNumber)
        
        asteroid.zPosition = 1
        //Де астероїд буде на екрані:
        asteroid.position.x = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 16))
        asteroid.position.y = frame.size.height  + asteroid.size.height
        
        //Робим фізичне тіло астероїда:
        asteroid.physicsBody = SKPhysicsBody(texture: asteroid.texture!, size: asteroid.size)
        //Присвоюємо астероїду імя:
        asteroid.name = "asteroid"
        
        asteroid.physicsBody?.categoryBitMask = asteroidCategory
        asteroid.physicsBody?.collisionBitMask = spaseShipCategory | asteroidCategory
        asteroid.physicsBody?.contactTestBitMask = spaseShipCategory
        
        //Щоб астероїди литіли не лише рівно:
        asteroid.physicsBody?.angularVelocity = CGFloat(drand48() * 2 - 1) * 3
        asteroid.physicsBody?.velocity.dx = CGFloat(drand48() * 2 - 1) * 100.0
        
        return asteroid
    }
    
    //Оновлення екрану:
    override func update(_ currentTime: TimeInterval) {
        
//        let asteriid = createAsteroid()
//        addChild(asteriid)
    }
    
    //Метод який буде спрацьовувати коли астероїди будуть поза екраном:
    override func didSimulatePhysics() {
        asteroidLayer.enumerateChildNodes(withName: "asteroid") { (asteroid, stop) in
            //Висота екрану:
            let hightScreen = UIScreen.main.bounds.height
            //Якщо він за екраном:
            if asteroid.position.y < -hightScreen {
                //Видаляємо його в батька:
                asteroid.removeFromParent()
                
                self.score = self.score + 1
                self.scoreLabel.text = "Score: \(self.score)"
            }
        }
    }
    
    //Методи делегатa:
    func didBegin(_ contact: SKPhysicsContact) {
        //При контакці виконується це:
        if contact.bodyA.categoryBitMask ==
            spaseShipCategory && contact.bodyB.categoryBitMask ==
            asteroidCategory || contact.bodyB.categoryBitMask ==
            spaseShipCategory && contact.bodyA.categoryBitMask == asteroidCategory {
            self.score = 0
            self.scoreLabel.text = "Score: \(self.score)"
            self.scoreLabel.zPosition = 5
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        
    }
}


