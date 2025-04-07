# Perplexel

<img src="preview.png" alt="Perplexel Game" width="300"/>

## About

Perplexel is an engaging puzzle game where players strategically capture tiles by matching colors. Starting from a purple corner, expand your territory by tapping adjacent tiles of the same color, converting them to purple. The goal is to turn the entire board purple with as few moves as possible!

## Features

- 🧩 Simple yet challenging gameplay
- 🎮 10 increasingly difficult levels
- 🎯 Strategic depth with combo system
- 🏆 Score tracking and achievement system
- 🎨 Beautiful modern UI with animations
- 🌙 Dark mode aesthetics

## How to Play

1. The game starts with a purple tile in the top-left corner
2. Tap any tile adjacent to a purple tile that matches another colored tile
3. All connected tiles of that color will be captured and turn purple
4. Continue capturing until the entire board is purple
5. Complete the level with as few moves as possible for a higher score

## Scoring System

- Each colored tile has a point value (displayed at the top)
- Capturing multiple tiles in one move creates a combo multiplier:
  - 3 tiles: 2x points
  - 4 tiles: 3x points
  - 5 tiles: 4x points
  - 6 tiles: 5x points
  - 7 tiles: 6x points
  - 8+ tiles: 8x points
- Level completion awards a bonus of (level number × 100) points

## Development

Perplexel is built with Swift and SpriteKit for iOS. The game features:

- Custom tile-based board system
- Recursive adjacency algorithms for tile capture
- Particle effects and animations
- Multi-level progression system
- Predictive scoring system

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Run on your iOS device or simulator

## Credits

- Design & Development: Ivan Smirnov
- Created in 2023

## License

This project is protected by copyright law. All rights reserved. See the LICENSE file for details. Unauthorized copying, reproduction, or distribution is strictly prohibited. 