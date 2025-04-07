//
//  GameLogicTests.swift
//  cubitTests
//
//  Created by Ivan Smirnov on 2025-04-06.
//

import Testing
import SpriteKit
@testable import cubit

struct GameLogicTests {
    
    // Test the tile tap handling logic
    @Test func testTileTapHandling() async throws {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .aspectFill
        scene.didMove(to: SKView())
        
        // Set up a simple test board
        setupTestBoard(scene)
        
        // Get the gameBoard position through reflection
        let mirror = Mirror(reflecting: scene)
        guard let gameBoardProperty = mirror.children.first(where: { $0.label == "gameBoard" }),
              let gameBoard = gameBoardProperty.value as? SKNode else {
            #expect(false, "Game board not found")
            return
        }
        
        // Simulate tapping an adjacent tile
        let tileSize = 40.0
        let adjacentTilePosition = CGPoint(x: tileSize * 1.5, y: tileSize * 0.5) // Position of (0,1)
        
        // Call handleTileTap with the position
        let _ = scene.perform(
            Selector(("handleTileTap:")),
            with: adjacentTilePosition
        )
        
        // After tapping, check if tile (0,1) is now purple
        guard let tilesProperty = mirror.children.first(where: { $0.label == "tiles" }),
              let tiles = tilesProperty.value as? [[SKNode]],
              let purpleColorProperty = mirror.children.first(where: { $0.label == "purpleColor" }),
              let purpleColor = purpleColorProperty.value as? SKColor else {
            #expect(false, "Required properties not found")
            return
        }
        
        // Allow time for animations
        try await Task.sleep(for: .milliseconds(500))
        
        if let tileShape = tiles[0][1].childNode(withName: "tileShape") as? SKShapeNode {
            #expect(tileShape.fillColor == purpleColor, "Tile should have changed to purple")
        } else {
            #expect(false, "Tile shape not found")
        }
    }
    
    // Test score updating logic
    @Test func testScoreUpdating() async throws {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .aspectFill
        scene.didMove(to: SKView())
        
        // Set up a consistent board for testing
        setupTestBoard(scene)
        
        // Get the necessary properties through reflection
        let mirror = Mirror(reflecting: scene)
        guard let tilesProperty = mirror.children.first(where: { $0.label == "tiles" }),
              let tiles = tilesProperty.value as? [[SKNode]],
              let tileColorsProperty = mirror.children.first(where: { $0.label == "tileColors" }),
              let tileColors = tileColorsProperty.value as? [SKColor] else {
            #expect(false, "Required properties not found")
            return
        }
        
        // Set up a group of red tiles
        let tilesToChange = [(1, 1), (1, 2), (2, 1)]
        for (row, col) in tilesToChange {
            if let tileShape = tiles[row][col].childNode(withName: "tileShape") as? SKShapeNode {
                tileShape.fillColor = tileColors[0] // Red
            }
        }
        
        // Get the initial score
        guard let currentScoreProperty = mirror.children.first(where: { $0.label == "currentScore" }),
              var initialScore = currentScoreProperty.value as? Int else {
            #expect(false, "Current score not found")
            return
        }
        
        // Call updateScore method
        let _ = scene.perform(
            Selector(("updateScore:by:")),
            with: tilesToChange
        )
        
        // Get the updated score
        guard let updatedScoreProperty = mirror.children.first(where: { $0.label == "currentScore" }),
              let updatedScore = updatedScoreProperty.value as? Int else {
            #expect(false, "Updated score not found")
            return
        }
        
        // Score should have increased
        #expect(updatedScore > initialScore, "Score should have increased")
    }
    
    // Test game restart logic
    @Test func testGameRestart() async throws {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .aspectFill
        scene.didMove(to: SKView())
        
        // Set up the game to be over
        let mirror = Mirror(reflecting: scene)
        
        // Force game over state
        setGameOver(scene)
        
        // Call restartGame
        let _ = scene.perform(Selector(("restartGame")))
        
        // After restart, game should not be over
        guard let isGameOverProperty = mirror.children.first(where: { $0.label == "isGameOver" }),
              let isGameOver = isGameOverProperty.value as? Bool else {
            #expect(false, "isGameOver property not found")
            return
        }
        
        // Allow time for animations and async operations
        try await Task.sleep(for: .milliseconds(500))
        
        #expect(!isGameOver, "Game should not be over after restart")
        
        // Score and moves should be reset
        guard let currentScoreProperty = mirror.children.first(where: { $0.label == "currentScore" }),
              let currentScore = currentScoreProperty.value as? Int,
              let movesCountProperty = mirror.children.first(where: { $0.label == "movesCount" }),
              let movesCount = movesCountProperty.value as? Int else {
            #expect(false, "Score or moves properties not found")
            return
        }
        
        #expect(currentScore == 0, "Score should be reset to 0")
        #expect(movesCount == 0, "Moves should be reset to 0")
    }
    
    // Helper method to set up a consistent test board
    private func setupTestBoard(_ scene: GameScene) {
        let mirror = Mirror(reflecting: scene)
        guard let tilesProperty = mirror.children.first(where: { $0.label == "tiles" }),
              let tiles = tilesProperty.value as? [[SKNode]],
              let tileColorsProperty = mirror.children.first(where: { $0.label == "tileColors" }),
              let tileColors = tileColorsProperty.value as? [SKColor],
              let purpleColorProperty = mirror.children.first(where: { $0.label == "purpleColor" }),
              let purpleColor = purpleColorProperty.value as? SKColor else {
            return
        }
        
        // Set top-left tile to purple
        if let tileShape = tiles[0][0].childNode(withName: "tileShape") as? SKShapeNode {
            tileShape.fillColor = purpleColor
        }
        
        // Set consistent colors for adjacent tiles
        // (0,1) - Red
        if let tileShape = tiles[0][1].childNode(withName: "tileShape") as? SKShapeNode {
            tileShape.fillColor = tileColors[0] // Red
        }
        
        // (1,0) - Blue 
        if let tileShape = tiles[1][0].childNode(withName: "tileShape") as? SKShapeNode {
            tileShape.fillColor = tileColors[1] // Blue
        }
        
        // Create a cluster of same-colored tiles
        // (1,1), (1,2), (2,1) - Red
        for (row, col) in [(1, 1), (1, 2), (2, 1)] {
            if let tileShape = tiles[row][col].childNode(withName: "tileShape") as? SKShapeNode {
                tileShape.fillColor = tileColors[0] // Red
            }
        }
    }
    
    // Helper method to set game over state
    private func setGameOver(_ scene: GameScene) {
        // Set isGameOver directly using Key-Value Coding
        scene.setValue(true, forKey: "isGameOver")
        
        // Set a non-zero score and moves
        scene.setValue(100, forKey: "currentScore")
        scene.setValue(10, forKey: "movesCount")
    }
} 