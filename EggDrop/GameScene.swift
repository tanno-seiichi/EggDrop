import SpriteKit
import GameplayKit
import CoreMotion
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // 画像
    struct Constants {
        static let LifeImages = ["Mihochan0-1", "Mihochan0-2"]
        static let Player1Images = ["Mihochan1-1", "Mihochan1-2"]
        static let Player1ClearImages = ["Mihochan1-3", "Mihochan1-4"]
        static let Player2Images = ["Mihochan2-1", "Mihochan2-2"]
        static let Player2ClearImages = ["Mihochan2-3", "Mihochan2-4"]
        static let Player3Images = ["Mihochan3-1", "Mihochan3-2"]
        static let Player3ClearImages = ["Mihochan3-3", "Mihochan3-4"]
        static let EggImages = ["Egg1-1", "Egg1-2"]
        static let BugImages = ["Bug1-1", "Bug1-2"]
        static let StarFighterImages = ["StarFighter_Blue"]
    }
    
    // アニメーション
    var lifeAnimation = SKAction()
    var player1Animation = SKAction()
    var player1ClearAnimation = SKAction()
    var player2Animation = SKAction()
    var player2ClearAnimation = SKAction()
    var player3Animation = SKAction()
    var player3ClearAnimation = SKAction()
    var eggAnimation = SKAction()
    var bugAnimation = SKAction()
    var starFighterAnimation = SKAction()

    var move = SKAction()
    
    // 卵キャッチサウンド
    let catchSound = SKAction.playSoundFileNamed("se_pikon7.mp3", waitForCompletion: false)
    
    // 卵クラッシュサウンド
    let missSound = SKAction.playSoundFileNamed("explosion3.mp3", waitForCompletion: false)
    
    // ステージクリアサウンド
    let stageClearSound = SKAction.playSoundFileNamed("VSQSE_0532_sfx_up_1.mp3", waitForCompletion: false)
    
    // ハイスコア記録用
    let defaults = UserDefaults.standard
    
    var vc: GameViewController!
    var mySpace = SKSpriteNode()
    var player = SKSpriteNode()
    var life1 = SKSpriteNode()
    var life2 = SKSpriteNode()
    var life3 = SKSpriteNode()
    var life4 = SKSpriteNode()

    // 卵の表示サイズと表示倍率
    var eggSize = CGSize(width: 0.0, height: 0.0)
    var eggRate : CGFloat = 0.0
    
    // 虫の表示サイズと表示倍率
    var bugSize = CGSize(width: 0.0, height: 0.0)
    var bugRate : CGFloat = 0.0
    
    // 戦闘機の表示サイズと表示倍率
    var starFighterSize = CGSize(width: 0.0, height: 0.0)
    var starFighterRate : CGFloat = 0.0
    
    // ライフの表示サイズと表示倍率
    var lifeSize = CGSize(width: 0.0, height: 0.0)
    var lifeRate : CGFloat = 0.0

    var dropTimer: Timer?
    var enemyCount = 0
    let motionMgr = CMMotionManager()
    var accelarationX: CGFloat = 0.0
    
    var _life = 3
    
    // LIFE表示ラベル
    var lifeLabelNode = SKLabelNode()
    
    // SCORE表示ラベル
    var scoreLabelNode = SKLabelNode()
    
    // HIGHSCORE表示ラベル
    var highScoreLabelNode = SKLabelNode()
    
    //レベルクリア表示ラベル
    var stageLabelNode1 = SKLabelNode()
    
    //レベルクリア表示ラベル
    var stageLabelNode2 = SKLabelNode()
    
    // 通常モードの曲
    let audio1 = Bundle.main.path(forResource: "VSQ_MUSIC_025", ofType: "mp3")
    
    // 難しいモードの曲
    let audio2 = Bundle.main.path(forResource: "VSQ_MUSIC_037", ofType: "mp3")

    var audioPlayer1 = AVAudioPlayer()
    var audioPlayer2 = AVAudioPlayer()
    
    var audioNum = 1
    
    // 当たり判定用ビットマスク
    let playerCategory : UInt32 = 0b0001
    let eggCategory : UInt32 = 0b1000
    let bugCategory : UInt32 = 0b0010
    let starFighterCategory : UInt32 = 0b0100
    
    // LIFE用プロパティ
    var life : Int = 0 {
        didSet {
            self.lifeLabelNode.text = "LIFE : \(life)"
        }
    }
    
    // SCORE用プロパティ
    var score : Int = 0 {
        didSet {
            self.scoreLabelNode.text = "SCORE : \(score)"
        }
    }
    
    // HIGHSCORE用プロパティ
    var highScore : Int = 0 {
        didSet {
            self.highScoreLabelNode.text = "HIGH-SCORE : \(highScore)"
        }
    }

    var stageType : Int = 1
    
    //レベルクリア用プロパティ
    var stage : Int = 1 {
        didSet{
            stageType = stageType < 3 ? stageType + 1 : 1
            if stageType == 1 {
                self.life += 1
                updateLife()
            }
            self.stageLabelNode1.text = "STAGE \(stage - 1) CLEAR"
            self.stageLabelNode2.text = "STAGE \(stage - 1) CLEAR"
        }
    }
 
    @objc func pause(){
        print("* * * * * * pause has been called * * * * * *")
        self.move.speed = 0
    }
    
    @objc func resume(){
        print("* * * * * * resume has been called * * * * * *")
    }
    
    override func didMove(to view: SKView) {
        NotificationCenter.default.addObserver(self, selector: #selector(pause), name: NSNotification.Name(rawValue: "PauseGameScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resume), name: NSNotification.Name(rawValue: "ResumeGameScene"), object: nil)

        var sizeRate : CGFloat = 0.0
        var mySpaceSize = CGSize(width: 0.0, height: 0.0)
        var playerSize = CGSize(width: 0.0, height: 0.0)
        let offsetY = frame.height / 20
        
        // 画面への重力設定
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        physicsWorld.contactDelegate = self

        //背景画像の読み込み
        self.mySpace = SKSpriteNode(imageNamed: "2391021")
        
        mySpaceSize = CGSize(width: self.mySpace.size.width * frame.height / self.mySpace.size.height,
                             height: self.mySpace.size.height * frame.height / self.mySpace.size.height)
        self.mySpace.scale(to: mySpaceSize)
        self.mySpace.zPosition = 0
        addChild(self.mySpace)
        
        // 画像ファイルの読み込み
        var player1Texture = [SKTexture]()
        for imageName in Constants.Player1Images {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .linear
            player1Texture.append(texture)
        }
        var player1ClearTexture = [SKTexture]()
        for imageName in Constants.Player1ClearImages {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .linear
            player1ClearTexture.append(texture)
        }

        var player2Texture = [SKTexture]()
        for imageName in Constants.Player2Images {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .linear
            player2Texture.append(texture)
        }
        var player2ClearTexture = [SKTexture]()
        for imageName in Constants.Player2ClearImages {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .linear
            player2ClearTexture.append(texture)
        }

        var player3Texture = [SKTexture]()
        for imageName in Constants.Player3Images {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .linear
            player3Texture.append(texture)
        }
        var player3ClearTexture = [SKTexture]()
        for imageName in Constants.Player3ClearImages {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .linear
            player3ClearTexture.append(texture)
        }

        var eggTexture = [SKTexture]()
        for imageName in Constants.EggImages {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .linear
            eggTexture.append(texture)
        }
        self.eggAnimation = SKAction.animate(with: eggTexture, timePerFrame: 0.2)

        var bugTexture = [SKTexture]()
        for imageName in Constants.BugImages {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .linear
            bugTexture.append(texture)
        }
        self.bugAnimation = SKAction.animate(with: bugTexture, timePerFrame: 0.2)

        var starFighterTexture = [SKTexture]()
        for imageName in Constants.StarFighterImages {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .linear
            starFighterTexture.append(texture)
        }
        self.starFighterAnimation = SKAction.animate(with: starFighterTexture, timePerFrame: 0.2)
        
        var lifeTexture = [SKTexture]()
        for imageName in Constants.LifeImages {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .linear
            lifeTexture.append(texture)
        }
        self.lifeAnimation = SKAction.animate(with: lifeTexture, timePerFrame: 0.2)

        // プレーヤーを生成
        self.player = SKSpriteNode(texture: player1Texture[0])
        
        // プレーヤーを幅の1/5にするための倍率を求める
        sizeRate = (frame.width / 5) / self.player.size.width
        
        // プレーヤーのサイズを設定する
        playerSize = CGSize(width: self.player.size.width * sizeRate, height: self.player.size.height * sizeRate)
        self.player.scale(to: playerSize)
        
        // プレーヤーの表示位置を設定する
        self.player.position = CGPoint(x: 0, y: (-frame.height / 2) + offsetY + playerSize.height)
        
        // プレーヤーのアニメーションを設定する
        self.player1Animation = SKAction.animate(with: player1Texture, timePerFrame: 0.2)
        self.player1ClearAnimation = SKAction.animate(with: player1ClearTexture, timePerFrame: 0.4)
        self.player2Animation = SKAction.animate(with: player2Texture, timePerFrame: 0.2)
        self.player2ClearAnimation = SKAction.animate(with: player2ClearTexture, timePerFrame: 0.4)
        self.player3Animation = SKAction.animate(with: player3Texture, timePerFrame: 0.2)
        self.player3ClearAnimation = SKAction.animate(with: player3ClearTexture, timePerFrame: 0.4)
        
        // プレーヤーのアニメーションを起動する
        let animation = SKAction.repeatForever(player1Animation)
        self.player.run(animation, withKey:"animation")
        
        // プレーヤーへの物理ボディ、カテゴリビットマスク、衝突ビットマスクの設定
        self.player.physicsBody = SKPhysicsBody(rectangleOf: self.player.size)
        self.player.physicsBody?.categoryBitMask = self.playerCategory
        self.player.physicsBody?.collisionBitMask = self.eggCategory | self.bugCategory | self.starFighterCategory
        self.player.physicsBody?.contactTestBitMask = self.eggCategory | self.bugCategory | self.starFighterCategory
        self.player.physicsBody?.isDynamic = true
        
        // プレーヤーをシーンに追加（表示）する
        self.player.zPosition = 1
        addChild(self.player)
        
        // 卵の画像ファイルの読み込み
        let tempEgg = SKSpriteNode(texture: eggTexture[0])
        self.eggRate = (frame.width / 10) / tempEgg.size.width
        self.eggSize = CGSize(width: tempEgg.size.width * self.eggRate, height: tempEgg.size.height * self.eggRate)
        
        // 虫の画像ファイルの読み込み
        let tempBug = SKSpriteNode(texture: bugTexture[0])
        self.bugRate = (frame.width / 12) / tempBug.size.width
        self.bugSize = CGSize(width: tempBug.size.width * self.bugRate, height: tempBug.size.height * self.bugRate)
        
        // 戦闘機の画像ファイルの読み込み
        let tempStarFighter = SKSpriteNode(texture: starFighterTexture[0])
        self.starFighterRate = (frame.width / 5) / tempStarFighter.size.width
        self.starFighterSize = CGSize(width: tempStarFighter.size.width * self.starFighterRate, height: tempStarFighter.size.height * self.starFighterRate)
        
        // ライフの画像ファイルの読み込み
        let tempLife = SKSpriteNode(texture: lifeTexture[0])
        self.lifeRate = (frame.width / 10) / tempLife.size.width
        self.lifeSize = CGSize(width: tempLife.size.width * self.lifeRate, height: tempLife.size.height * self.lifeRate)
        // 卵を表示するメソッドmoveEggを1秒ごとに呼び出し
        dropTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.moveEgg()
        })
        
        // ライフの作成
        let loopAnimation = SKAction.repeatForever(self.lifeAnimation)
        self.life1 = SKSpriteNode(imageNamed:"Mihochan0-1")
        self.life1.scale(to: lifeSize)
        self.life1.run(loopAnimation)
        self.life1.zPosition = 2
        self.life1.position = CGPoint(x: -frame.width / 2 + 70, y: frame.height / 2 - 125)
        addChild(self.life1)
        
        self.life2 = SKSpriteNode(imageNamed:"Mihochan0-1")
        self.life2.scale(to: lifeSize)
        self.life2.run(loopAnimation)
        self.life2.zPosition = 2
        self.life2.position = CGPoint(x: -frame.width / 2 + 140, y: frame.height / 2 - 125)
        addChild(self.life2)
        
        self.life3 = SKSpriteNode(imageNamed:"Mihochan0-1")
        self.life3.scale(to: lifeSize)
        self.life3.run(loopAnimation)
        self.life3.zPosition = 2
        self.life3.position = CGPoint(x: -frame.width / 2 + 210, y: frame.height / 2 - 125)
        addChild(self.life3)
        
        self.life4 = SKSpriteNode(imageNamed:"Mihochan0-1")
        self.life4.scale(to: lifeSize)
        self.life4.run(loopAnimation)
        self.life4.zPosition = 2
        self.life4.position = CGPoint(x: -frame.width / 2 + 280, y: frame.height / 2 - 125)
        addChild(self.life4)

        self.life = 3
        updateLife()
        
        // スコアの表示
        self.score = 0
        self.scoreLabelNode.fontName = "HelveticaNeue-Bold"
        self.scoreLabelNode.fontColor = UIColor.white
        self.scoreLabelNode.fontSize = 37
        self.scoreLabelNode.horizontalAlignmentMode = .left
        self.scoreLabelNode.position = CGPoint(
            x: -frame.width / 2 + 35,
            y: frame.height / 2 - self.scoreLabelNode.frame.height * 2.5)
        self.scoreLabelNode.zPosition = 2
        addChild(self.scoreLabelNode)
        
        //ハイスコアの表示
        self.highScore = 0
        self.highScoreLabelNode.fontName = "HelveticaNeue-Bold"
        self.highScoreLabelNode.fontColor = UIColor.white
        self.highScoreLabelNode.fontSize = 37
        self.highScoreLabelNode.horizontalAlignmentMode = .right
        self.highScoreLabelNode.position = CGPoint(
            x: frame.width / 2 - 35,
            y: frame.height / 2 - self.highScoreLabelNode.frame.height * 2.5)
        self.highScoreLabelNode.zPosition = 2
        addChild(self.highScoreLabelNode)
        
        self.defaults.register(defaults:["highScores":[10,11,12]])
        let highScores = self.defaults.object(forKey: "highScores") as! [Int]
        self.highScore = highScores[0]
        
        do{
            self.audioPlayer1 = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: audio1!))
            self.audioPlayer1.volume = 0.7
            self.audioPlayer1.numberOfLoops = -1

            self.audioPlayer2 = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: audio2!))
            self.audioPlayer2.volume = 0.8
            self.audioPlayer2.numberOfLoops = -1
        }catch{
            
        }

        // バックグラウンドミュージックの再生
        self.audioPlayer1.prepareToPlay()
        self.audioPlayer1.play()
    }
    
    func updateLife(){
        switch self.life{
        case 2:
            self.life1.isHidden = false
            self.life2.isHidden = true
            self.life3.isHidden = true
            self.life4.isHidden = true
        case 3:
            self.life1.isHidden = false
            self.life2.isHidden = false
            self.life3.isHidden = true
            self.life4.isHidden = true
        case 4:
            self.life1.isHidden = false
            self.life2.isHidden = false
            self.life3.isHidden = false
            self.life4.isHidden = true
        case 5:
            self.life1.isHidden = false
            self.life2.isHidden = false
            self.life3.isHidden = false
            self.life4.isHidden = false
        default:
            self.life1.isHidden = true
            self.life2.isHidden = true
            self.life3.isHidden = true
            self.life4.isHidden = true
        }
    }

    /// 卵を表示するメソッド
    func moveEgg() {
        if self.isPaused {
            return
        }
        
        var idx = Int.random(in: 0 ..< 3)
        if (stageType == 2 || stageType == 3) && idx == 2  {
            if self.enemyCount > 1{
                idx = 0
            }
            else{
                self.enemyCount += 1
            }
        }
        
        let egg = SKSpriteNode(imageNamed: "Egg1-1")
        
        // 卵のサイズを設定する
        if stageType == 2 && idx == 2{
            egg.scale(to: bugSize)
        }
        else if stageType == 3 && idx == 2{
            egg.scale(to: starFighterSize)
        }
        else{
            egg.scale(to: eggSize)
        }
        // 敵のx方向の位置を生成する
        let xPos = (frame.width * 0.9 / CGFloat.random(in: 1...5)) - frame.width / 2
        // 卵の位置を設定する
        egg.position = CGPoint(x: xPos, y: frame.height / 2)

        if stageType == 2 && idx == 2{
            let loopAnimation = SKAction.repeatForever(bugAnimation)
            egg.run(loopAnimation)
        }
        else if stageType == 3 && idx == 2{
            let loopAnimation = SKAction.repeatForever(starFighterAnimation)
            egg.run(loopAnimation)
        }
        else{
            let loopAnimation = SKAction.repeatForever(eggAnimation)
            egg.run(loopAnimation)
        }
        // 卵への物理ボディ、カテゴリビットマスクの設定
        if (stageType == 2 || stageType == 3 ) && idx == 2{
            egg.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: egg.size.width * 0.5, height: egg.size.height * 0.5))
        }
        else{
            egg.physicsBody = SKPhysicsBody(rectangleOf: egg.size)
        }
        
        if stageType == 2 && idx == 2{
            egg.physicsBody?.categoryBitMask = bugCategory
        }
        else if stageType == 3 && idx == 2{
            egg.physicsBody?.categoryBitMask = starFighterCategory
        }
        else{
            egg.physicsBody?.categoryBitMask = eggCategory
        }
        
        egg.physicsBody?.isDynamic = true
        
        // シーンに卵を表示する
        egg.zPosition = 1
        addChild(egg)
        
        // 曲番号に応じて卵の移動速度を設定する
        let speed = 2...3 ~= self.audioNum ? 1.5 : 2.0
        self.move = SKAction.moveTo(y: -frame.height / 2, duration: speed)

        // 親からノードを削除する
        let remove = SKAction.removeFromParent()

        let dispBrokenEgg = SKAction.run {
            let brokenEgg = SKSpriteNode(imageNamed: "EggBroken")
            brokenEgg.position = CGPoint(x: xPos, y: -self.frame.height / 2 + self.eggSize.height)
            brokenEgg.zPosition = 3
            brokenEgg.scale(to: CGSize(width: self.eggSize.width * 1.5, height: self.eggSize.height * 1.5))
            self.addChild(brokenEgg)
            
            self.run(SKAction.wait(forDuration: 1.0)) {
                brokenEgg.removeFromParent()
            }
        }
        
        let decrementLife = SKAction.run {
            self.miss()
        }
        
        let decrementEnemyCount = SKAction.run {
            self.enemyCount -= 1
        }
        // アクションを連続して実行する
        if stageType == 2 && idx == 2{
            egg.run(SKAction.sequence([move, remove, decrementEnemyCount]))
        }
        else if stageType == 3 && idx == 2{
            egg.run(SKAction.sequence([move, remove, decrementEnemyCount]))
        }
        else{
            egg.run(SKAction.sequence([move, remove, dispBrokenEgg, decrementLife]))
        }
    }
    
    func miss(){
        if self.life > 0 {
            let shotSound = SKAction.playSoundFileNamed("explosion3.mp3", waitForCompletion: false)
            self.run(shotSound)
            self.life -= 1
            updateLife()
        }
        
        if self.life <= 0 {
            self.dropTimer?.invalidate()
            self.dropTimer = nil
            
            self.audioPlayer1.stop()
            self.audioPlayer2.stop()
            
            var highScores = self.defaults.object(forKey: "highScores") as! [Int]
            highScores.append(self.score)
            highScores.sort(by: >)
            self.defaults.set(highScores, forKey: "highScores")
            
            // START画面に戻る
            self.run(SKAction.wait(forDuration: 0.5)) {
                self.vc.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    var distX = CGFloat()
    var distY = CGFloat()
    
    // プレーヤーの移動
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    // プレーヤーの移動
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
        if let touch: AnyObject = touches.first{
            let old = touch.previousLocation(in: self.view)
            let new = touch.location(in: self.view)
            player.position = CGPoint(x: player.position.x + (new.x - old.x) * 2.2, y: player.position.y - (new.y - old.y) * 2.2)
        }
    }
    
    /// 接触時のメソッド
    func didBegin(_ contact: SKPhysicsContact) {
        if self.life <= 0{
            return
        }
        
        if contact.bodyA.categoryBitMask == eggCategory {
            contact.bodyA.node?.removeFromParent()
            self.run(self.catchSound)
            self.score += 10
        }
        
        if contact.bodyB.categoryBitMask == eggCategory {
            contact.bodyB.node?.removeFromParent()
            self.run(self.catchSound)
            self.score += 10
        }
        
        if contact.bodyA.categoryBitMask == bugCategory {
            contact.bodyA.node?.removeFromParent()
            self.miss()
            self.enemyCount -= 1
            return
        }

        if contact.bodyB.categoryBitMask == bugCategory {
            contact.bodyB.node?.removeFromParent()
            self.miss()
            self.enemyCount -= 1
            return
        }
        
        if contact.bodyA.categoryBitMask == starFighterCategory {
            contact.bodyA.node?.removeFromParent()
            self.miss()
            self.enemyCount -= 1
            return
        }
        
        if contact.bodyB.categoryBitMask == starFighterCategory {
            contact.bodyB.node?.removeFromParent()
            self.miss()
            self.enemyCount -= 1
            return
        }
        
        if self.score > self.highScore{
            self.highScore = self.score
        }

        let musicChangeFlag = self.score < 400 ? self.score % 200 == 0 : self.score % 400 == 0
        if(musicChangeFlag){
            if self.audioNum < 4{
                self.audioNum += 1
            }
            else{
                self.audioNum = 1
            }
            
            if self.audioNum == 1 {
                self.audioPlayer2.stop()
                self.audioPlayer1.currentTime = 0
                self.audioPlayer1.prepareToPlay()
                self.run(SKAction.wait(forDuration: 1.0)) { self.audioPlayer1.play() }
                
                // ステージの表示
                self.stageLabelNode1.fontName = "HelveticaNeue-Bold"
                self.stageLabelNode1.fontColor = UIColor.magenta
                self.stageLabelNode1.fontSize = 80
                self.stageLabelNode1.position = CGPoint(x: 0, y: frame.height / 2 - frame.height / 5 )
                self.stageLabelNode1.zPosition = 5
                addChild(self.stageLabelNode1)
                
                self.stageLabelNode2.fontName = "HelveticaNeue-Bold"
                self.stageLabelNode2.fontColor = UIColor.black
                self.stageLabelNode2.fontSize = 80
                self.stageLabelNode2.position = CGPoint(x: 5, y: frame.height / 2 - frame.height / 5 - 5)
                self.stageLabelNode2.zPosition = 4
                addChild(self.stageLabelNode2)
                
                self.run(self.stageClearSound)
                
                var animation = SKAction()
                switch self.stageType {
                case 2:
                    animation = SKAction.repeatForever(self.player2ClearAnimation)
                case 3:
                    animation = SKAction.repeatForever(self.player3ClearAnimation)
                default:
                    animation = SKAction.repeatForever(self.player1ClearAnimation)
                }
                self.player.removeAction(forKey: "animation")
                self.player.run(animation, withKey: "animation")
                
                self.run(SKAction.wait(forDuration: 3.0)) {
                    self.stageLabelNode1.removeFromParent()
                    self.stageLabelNode2.removeFromParent()
                }
                self.stage += 1
            }
            
            if self.audioNum == 4 {
                self.audioPlayer1.stop()
                self.audioPlayer2.currentTime = 0
                self.audioPlayer2.prepareToPlay()
                self.run(SKAction.wait(forDuration: 1.0)) { self.audioPlayer2.play() }
            }

            self.dropTimer?.invalidate()
            self.dropTimer = nil
            
            if self.audioNum == 1{
                self.run(SKAction.wait(forDuration: 4.0)){
                    var animation = SKAction()
                    
                    self.mySpace.removeFromParent()
                    switch self.stageType {
                    case 2:
                        self.mySpace = SKSpriteNode(imageNamed: "3779")
                        animation = SKAction.repeatForever(self.player2Animation)
                    case 3:
                        self.mySpace = SKSpriteNode(imageNamed: "earthandmoon_1920")
                        animation = SKAction.repeatForever(self.player3Animation)
                    default:
                        self.mySpace = SKSpriteNode(imageNamed: "2391021")
                        animation = SKAction.repeatForever(self.player1Animation)
                    }
                    
                    let mySpaceSize = CGSize(width: self.mySpace.size.width * self.frame.height / self.mySpace.size.height,
                                             height: self.mySpace.size.height * self.frame.height / self.mySpace.size.height)
                    self.mySpace.scale(to: mySpaceSize)
                    self.mySpace.zPosition = 0
                    self.addChild(self.mySpace)
                    
                    self.player.removeAction(forKey: "animation")
                    self.player.run(animation, withKey: "animation")
                }
            }

            self.run(SKAction.wait(forDuration: self.audioNum == 1 ? 6.0 : 1.5)) {
                self.dropTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(self.audioNum + 1), repeats: true, block: { _ in self.moveEgg()})
            }
        }
    }
    
}
