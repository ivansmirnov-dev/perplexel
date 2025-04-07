//
//  GameScene.swift
//  cubit
//
//  Created by Ivan Smirnov on 2025-04-06.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // Debug settings
    private let debugMode = false
    
    // Game properties
    private var gameBoard: SKNode?
    private var tiles: [[SKNode]] = []
    private var scoreLabel: SKLabelNode?
    private var currentScore: Int = 0
    private var movesLabel: SKLabelNode?
    private var movesCount: Int = 0
    private var gameOverLabel: SKLabelNode?
    private var isGameOver: Bool = false
    private var headerBackground: SKShapeNode?
    private var predictedMovesLabel: SKLabelNode?
    private var predictedScoreLabel: SKLabelNode?
    private var currentLevel: Int = 1
    private var levelLabel: SKLabelNode?
    
    // Game configuration
    private let boardSize = 4
    private let tileSize: CGFloat = 64.0
    
    // Modern color palette with vibrant colors
    private let tileColors: [SKColor] = [
        SKColor(red: 0.906, green: 0.298, blue: 0.235, alpha: 1.0),  // Red
        SKColor(red: 0.204, green: 0.596, blue: 0.859, alpha: 1.0),  // Blue
        SKColor(red: 0.180, green: 0.800, blue: 0.443, alpha: 1.0),  // Green
        SKColor(red: 0.945, green: 0.769, blue: 0.059, alpha: 1.0),  // Yellow
        SKColor(red: 0.902, green: 0.494, blue: 0.133, alpha: 1.0)   // Orange
    ]
    private let purpleColor = SKColor(red: 0.608, green: 0.349, blue: 0.714, alpha: 1.0)
    
    // Visual properties
    private let cornerRadius: CGFloat = 12.0  // Increased corner radius for modern look
    private let tilePadding: CGFloat = 6.0    // Increased padding for a more spacious feel
    private var backgroundGradient: SKSpriteNode?
    private var boardBackgroundNode: SKShapeNode?
    private var gameTheme = GameTheme.dark // Default theme
    
    // Theme configuration
    enum GameTheme {
        case dark
        case light
        
        var backgroundColor: SKColor {
            switch self {
            case .dark: return SKColor(red: 0.133, green: 0.133, blue: 0.18, alpha: 1.0)
            case .light: return SKColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
            }
        }
        
        var headerColor: SKColor {
            switch self {
            case .dark: return SKColor(red: 0.165, green: 0.165, blue: 0.22, alpha: 1.0)
            case .light: return SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
            }
        }
        
        var textColor: SKColor {
            switch self {
            case .dark: return .white
            case .light: return SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
            }
        }
        
        var boardBackgroundColor: SKColor {
            switch self {
            case .dark: return SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
            case .light: return SKColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
            }
        }
        
        var tileBaseColor: SKColor {
            switch self {
            case .dark: return SKColor(red: 0.25, green: 0.25, blue: 0.3, alpha: 1.0)
            case .light: return SKColor(red: 0.75, green: 0.75, blue: 0.8, alpha: 1.0)
            }
        }
    }
    
    // Color point values
    private var colorPoints: [SKColor: Int] = [:]
    
    // Combo multipliers
    private let comboMultipliers: [Int: Int] = [
        3: 2,   // 2x multiplier for 3 tiles
        4: 3,   // 3x multiplier for 4 tiles
        5: 4,   // 4x multiplier for 5 tiles
        6: 5,   // 5x multiplier for 6 tiles
        7: 6,   // 6x multiplier for 7 tiles
        8: 8    // 8x multiplier for 8+ tiles
    ]
    
    // Score animation properties
    private var scoreAnimations: [SKNode] = []
    
    // Keep track of color info nodes
    private var colorInfoNodes: [SKNode] = []
    
    override func didMove(to view: SKView) {
        // Initialize color point values
        colorPoints = [
            tileColors[0]: 10,  // Red
            tileColors[1]: 15,  // Blue
            tileColors[2]: 20,  // Green
            tileColors[3]: 25,  // Yellow
            tileColors[4]: 30   // Orange
        ]
        
        setupGame()
    }
    
    private func setupGame() {
        // Set up gradient background instead of flat color
        backgroundColor = gameTheme.backgroundColor
        
        // Create gradient background
        let gradientTexture = createGradientTexture(
            size: CGSize(width: frame.width, height: frame.height),
            startColor: gameTheme.backgroundColor,
            endColor: SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        )
        
        backgroundGradient = SKSpriteNode(texture: gradientTexture)
        backgroundGradient?.position = CGPoint(x: frame.midX, y: frame.midY)
        backgroundGradient?.size = frame.size
        backgroundGradient?.zPosition = -10
        if let backgroundGradient = backgroundGradient {
            addChild(backgroundGradient)
        }
        
        // Add subtle animated particles for background
        if let particles = SKEmitterNode(fileNamed: "StarField") {
            particles.position = CGPoint(x: frame.midX, y: frame.midY)
            particles.zPosition = -5
            particles.particleAlpha = 0.1
            particles.particleScale = 0.3
            addChild(particles)
        }
        
        // Create header background - adjusted for Dynamic Island with shadow
        headerBackground = SKShapeNode(rect: CGRect(x: 0, y: frame.height - 140,
                                                  width: frame.width, height: 110),
                                     cornerRadius: 0)
        if let headerBackground = headerBackground {
            headerBackground.fillColor = gameTheme.headerColor
            headerBackground.strokeColor = .clear
            
            // Add subtle shadow to header
            let shadow = SKShapeNode(rect: CGRect(x: 0, y: frame.height - 142,
                                                width: frame.width, height: 4),
                                    cornerRadius: 0)
            shadow.fillColor = SKColor.black.withAlphaComponent(0.2)
            shadow.strokeColor = .clear
            shadow.zPosition = 4
            addChild(shadow)
            
            addChild(headerBackground)
        }
        
        // Create game board with background
        let boardWidth = CGFloat(self.boardSize) * tileSize
        let boardHeight = CGFloat(self.boardSize) * tileSize
        
        // Create larger background for visibility with shadow effect
        boardBackgroundNode = SKShapeNode(rectOf: CGSize(width: boardWidth + 30,
                                                      height: boardHeight + 30),
                                        cornerRadius: 20)
        if let boardBackground = boardBackgroundNode {
            boardBackground.fillColor = gameTheme.boardBackgroundColor
            boardBackground.strokeColor = SKColor.white.withAlphaComponent(0.1)
            boardBackground.lineWidth = 2
            boardBackground.position = CGPoint(x: frame.midX, y: frame.midY)
            
            // Add subtle shadow
            let shadowPath = CGPath(roundedRect: CGRect(x: -boardWidth/2 - 15 + 4, 
                                                      y: -boardHeight/2 - 15 - 4, 
                                                      width: boardWidth + 30, 
                                                      height: boardHeight + 30), 
                                  cornerWidth: 20, 
                                  cornerHeight: 20, 
                                  transform: nil)
            let shadow = SKShapeNode(path: shadowPath)
            shadow.fillColor = SKColor.black.withAlphaComponent(0.3)
            shadow.strokeColor = .clear
            shadow.zPosition = -1
            shadow.blendMode = .alpha
            boardBackground.addChild(shadow)
            
            addChild(boardBackground)
        }
        
        // Create and position the game board node
        gameBoard = SKNode()
        if let gameBoard = gameBoard {
            // Position the gameBoard so its center aligns with the frame's center
            gameBoard.position = CGPoint(x: frame.midX - boardWidth / 2,
                                       y: frame.midY - boardHeight / 2)
            addChild(gameBoard)
            
            // Clear any existing tiles
            tiles.removeAll()
            
            // Create board tiles
            for row in 0..<self.boardSize {
                var tileRow: [SKNode] = []
                for col in 0..<self.boardSize {
                    let tile = createTile()
                    
                    // Position each tile at its center (half tile size offset)
                    let x = CGFloat(col) * tileSize + tileSize / 2
                    let y = CGFloat(row) * tileSize + tileSize / 2
                    tile.position = CGPoint(x: x, y: y)
                    
                    // Set name for easier identification
                    tile.name = "\(row):\(col)"
                    
                    // Add to gameBoard and keep track in array
                    gameBoard.addChild(tile)
                    tileRow.append(tile)
                }
                tiles.append(tileRow)
            }
            
            if debugMode {
                print("Game board positioned at: \(gameBoard.position)")
                print("First tile positioned at: \(tiles[0][0].position)")
                print("Last tile positioned at: \(tiles[self.boardSize-1][self.boardSize-1].position)")
                print("Created \(self.boardSize * self.boardSize) tiles for \(self.boardSize)×\(self.boardSize) board")
            }
        }
        
        // Adjust score and moves labels position with enhanced styling
        scoreLabel = createStyledLabel(text: "Score: 0", fontSize: 26, isBold: true)
        if let scoreLabel = scoreLabel {
            scoreLabel.position = CGPoint(x: frame.midX - 150, y: frame.maxY - 100)
            addChild(scoreLabel)
        }
        
        movesLabel = createStyledLabel(text: "Moves: 0", fontSize: 26, isBold: true)
        if let movesLabel = movesLabel {
            movesLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 100)
            addChild(movesLabel)
        }
        
        // Add level label
        levelLabel = createStyledLabel(text: "Level: 1", fontSize: 26, isBold: true)
        if let levelLabel = levelLabel {
            levelLabel.position = CGPoint(x: frame.midX + 150, y: frame.maxY - 100)
            addChild(levelLabel)
        }
        
        // We'll create color point displays after the board is generated
        
        // Add prediction labels with better styling
        predictedMovesLabel = createStyledLabel(text: "Est. Min Moves: --", fontSize: 18, isBold: false)
        if let predictedMovesLabel = predictedMovesLabel {
            predictedMovesLabel.position = CGPoint(x: frame.midX - 120, y: frame.minY + 60)
            addChild(predictedMovesLabel)
        }
        
        predictedScoreLabel = createStyledLabel(text: "Est. Max Score: --", fontSize: 18, isBold: false)
        if let predictedScoreLabel = predictedScoreLabel {
            predictedScoreLabel.position = CGPoint(x: frame.midX + 120, y: frame.minY + 60)
            addChild(predictedScoreLabel)
        }
        
        // Add permanent restart button at the bottom
        setupRestartButton()
        
        // Initial tile colors
        randomizeTileColors()
        
        // Set top-left corner to purple
        if let tileShape = tiles[0][0].childNode(withName: "tileShape") as? SKShapeNode {
            tileShape.fillColor = purpleColor
            
            // Add glow effect to purple tiles
            addGlowEffect(to: tileShape)
        }
        
        // Create color point displays based on active tiles
        updateColorPointDisplay()
        
        // Make initial predictions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updatePredictions()
        }
        
        // Add game title at the top
        addGameTitle()
    }
    
    private func createGradientTexture(size: CGSize, startColor: SKColor, endColor: SKColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [startColor.cgColor, endColor.cgColor] as CFArray,
                locations: [0.0, 1.0]
            )!
            
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
        return SKTexture(image: image)
    }
    
    private func createStyledLabel(text: String, fontSize: CGFloat, isBold: Bool) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: isBold ? "AvenirNext-Bold" : "AvenirNext-Medium")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = gameTheme.textColor
        
        // Add subtle shadow to text
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        
        return label
    }
    
    private func addGameTitle() {
        let titleNode = SKNode()
        titleNode.position = CGPoint(x: frame.midX, y: frame.maxY - 50)
        
        let gameTitle = createStyledLabel(text: "PERPLEXEL", fontSize: 36, isBold: true)
        gameTitle.fontColor = purpleColor
        gameTitle.verticalAlignmentMode = .center
        gameTitle.horizontalAlignmentMode = .center
        
        // Add subtle shadow to the title
        let shadow = gameTitle.copy() as! SKLabelNode
        shadow.fontColor = SKColor.black.withAlphaComponent(0.3)
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        titleNode.addChild(shadow)
        
        titleNode.addChild(gameTitle)
        addChild(titleNode)
        
        // Add subtle animation to the title
        let scaleAction = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 1.0),
            SKAction.scale(to: 0.95, duration: 1.0)
        ])
        titleNode.run(SKAction.repeatForever(scaleAction))
    }
    
    private func addGlowEffect(to node: SKShapeNode) {
        // Remove any existing glow
        node.childNode(withName: "glow")?.removeFromParent()
        
        // Create a copy of the shape for the glow
        let glow = SKShapeNode(rectOf: CGSize(width: tileSize - tilePadding + 8,
                                            height: tileSize - tilePadding + 8),
                             cornerRadius: cornerRadius)
        glow.fillColor = .clear
        glow.strokeColor = purpleColor
        glow.lineWidth = 3
        glow.alpha = 0.5
        glow.zPosition = -1
        glow.name = "glow"
        
        // Add pulsing animation
        let pulseAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.7),
            SKAction.fadeAlpha(to: 0.4, duration: 0.7)
        ])
        glow.run(SKAction.repeatForever(pulseAction))
        
        node.addChild(glow)
    }
    
    private func createTile() -> SKNode {
        // Create container node
        let container = SKNode()
        
        // Create shadow/background tile with larger size
        let shadow = SKShapeNode(rectOf: CGSize(width: tileSize - tilePadding,
                                              height: tileSize - tilePadding),
                               cornerRadius: cornerRadius)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.lineWidth = 0
        shadow.position = CGPoint(x: 3, y: -3) // Slightly larger shadow offset
        container.addChild(shadow)
        
        // Create main tile with larger size
        let tile = SKShapeNode(rectOf: CGSize(width: tileSize - tilePadding,
                                            height: tileSize - tilePadding),
                             cornerRadius: cornerRadius)
        tile.fillColor = gameTheme.tileBaseColor
        tile.strokeColor = SKColor.white.withAlphaComponent(0.2)
        tile.lineWidth = 1
        tile.name = "tileShape"  // Add name to reference the shape
        
        // Add subtle shine effect to the tile
        let shine = SKShapeNode(rectOf: CGSize(width: (tileSize - tilePadding) * 0.7,
                                             height: (tileSize - tilePadding) * 0.2),
                              cornerRadius: cornerRadius * 0.5)
        shine.fillColor = SKColor.white.withAlphaComponent(0.2)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -5, y: 10)
        shine.zRotation = -0.3
        shine.alpha = 0.5
        shine.name = "shine"
        tile.addChild(shine)
        
        // Add initial appearance animation
        tile.setScale(0.8)
        tile.alpha = 0.0
        let appearAction = SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 0.0...0.3)),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.3),
                SKAction.fadeIn(withDuration: 0.3)
            ])
        ])
        tile.run(appearAction)
        
        container.addChild(tile)
        return container
    }
    
    private func randomizeTileColors() {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                // Skip the top-left corner (will be purple)
                if row == 0 && col == 0 {
                    continue
                }
                if let tile = tiles[row][col].childNode(withName: "tileShape") as? SKShapeNode {
                    tile.fillColor = tileColors.randomElement() ?? .darkGray
                }
            }
        }
    }
    
    private func setupRestartButton() {
        // Create restart button container
        let buttonContainer = SKNode()
        buttonContainer.name = "restartButton"
        buttonContainer.position = CGPoint(x: frame.midX, y: 60)
        buttonContainer.zPosition = 100
        
        // Create restart button with gradient background
        let buttonWidth: CGFloat = 140
        let buttonHeight: CGFloat = 50
        
        // Gradient texture for the button
        let gradientTexture = createGradientTexture(
            size: CGSize(width: buttonWidth, height: buttonHeight),
            startColor: purpleColor.withAlphaComponent(0.9),
            endColor: purpleColor.withAlphaComponent(0.7)
        )
        
        let restartButton = SKSpriteNode(texture: gradientTexture)
        restartButton.size = CGSize(width: buttonWidth, height: buttonHeight)
        restartButton.zPosition = 100
        
        // Add shape for rounded corners and border
        let buttonShape = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 25)
        buttonShape.fillColor = .clear
        buttonShape.strokeColor = SKColor.white.withAlphaComponent(0.6)
        buttonShape.lineWidth = 2
        buttonShape.zPosition = 101
        restartButton.addChild(buttonShape)
        
        // Add text label
        let buttonText = SKLabelNode(fontNamed: "AvenirNext-Bold")
        buttonText.text = "RESTART"
        buttonText.fontColor = .white
        buttonText.fontSize = 20
        buttonText.verticalAlignmentMode = .center
        buttonText.horizontalAlignmentMode = .center
        buttonText.zPosition = 102
        restartButton.addChild(buttonText)
        
        // Add button shadow
        let buttonShadow = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 25)
        buttonShadow.fillColor = SKColor.black.withAlphaComponent(0.3)
        buttonShadow.strokeColor = .clear
        buttonShadow.position = CGPoint(x: 3, y: -3)
        buttonShadow.zPosition = 99
        buttonContainer.addChild(buttonShadow)
        
        // Add button to container
        buttonContainer.addChild(restartButton)
        
        // Add subtle animation
        let buttonPulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 1.0),
            SKAction.scale(to: 0.95, duration: 1.0)
        ])
        buttonContainer.run(SKAction.repeatForever(buttonPulse))
        
        // Add to scene
        addChild(buttonContainer)
        
        // Add a debug gesture area that will print board state when tapped (invisible)
        if debugMode {
            let debugArea = SKShapeNode(rectOf: CGSize(width: 80, height: 40), cornerRadius: 10)
            debugArea.fillColor = .clear
            debugArea.strokeColor = debugMode ? .gray.withAlphaComponent(0.3) : .clear
            debugArea.position = CGPoint(x: frame.maxX - 50, y: frame.maxY - 30)
            debugArea.zPosition = 100
            debugArea.name = "debugButton"
            addChild(debugArea)
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if restart button was tapped (regardless of game state)
        let nodes = nodes(at: location)
        for node in nodes {
            if node.name == "restartButton" {
                restartGame()
                return
            } else if debugMode && node.name == "debugButton" {
                // Debug button was tapped, print the board state
                print("\n---------- MANUAL BOARD STATE CHECK ----------")
                printBoardState()
                print("---------- END MANUAL CHECK ----------\n")
                return
            }
        }
        
        // Don't proceed with tile handling if game is over
        if isGameOver {
            return
        }
        
        // Convert touch location to gameBoard coordinates
        guard let gameBoard = gameBoard else { return }
        let boardLocation = convert(location, to: gameBoard)
        
        // Log touch locations for debugging
        if debugMode {
            print("Scene touch: \(location)")
            print("Board touch: \(boardLocation)")
        }
        
        handleTileTap(at: boardLocation)
    }
    
    private func handleTileTap(at position: CGPoint) {
        // Calculate tile coordinates from board position
        let col = Int(position.x / tileSize)
        let row = Int(position.y / tileSize)
        
        if debugMode {
            print("Calculated tile: row: \(row), col: \(col)")
        }
        
        // Ensure the tap is within bounds
        guard row >= 0 && row < boardSize && col >= 0 && col < boardSize else {
            if debugMode {
                print("Tap outside board bounds")
            }
            return
        }
        
        // Get the tile node and shape
        let tileNode = tiles[row][col]
        guard let tileShape = tileNode.childNode(withName: "tileShape") as? SKShapeNode else {
            if debugMode {
                print("Could not find tile shape")
            }
            return
        }
        
        // If it's already purple, just do the animation without scoring
        if compareColors(color1: tileShape.fillColor, color2: purpleColor) {
            if debugMode {
                print("Tile already purple - showing animation only")
            }
            let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            tileShape.run(SKAction.sequence([scaleUp, scaleDown]))
            
            // Add a ripple effect
            addRippleEffect(at: tileNode.position)
            
            return
        }
        
        // Check if the tapped tile is adjacent to any purple tile
        guard isAdjacentToPurpleTile(row: row, col: col) else {
            if debugMode {
                print("Tile not adjacent to purple tile: (\(row), \(col))")
            }
            
            // Add a subtle "invalid" feedback animation
            let shakeAction = SKAction.sequence([
                SKAction.moveBy(x: 3, y: 0, duration: 0.05),
                SKAction.moveBy(x: -6, y: 0, duration: 0.05),
                SKAction.moveBy(x: 6, y: 0, duration: 0.05),
                SKAction.moveBy(x: -3, y: 0, duration: 0.05)
            ])
            tileShape.run(shakeAction)
            
            return
        }
        
        if debugMode {
            print("Valid tile tap - processing tile (\(row), \(col))")
        }
        
        // Get the color of the tapped tile
        let tappedColor = tileShape.fillColor
        
        // Find all adjacent tiles of the same color
        var tilesToChange: [(Int, Int)] = []
        findAdjacentTilesOfSameColor(row: row, col: col, color: tappedColor, tilesToChange: &tilesToChange)
        
        // Add the tapped tile itself if not already included
        if !tilesToChange.contains(where: { $0 == (row, col) }) {
            tilesToChange.append((row, col))
        }
        
        if debugMode {
            print("Tiles to change: \(tilesToChange.count)")
        }
        
        // Change all tiles to purple with staggered animations
        for (index, (tileRow, tileCol)) in tilesToChange.enumerated() {
            if let tileShape = tiles[tileRow][tileCol].childNode(withName: "tileShape") as? SKShapeNode {
                // Calculate delay based on distance from tapped tile
                let distance = sqrt(pow(Double(tileRow - row), 2) + pow(Double(tileCol - col), 2))
                let delay = min(distance * 0.05, 0.2)
                
                // Add an animation sequence
                let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
                let colorChange = SKAction.run {
                    // Don't use colorize action - directly set the color for exact RGB values
                    tileShape.fillColor = self.purpleColor
                }
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                
                let sequence = SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    scaleUp,
                    colorChange,
                    scaleDown
                ])
                
                tileShape.run(sequence) {
                    // Add glow effect after turning purple
                    self.addGlowEffect(to: tileShape)
                    
                    // Add a particle effect at the last tile to change
                    if index == tilesToChange.count - 1 {
                        self.addCaptureParticles(at: self.tiles[tileRow][tileCol].position)
                    }
                }
            }
        }
        
        // Add ripple effect at the tapped location
        addRippleEffect(at: tileNode.position)
        
        // Update score based on captured tiles
        updateScore(by: tilesToChange)
        
        // Update moves count
        updateMoves()
        
        // Update predictions after the move
        updatePredictions()
        
        // Check if the level is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.checkGameOver()
        }
    }
    
    private func isAdjacentToPurpleTile(row: Int, col: Int) -> Bool {
        // Check all four directions: up, right, down, left
        let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
        
        for (dx, dy) in directions {
            let newRow = row + dx
            let newCol = col + dy
            
            // Check if the new position is within bounds
            if newRow >= 0 && newRow < boardSize && newCol >= 0 && newCol < boardSize {
                if let adjacentTile = tiles[newRow][newCol].childNode(withName: "tileShape") as? SKShapeNode {
                    // If any adjacent tile is purple, return true
                    if compareColors(color1: adjacentTile.fillColor, color2: purpleColor) {
                        print("Found adjacent purple tile at (\(newRow), \(newCol))")
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func findAdjacentTilesOfSameColor(row: Int, col: Int, color: SKColor, tilesToChange: inout [(Int, Int)]) {
        // Check all four directions: up, right, down, left
        let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
        
        for (dx, dy) in directions {
            let newRow = row + dx
            let newCol = col + dy
            
            // Check if the new position is within bounds
            if newRow >= 0 && newRow < boardSize && newCol >= 0 && newCol < boardSize {
                // Skip if this position is already in our list to avoid infinite recursion
                if tilesToChange.contains(where: { $0 == (newRow, newCol) }) {
                    continue
                }
                
                if let adjacentTile = tiles[newRow][newCol].childNode(withName: "tileShape") as? SKShapeNode {
                    // Check if the adjacent tile has the same color
                    let sameColor = compareColors(color1: adjacentTile.fillColor, color2: color)
                    if sameColor {
                        print("Found same color tile at (\(newRow), \(newCol))")
                        tilesToChange.append((newRow, newCol))
                        
                        // Recursively check adjacent tiles of the same color
                        findAdjacentTilesOfSameColor(row: newRow, col: newCol, color: color, tilesToChange: &tilesToChange)
                    }
                }
            }
        }
    }
    
    // Helper function to compare colors with small epsilon
    private func compareColors(color1: SKColor, color2: SKColor) -> Bool {
        // For purple color, first try direct equality
        if color2 == purpleColor && color1 == purpleColor {
            return true
        }
        
        // Extra debugging for purple color checks
        let isPurpleCheck = color2 == purpleColor
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        // Safely get color components
        let success1 = color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        let success2 = color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        // If we couldn't get components, compare directly
        if !success1 || !success2 {
            return color1 == color2
        }
        
        // For purple checks, use a more relaxed epsilon
        let epsilon: CGFloat = isPurpleCheck ? 0.05 : 0.01
        
        // Compare with epsilon for floating point precision
        let redMatch = abs(r1 - r2) < epsilon
        let greenMatch = abs(g1 - g2) < epsilon
        let blueMatch = abs(b1 - b2) < epsilon
        
        let isMatch = redMatch && greenMatch && blueMatch
        
        // Extra debug logging for purple color comparisons
        if debugMode && isPurpleCheck && !isMatch {
            // Calculate total difference to help identify how close it is
            let totalDiff = abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
            print("Purple color mismatch: R:\(r1) vs \(r2), G:\(g1) vs \(g2), B:\(b1) vs \(b2), total diff: \(totalDiff)")
            
            // If it's very close to purple but not matching, log additional details
            if totalDiff < 0.1 {
                print("WARNING: Color is close to purple but not matching! Epsilon: \(epsilon)")
            }
        }
        
        return isMatch
    }
    
    private func updateScore(by tilesToChange: [(Int, Int)]) {
        guard !tilesToChange.isEmpty else { return }
        
        // Check if the indices are valid
        let row = tilesToChange[0].0
        let col = tilesToChange[0].1
        
        guard row >= 0 && row < boardSize && col >= 0 && col < boardSize else {
            print("Invalid tile indices for scoring")
            return
        }
        
        let tileNode = tiles[row][col]
        guard let tileShape = tileNode.childNode(withName: "tileShape") as? SKShapeNode else {
            print("Could not find tile shape node")
            return
        }
        
        // Get the color of the changed tiles
        let baseColor = tileShape.fillColor
        
        // Don't award points if the tiles were already purple
        if compareColors(color1: baseColor, color2: purpleColor) {
            if debugMode {
                print("No points awarded - tiles were already purple")
            }
            return
        }
        
        // Find the matching color in our color points dictionary
        var matchedColorKey: SKColor? = nil
        var basePoints = 10 // Default points if no match found
        
        // Try to find exact match for the color in our dictionary
        for (colorKey, points) in colorPoints {
            if compareColors(color1: baseColor, color2: colorKey) {
                matchedColorKey = colorKey
                basePoints = points
                break
            }
        }
        
        if debugMode {
            if matchedColorKey != nil {
                print("Found matching color in points dictionary: \(basePoints) points")
            } else {
                print("WARNING: No color match found in points dictionary, using default: \(basePoints) points")
                
                // Log the color details for debugging
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                baseColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                print("Color RGB: \(r), \(g), \(b)")
            }
        }
        
        // Calculate combo multiplier
        let comboMultiplier = comboMultipliers[tilesToChange.count] ?? 1
        
        // Calculate total points for this move
        let points = basePoints * tilesToChange.count * comboMultiplier
        currentScore += points
        
        // Update score label
        scoreLabel?.text = "Score: \(currentScore)"
        
        if debugMode {
            print("Scored \(points) points for \(tilesToChange.count) tiles of base value \(basePoints) with multiplier \(comboMultiplier)")
        }
        
        // Show score animation at the position of the first tile
        if let gameBoard = gameBoard {
            // Convert tile position to scene coordinates for the animation
            let tilePosition = tileNode.position
            let worldPosition = gameBoard.convert(tilePosition, to: self)
            
            showScoreAnimation(points: points, at: worldPosition)
        }
    }
    
    private func showScoreAnimation(points: Int, at position: CGPoint) {
        // Create score node with better styling
        let scoreNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreNode.text = "+\(points)"
        scoreNode.fontSize = 30
        scoreNode.fontColor = .white
        scoreNode.zPosition = 100
        
        // Add glow effect
        let glow = SKEffectNode()
        glow.shouldRasterize = true
        glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 2.0])
        glow.addChild(scoreNode)
        glow.position = position
        
        // Add to scene
        addChild(glow)
        scoreAnimations.append(glow)
        
        // Enhanced animation sequence with more dynamic movement
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.2, duration: 0.1)
        
        // Random horizontal movement for more natural feel
        let randomX = CGFloat.random(in: -20...20)
        let moveUp = SKAction.moveBy(x: randomX, y: 80, duration: 1.0)
        
        // Ease-out for more natural movement
        moveUp.timingMode = .easeOut
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        fadeOut.timingMode = .easeIn
        
        let sequence = SKAction.sequence([
            scaleUp,
            scaleDown,
            SKAction.group([
                moveUp,
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.6),
                    fadeOut
                ])
            ]),
            SKAction.removeFromParent()
        ])
        
        glow.run(sequence) { [weak self] in
            if let index = self?.scoreAnimations.firstIndex(of: glow) {
                self?.scoreAnimations.remove(at: index)
            }
        }
    }
    
    private func updateMoves() {
        movesCount += 1
        movesLabel?.text = "Moves: \(movesCount)"
    }
    
    private func checkGameOver() {
        // Check if all tiles are purple
        var allPurple = true
        
        // Enhanced logging for debugging
        var nonPurpleCount = 0
        
        if debugMode {
            print("\n---------- CHECKING GAME OVER CONDITION ----------")
            // Print the board state for debugging
            printBoardState()
        }
        
        // Check each tile with detailed logging
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if let tile = tiles[row][col].childNode(withName: "tileShape") as? SKShapeNode {
                    let isPurple = compareColors(color1: tile.fillColor, color2: purpleColor)
                    if !isPurple {
                        allPurple = false
                        nonPurpleCount += 1
                        
                        // Print detailed color information for debugging
                        if debugMode {
                            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                            tile.fillColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                            print("Found non-purple tile at (\(row), \(col)) with color: R:\(r), G:\(g), B:\(b), A:\(a)")
                        }
                    }
                }
            }
        }
        
        // Set allPurple based on nonPurpleCount, regardless of debug mode
        allPurple = (nonPurpleCount == 0)
        
        if debugMode {
            print("Level check: \(nonPurpleCount) non-purple tiles remain")
        
            if nonPurpleCount > 0 {
                print("Level not complete - continuing game")
            } else {
                print("All tiles confirmed purple. Level complete!")
            }
        }
        
        if allPurple {
            if debugMode {
                print("All tiles are purple! Level complete.")
            }
            // Level completed
            if currentLevel < 10 {  // Maximum level cap
                levelUp()
            } else {
                // Final game over at level 10
                showGameOver()
            }
        } else if debugMode {
            print("Level not complete - continuing game")
        }
        
        if debugMode {
            print("---------- END GAME OVER CHECK ----------\n")
        }
    }
    
    // Debug function to print the entire board state
    private func printBoardState() {
        print("\n========== BOARD STATE ==========")
        print("Board size: \(boardSize)x\(boardSize)")
        print("Purple color reference: R:0.608 G:0.349 B:0.714")
        
        var purpleTileCount = 0
        var nonPurpleTileCount = 0
        var suspiciousTileCount = 0
        
        for row in 0..<boardSize {
            var rowString = "Row \(row): "
            for col in 0..<boardSize {
                if let tile = tiles[row][col].childNode(withName: "tileShape") as? SKShapeNode {
                    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    tile.fillColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                    
                    let isPurple = compareColors(color1: tile.fillColor, color2: purpleColor)
                    let status = isPurple ? "P" : "X"
                    
                    // Calculate the difference from purple color for debugging
                    let rDiff = abs(r - 0.608)
                    let gDiff = abs(g - 0.349)
                    let bDiff = abs(b - 0.714)
                    let isCloseToPurple = rDiff < 0.02 && gDiff < 0.02 && bDiff < 0.02
                    
                    if isPurple {
                        purpleTileCount += 1
                    } else {
                        nonPurpleTileCount += 1
                        
                        // Mark suspicious tiles that are close to purple but not detected as purple
                        if isCloseToPurple {
                            suspiciousTileCount += 1
                            rowString += "[S(\(row),\(col))R:\(String(format: "%.3f", r))G:\(String(format: "%.3f", g))B:\(String(format: "%.3f", b))Δ:\(String(format: "%.3f", rDiff+gDiff+bDiff))] "
                        } else {
                            rowString += "[X(\(row),\(col))R:\(String(format: "%.3f", r))G:\(String(format: "%.3f", g))B:\(String(format: "%.3f", b))] "
                        }
                    }
                } else {
                    rowString += "[Missing] "
                }
            }
            print(rowString)
        }
        
        print("Purple tiles: \(purpleTileCount), Non-purple: \(nonPurpleTileCount), Suspicious: \(suspiciousTileCount)")
        print("Total tiles: \(purpleTileCount + nonPurpleTileCount) of \(boardSize * boardSize) expected")
        print("=================================\n")
    }
    
    private func levelUp() {
        // Create a full-screen flash effect
        let flash = SKShapeNode(rectOf: CGSize(width: frame.width, height: frame.height))
        flash.fillColor = SKColor.white
        flash.strokeColor = .clear
        flash.alpha = 0
        flash.zPosition = 90
        flash.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(flash)
        
        // Flash animation
        let flashAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ])
        flash.run(flashAction)
        
        // Show level complete message with enhanced styling
        let levelCompleteNode = SKNode()
        levelCompleteNode.position = CGPoint(x: frame.midX, y: frame.midY)
        levelCompleteNode.zPosition = 100
        levelCompleteNode.alpha = 0
        addChild(levelCompleteNode)
        
        // Background for the level complete message
        let messageBg = SKShapeNode(rectOf: CGSize(width: 300, height: 200), cornerRadius: 20)
        messageBg.fillColor = purpleColor.withAlphaComponent(0.9)
        messageBg.strokeColor = SKColor.white.withAlphaComponent(0.5)
        messageBg.lineWidth = 2
        messageBg.alpha = 0.9
        levelCompleteNode.addChild(messageBg)
        
        // Add a particle effect behind the message
        if let particles = SKEmitterNode(fileNamed: "Confetti") {
            particles.position = CGPoint(x: 0, y: 0)
            particles.particleBirthRate = 100
            particles.numParticlesToEmit = 200
            particles.zPosition = -1
            levelCompleteNode.addChild(particles)
        }
        
        // Level complete text
        let levelCompleteLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        levelCompleteLabel.text = "Level \(currentLevel) Complete!"
        levelCompleteLabel.fontSize = 32
        levelCompleteLabel.fontColor = .white
        levelCompleteLabel.position = CGPoint(x: 0, y: 30)
        levelCompleteNode.addChild(levelCompleteLabel)
        
        // Show bonus points for completing the level
        let levelBonus = currentLevel * 100
        currentScore += levelBonus
        
        // Update score label
        scoreLabel?.text = "Score: \(currentScore)"
        
        // Show bonus score animation
        let bonusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        bonusLabel.text = "Level Bonus: +\(levelBonus)"
        bonusLabel.fontSize = 26
        bonusLabel.fontColor = SKColor.yellow
        bonusLabel.position = CGPoint(x: 0, y: -20)
        levelCompleteNode.addChild(bonusLabel)
        
        // Stars or achievement indicator
        addStars(to: levelCompleteNode, count: min(currentLevel, 5), y: -60)
        
        // Animate level complete message
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut])
        
        levelCompleteNode.run(sequence) { [weak self] in
            guard let self = self else { return }
            levelCompleteNode.removeFromParent()
            
            // Increment level and update label
            self.currentLevel += 1
            self.levelLabel?.text = "Level: \(self.currentLevel)"
            
            // Reset tiles but keep score
            self.resetBoardForNewLevel()
            
            if self.debugMode {
                print("Advanced to Level \(self.currentLevel)")
            }
        }
    }
    
    private func addStars(to parent: SKNode, count: Int, y: CGFloat) {
        let starSize: CGFloat = 30
        let totalWidth = CGFloat(count) * starSize * 1.5
        let startX = -totalWidth / 2 + starSize / 2
        
        for i in 0..<count {
            let star = SKSpriteNode(imageNamed: "star")
            star.size = CGSize(width: starSize, height: starSize)
            star.position = CGPoint(x: startX + CGFloat(i) * starSize * 1.5, y: y)
            star.setScale(0.1)
            parent.addChild(star)
            
            // Animate each star with a delay
            let delay = 0.1 * Double(i)
            let popIn = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: 1.3, duration: 0.3),
                    SKAction.fadeIn(withDuration: 0.2)
                ]),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            star.run(popIn)
            
            // Add subtle rotation animation
            let rotation = SKAction.rotate(byAngle: .pi * 2, duration: 3.0)
            star.run(SKAction.repeatForever(rotation))
        }
    }
    
    private func resetBoardForNewLevel() {
        // Reset board state but keep score
        movesCount = 0
        movesLabel?.text = "Moves: 0"
        isGameOver = false
        
        // Reset all tiles with animation
        for row in tiles {
            for tileNode in row {
                if let tileShape = tileNode.childNode(withName: "tileShape") as? SKShapeNode {
                    let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.2)
                    let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
                    tileShape.run(SKAction.sequence([fadeOut, fadeIn]))
                }
            }
        }
        
        // Create new level with appropriate difficulty
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            // Generate level with appropriate difficulty
            self.generateLevelWithDifficulty(level: self.currentLevel)
            
            // Update predictions for new level
            self.updatePredictions()
            
            if self.debugMode {
                print("Advanced to Level \(self.currentLevel)")
            }
        }
    }
    
    private func generateLevelWithDifficulty(level: Int) {
        // Adjust difficulty based on level with more gradual progression
        // Start with just 2 colors at level 1, then add more colors gradually
        let usedColors = min(2 + (level - 1) / 3, tileColors.count)
        
        // Special tiles appear starting from level 3, gradually increasing chance
        let specialTileChance = level <= 2 ? 0.0 : min(0.05 + Double(level-3) * 0.02, 0.3)
        
        // Start with simpler patterns, then get more complex
        let patternDifficulty = level <= 4 ? 0 : level - 4
        
        if debugMode {
            print("Level \(level) - Using \(usedColors) colors, special tile chance: \(specialTileChance), pattern difficulty: \(patternDifficulty)")
        }
        
        // Generate board with increasing difficulty
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                // Skip the top-left corner (will be purple)
                if row == 0 && col == 0 {
                    if let tileShape = tiles[row][col].childNode(withName: "tileShape") as? SKShapeNode {
                        tileShape.fillColor = purpleColor
                    }
                    continue
                }
                
                if let tileShape = tiles[row][col].childNode(withName: "tileShape") as? SKShapeNode {
                    // Use a subset of colors based on level difficulty
                    // At level 1, favor easier colors (more adjacent similar colors)
                    var colorIndex: Int
                    
                    if level == 1 {
                        // Level 1: Make it easier with more patterns of same colors
                        // Use position-based pattern to create clusters of same color
                        colorIndex = (row + col) % 2
                    } else if level == 2 {
                        // Level 2: Slightly more random but still with some patterns
                        colorIndex = (row * col) % usedColors
                    } else {
                        // Higher levels: More randomness
                        colorIndex = Int.random(in: 0..<usedColors)
                    }
                    
                    tileShape.fillColor = tileColors[colorIndex]
                    
                    // Apply special patterns for higher levels
                    if level >= 5 && row % 3 == 0 && col % 3 == 0 {
                        // Create some fixed pattern tiles for special challenges in higher levels
                        tileShape.fillColor = tileColors[0]  // Always red in fixed positions
                    }
                    
                    // Special tiles chance increases with level
                    if level >= 3 && Double(Int.random(in: 0...100)) / 100.0 < specialTileChance {
                        // Use higher value colors for special tiles
                        tileShape.fillColor = tileColors[min(usedColors - 1, tileColors.count - 1)]
                    }
                }
            }
        }
        
        // Create special patterns from level 6 onwards
        if level >= 6 {
            // The interval determines how dense the pattern is (higher = less dense)
            let interval = max(2, 8 - patternDifficulty)
            createCheckerboardPattern(interval: interval)
        }
        
        // Update the display to show only colors present in this level
        updateColorPointDisplay()
    }
    
    private func createCheckerboardPattern(interval: Int) {
        // Create a checkerboard or other pattern to increase difficulty
        // The smaller the interval, the more dense the pattern
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                // Skip the top-left corner (will be purple)
                if row == 0 && col == 0 {
                    continue
                }
                
                // Different pattern types based on interval:
                // - Even intervals create checkerboard-like patterns
                // - Odd intervals create striped patterns
                let shouldChange: Bool
                
                if interval % 2 == 0 {
                    // Checkerboard pattern
                    shouldChange = (row + col) % interval == 0
                } else {
                    // Striped pattern
                    shouldChange = (row % interval == 0) || (col % interval == 0)
                }
                
                if shouldChange {
                    if let tileShape = tiles[row][col].childNode(withName: "tileShape") as? SKShapeNode {
                        // Use different colors based on position to create visual patterns
                        let patternColorIndex = ((row * col) % tileColors.count)
                        tileShape.fillColor = tileColors[patternColorIndex]
                    }
                }
            }
        }
    }
    
    private func showGameOver() {
        isGameOver = true
        
        // Add dark overlay with gradients
        let overlay = SKShapeNode(rectOf: CGSize(width: frame.width, height: frame.height))
        let gradientTexture = createGradientTexture(
            size: CGSize(width: frame.width, height: frame.height),
            startColor: SKColor.black.withAlphaComponent(0.7),
            endColor: SKColor.black.withAlphaComponent(0.9)
        )
        
        let overlaySprite = SKSpriteNode(texture: gradientTexture)
        overlaySprite.size = CGSize(width: frame.width, height: frame.height)
        overlaySprite.position = CGPoint(x: frame.midX, y: frame.midY)
        overlaySprite.zPosition = 90
        addChild(overlaySprite)
        
        // Add particle effect
        if let particles = SKEmitterNode(fileNamed: "MagicParticles") {
            particles.position = CGPoint(x: frame.midX, y: frame.midY)
            particles.zPosition = 91
            particles.particleAlpha = 0.5
            addChild(particles)
        }
        
        // Create container for game over content
        let gameOverContainer = SKNode()
        gameOverContainer.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOverContainer.zPosition = 95
        addChild(gameOverContainer)
        
        // Set up game over label with animation
        gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        if let gameOverLabel = gameOverLabel {
            gameOverLabel.text = "GAME COMPLETE!"
            gameOverLabel.fontSize = 48
            gameOverLabel.fontColor = .white
            gameOverLabel.position = CGPoint(x: 0, y: 120)
            gameOverLabel.zPosition = 100
            gameOverLabel.alpha = 0
            
            // Add glow behind text
            let glow = SKEffectNode()
            glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 4.0])
            let glowLabel = gameOverLabel.copy() as! SKLabelNode
            glowLabel.fontColor = purpleColor
            glowLabel.position = CGPoint.zero
            glow.addChild(glowLabel)
            glow.position = gameOverLabel.position
            glow.alpha = 0
            gameOverContainer.addChild(glow)
            
            gameOverContainer.addChild(gameOverLabel)
            
            // Animate game over label
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            let fadeIn = SKAction.fadeIn(withDuration: 0.5)
            
            gameOverLabel.run(SKAction.sequence([fadeIn, scaleUp, scaleDown]))
            glow.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.2),
                SKAction.fadeAlpha(to: 0.7, duration: 0.3)
            ]))
        }
        
        // Add trophy or achievement icon
        let trophy = SKSpriteNode(imageNamed: "trophy")
        trophy.size = CGSize(width: 80, height: 80)
        trophy.position = CGPoint(x: 0, y: 50)
        trophy.zPosition = 100
        trophy.alpha = 0
        trophy.setScale(0.5)
        gameOverContainer.addChild(trophy)
        
        // Animate trophy
        let trophyAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.scale(to: 1.2, duration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.2)
            ])
        ])
        trophy.run(trophyAction)
        
        // Add final score panel
        let scorePanel = SKShapeNode(rectOf: CGSize(width: 300, height: 180), cornerRadius: 20)
        scorePanel.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 0.9)
        scorePanel.strokeColor = SKColor.white.withAlphaComponent(0.3)
        scorePanel.lineWidth = 2
        scorePanel.position = CGPoint(x: 0, y: -40)
        scorePanel.zPosition = 96
        scorePanel.alpha = 0
        gameOverContainer.addChild(scorePanel)
        
        // Animate score panel
        scorePanel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.9),
            SKAction.fadeIn(withDuration: 0.5)
        ]))
        
        // Add stats with enhanced styling
        let statsNode = SKNode()
        statsNode.position = scorePanel.position
        statsNode.zPosition = 97
        gameOverContainer.addChild(statsNode)
        
        // Add final score with animated counting
        let finalScoreLabel = createStyledLabel(text: "Final Score", fontSize: 26, isBold: true)
        finalScoreLabel.position = CGPoint(x: 0, y: 30)
        finalScoreLabel.alpha = 0
        statsNode.addChild(finalScoreLabel)
        
        let scoreValueLabel = createStyledLabel(text: "\(currentScore)", fontSize: 40, isBold: true)
        scoreValueLabel.fontColor = SKColor.yellow
        scoreValueLabel.position = CGPoint(x: 0, y: 0)
        scoreValueLabel.alpha = 0
        statsNode.addChild(scoreValueLabel)
        
        // Add level reached
        let finalLevelLabel = createStyledLabel(text: "Level Reached: \(currentLevel)", fontSize: 24, isBold: true)
        finalLevelLabel.position = CGPoint(x: 0, y: -40)
        finalLevelLabel.alpha = 0
        statsNode.addChild(finalLevelLabel)
        
        // Add moves count
        let finalMovesLabel = createStyledLabel(text: "Total Moves: \(movesCount)", fontSize: 24, isBold: true)
        finalMovesLabel.position = CGPoint(x: 0, y: -70)
        finalMovesLabel.alpha = 0
        statsNode.addChild(finalMovesLabel)
        
        // Animate stats appearance with sequence
        let fadeInStats = SKAction.fadeIn(withDuration: 0.4)
        
        finalScoreLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.1),
            fadeInStats
        ]))
        
        scoreValueLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.3),
            fadeInStats
        ]))
        
        finalLevelLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            fadeInStats
        ]))
        
        finalMovesLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.7),
            fadeInStats
        ]))
        
        // Add new game button with enhanced styling
        let newGameButton = SKNode()
        newGameButton.name = "restartButton"
        newGameButton.position = CGPoint(x: 0, y: -150)
        newGameButton.zPosition = 100
        newGameButton.alpha = 0
        gameOverContainer.addChild(newGameButton)
        
        // Button background with gradient
        let buttonGradient = createGradientTexture(
            size: CGSize(width: 200, height: 50),
            startColor: purpleColor,
            endColor: purpleColor.withAlphaComponent(0.8)
        )
        
        let buttonBg = SKSpriteNode(texture: buttonGradient)
        buttonBg.size = CGSize(width: 200, height: 50)
        newGameButton.addChild(buttonBg)
        
        // Button border
        let buttonBorder = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 25)
        buttonBorder.fillColor = .clear
        buttonBorder.strokeColor = SKColor.white.withAlphaComponent(0.8)
        buttonBorder.lineWidth = 2
        newGameButton.addChild(buttonBorder)
        
        // Button text
        let newGameText = createStyledLabel(text: "New Game", fontSize: 26, isBold: true)
        newGameText.position = CGPoint(x: 0, y: 0)
        newGameButton.addChild(newGameText)
        
        // Animate button
        newGameButton.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeIn(withDuration: 0.5)
        ]))
        
        // Add button animation
        let buttonPulse = SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.5),
                SKAction.scale(to: 0.95, duration: 0.5)
            ]))
        ])
        newGameButton.run(buttonPulse)
    }
    
    private func restartGame() {
        // Remove game over screen
        for child in children {
            if child.zPosition >= 90 && child.name != "restartButton" {
                child.removeFromParent()
            }
        }
        
        // Reset game state
        isGameOver = false
        currentScore = 0
        movesCount = 0
        currentLevel = 1
        
        // Update UI
        scoreLabel?.text = "Score: 0"
        movesLabel?.text = "Moves: 0"
        levelLabel?.text = "Level: 1"
        
        // Reset all tiles with animation
        for row in tiles {
            for tileNode in row {
                if let tileShape = tileNode.childNode(withName: "tileShape") as? SKShapeNode {
                    let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.2)
                    let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
                    tileShape.run(SKAction.sequence([fadeOut, fadeIn]))
                }
            }
        }
        
        // Create new level with appropriate difficulty
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            // Generate level with appropriate difficulty
            self.generateLevelWithDifficulty(level: 1)
            
            // Update predictions for new game
            self.updatePredictions()
            
            if self.debugMode {
                print("Game restarted")
            }
        }
    }
    
    // MARK: - Game Prediction Logic
    
    private func updatePredictions() {
        // Simplified prediction algorithm
        let (minMoves, maxScore) = predictGameOutcome()
        
        // Update prediction labels
        predictedMovesLabel?.text = "Est. Min Moves: \(minMoves)"
        predictedScoreLabel?.text = "Est. Max Score: \(maxScore)"
    }
    
    private func predictGameOutcome() -> (moves: Int, score: Int) {
        // Count the number of non-purple tiles
        var remainingTiles = 0
        var colorDistribution: [SKColor: Int] = [:]
        
        // Analyze current board state
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if let tile = tiles[row][col].childNode(withName: "tileShape") as? SKShapeNode {
                    let isPurple = compareColors(color1: tile.fillColor, color2: purpleColor)
                    if !isPurple {
                        remainingTiles += 1
                        
                        // Count color distribution
                        let color = tile.fillColor
                        colorDistribution[color] = (colorDistribution[color] ?? 0) + 1
                    }
                }
            }
        }
        
        // Simple prediction algorithm:
        // Assumes average 3 tiles per move, and that the player can find optimal moves
        let avgTilesPerMove = max(3.0, Double(remainingTiles) / 5.0)
        let estimatedMoves = Int(ceil(Double(remainingTiles) / avgTilesPerMove))
        
        // Estimate score based on average points per move
        var estimatedScore = currentScore
        let avgMoveScore = 15 * 3 * 2  // Average base points * average tiles * average multiplier
        estimatedScore += estimatedMoves * avgMoveScore
        
        return (estimatedMoves, estimatedScore)
    }
    
    private func updateColorPointDisplay() {
        // Remove any existing color point displays
        for node in colorInfoNodes {
            node.removeFromParent()
        }
        colorInfoNodes.removeAll()
        
        // Get the active colors in the current board
        var activeColors: Set<SKColor> = []
        
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                // Skip the purple tiles
                if let tile = tiles[row][col].childNode(withName: "tileShape") as? SKShapeNode {
                    if !compareColors(color1: tile.fillColor, color2: purpleColor) {
                        activeColors.insert(tile.fillColor)
                    }
                }
            }
        }
        
        // Convert to array and sort by point values (higher points first)
        let sortedColors = Array(activeColors).sorted { (color1, color2) -> Bool in
            let points1 = colorPoints[color1] ?? 0
            let points2 = colorPoints[color2] ?? 0
            return points1 > points2
        }
        
        // Create displays for each active color
        let colorInfoY = frame.maxY - 130
        var xOffset: CGFloat = -180 * Double(sortedColors.count - 1) / 2
        
        // Add a label explaining what these are
        let pointsHeaderLabel = SKLabelNode(fontNamed: "AvenirNext-Bold") 
        pointsHeaderLabel.text = "Tile Points"
        pointsHeaderLabel.fontSize = 16
        pointsHeaderLabel.fontColor = gameTheme.textColor
        pointsHeaderLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 160)
        pointsHeaderLabel.zPosition = 5
        addChild(pointsHeaderLabel)
        colorInfoNodes.append(pointsHeaderLabel)
        
        for color in sortedColors {
            let points = colorPoints[color] ?? 0
            
            // Create a container node for the color info
            let container = SKNode()
            container.position = CGPoint(x: frame.midX + xOffset, y: colorInfoY)
            container.zPosition = 5
            addChild(container)
            colorInfoNodes.append(container)
            
            // Container background with enhanced visuals
            let bg = SKShapeNode(rectOf: CGSize(width: 80, height: 30), cornerRadius: 12)
            bg.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.7)
            bg.strokeColor = SKColor.white.withAlphaComponent(0.3)
            bg.lineWidth = 1
            bg.position = CGPoint(x: 40, y: 0)
            container.addChild(bg)
            
            // Color sample - using actual tile appearance
            let colorBox = SKShapeNode(rectOf: CGSize(width: 24, height: 24), cornerRadius: 6)
            colorBox.fillColor = color
            colorBox.strokeColor = SKColor.white.withAlphaComponent(0.3)
            colorBox.lineWidth = 1
            colorBox.position = CGPoint(x: 20, y: 0)
            
            // Add shine effect like on tiles
            let shine = SKShapeNode(rectOf: CGSize(width: 14, height: 6), cornerRadius: 3)
            shine.fillColor = SKColor.white.withAlphaComponent(0.3)
            shine.strokeColor = .clear
            shine.position = CGPoint(x: -2, y: 5)
            shine.zRotation = -0.3
            colorBox.addChild(shine)
            
            container.addChild(colorBox)
            
            // Points text
            let pointsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            pointsLabel.text = "\(points)p"
            pointsLabel.fontSize = 18
            pointsLabel.fontColor = SKColor.white
            pointsLabel.position = CGPoint(x: 55, y: -7)
            pointsLabel.horizontalAlignmentMode = .center
            container.addChild(pointsLabel)
            
            // Add a subtle animation to the container
            container.setScale(0.9)
            container.alpha = 0
            
            let appearAction = SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.3),
                SKAction.fadeIn(withDuration: 0.3)
            ])
            container.run(appearAction)
            
            xOffset += 180
        }
    }
    
    private func addRippleEffect(at position: CGPoint) {
        guard let gameBoard = gameBoard else { return }
        
        let ripple = SKShapeNode(circleOfRadius: 10)
        ripple.position = position
        ripple.fillColor = .clear
        ripple.strokeColor = SKColor.white.withAlphaComponent(0.6)
        ripple.lineWidth = 2
        ripple.zPosition = 5
        gameBoard.addChild(ripple)
        
        let expand = SKAction.group([
            SKAction.scale(to: 3.0, duration: 0.5),
            SKAction.fadeOut(withDuration: 0.5)
        ])
        
        ripple.run(SKAction.sequence([expand, SKAction.removeFromParent()]))
    }
    
    private func addCaptureParticles(at position: CGPoint) {
        guard let gameBoard = gameBoard else { return }
        
        // Create a simple particle effect
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        emitter.position = position
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 50
        emitter.particleLifetime = 0.8
        emitter.particleScale = 0.4
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.2
        emitter.particleAlpha = 0.8
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -0.4
        emitter.particleColor = purpleColor
        emitter.particleColorBlendFactor = 0.8
        emitter.particleSpeed = 60
        emitter.particleSpeedRange = 20
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = CGFloat.pi * 2
        emitter.particleBlendMode = .add
        emitter.zPosition = 10
        
        gameBoard.addChild(emitter)
        
        // Remove the emitter after particles finish
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ])
        emitter.run(removeAction)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Game loop updates will go here
    }
}

