//
//  cubitTests.swift
//  cubitTests
//
//  Created by Ivan Smirnov on 2025-04-06.
//

import Testing
import SpriteKit
@testable import cubit

struct cubitTests {
    
    // Test the initialization of the game board
    @Test func testGameBoardInitialization() async throws {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .aspectFill
        scene.didMove(to: SKView())
        
        // Access the private properties through reflection
        let mirror = Mirror(reflecting: scene)
        
        // Test board size is 8x8
        let boardSizeProperty = mirror.children.first { $0.label == "boardSize" }
        #expect(boardSizeProperty?.value as? Int == 8)
        
        // Test tile colors are initialized
        let tileColorsProperty = mirror.children.first { $0.label == "tileColors" }
        #expect(tileColorsProperty?.value as? [SKColor] != nil)
        
        // Test tiles array is created
        let tilesProperty = mirror.children.first { $0.label == "tiles" }
        #expect((tilesProperty?.value as? [[SKNode]])?.count == 8)
    }
    
    // Test the isAdjacentToPurpleTile functionality
    @Test func testAdjacentToPurpleTile() async throws {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .aspectFill
        scene.didMove(to: SKView())
        
        // Get the isAdjacentToPurpleTile method through reflection
        let isAdjacentToPurpleTileMethod = scene.perform(
            Selector(("isAdjacentToPurpleTile:col:")),
            with: 0,
            with: 1
        )
        
        // Initially only top-left (0,0) is purple, so (0,1) should be adjacent
        #expect(isAdjacentToPurpleTileMethod?.takeRetainedValue() as? Bool == true)
        
        // Position (1,1) is diagonal, not adjacent
        let isDiagonalAdjacent = scene.perform(
            Selector(("isAdjacentToPurpleTile:col:")),
            with: 1,
            with: 1
        )
        #expect(isDiagonalAdjacent?.takeRetainedValue() as? Bool == false)
    }
    
    // Test the findAdjacentTilesOfSameColor functionality
    @Test func testFindAdjacentTilesOfSameColor() async throws {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .aspectFill
        scene.didMove(to: SKView())
        
        // Set up a controlled test scenario by setting specific tile colors
        setupTestTileColors(scene)
        
        // Test finding adjacent tiles of the same color
        var tilesToChange: [(Int, Int)] = []
        let _ = scene.perform(
            Selector(("findAdjacentTilesOfSameColor:col:color:tilesToChange:")),
            with: 1,
            with: 1,
            with: SKColor.red,
            with: &tilesToChange
        )
        
        // Should find connected red tiles
        #expect(tilesToChange.count > 0)
    }
    
    // Test the game over condition
    @Test func testGameOverCondition() async throws {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .aspectFill
        scene.didMove(to: SKView())
        
        // Set all tiles to purple
        setAllTilesPurple(scene)
        
        // Check game over
        let _ = scene.perform(Selector(("checkGameOver")))
        
        // Game should be over
        let mirror = Mirror(reflecting: scene)
        let isGameOverProperty = mirror.children.first { $0.label == "isGameOver" }
        #expect(isGameOverProperty?.value as? Bool == true)
    }
    
    // Helper function to set up test tile colors
    private func setupTestTileColors(_ scene: GameScene) {
        // Get the tiles array through reflection
        let mirror = Mirror(reflecting: scene)
        guard let tilesProperty = mirror.children.first(where: { $0.label == "tiles" }),
              let tiles = tilesProperty.value as? [[SKNode]] else {
            return
        }
        
        // Set up a pattern of colored tiles for testing
        // Set (1,1), (1,2), (2,1) to red for testing adjacent colors
        if let tile1 = tiles[1][1].childNode(withName: "tileShape") as? SKShapeNode {
            tile1.fillColor = .red
        }
        if let tile2 = tiles[1][2].childNode(withName: "tileShape") as? SKShapeNode {
            tile2.fillColor = .red
        }
        if let tile3 = tiles[2][1].childNode(withName: "tileShape") as? SKShapeNode {
            tile3.fillColor = .red
        }
    }
    
    // Helper function to set all tiles to purple
    private func setAllTilesPurple(_ scene: GameScene) {
        // Get the tiles array through reflection
        let mirror = Mirror(reflecting: scene)
        guard let tilesProperty = mirror.children.first(where: { $0.label == "tiles" }),
              let tiles = tilesProperty.value as? [[SKNode]],
              let purpleColorProperty = mirror.children.first(where: { $0.label == "purpleColor" }),
              let purpleColor = purpleColorProperty.value as? SKColor else {
            return
        }
        
        // Set all tiles to purple
        for row in tiles {
            for tile in row {
                if let tileShape = tile.childNode(withName: "tileShape") as? SKShapeNode {
                    tileShape.fillColor = purpleColor
                }
            }
        }
    }
}
