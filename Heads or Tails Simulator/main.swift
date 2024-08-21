//
//  main.swift
//  Heads or Tails Simulator
//
//  Created by Daniel Bergquist on 4/17/16.
//  Copyright © 2016 Daniel Bergquist. All rights reserved.
//

import Foundation
import Cocoa
import Xorswift

let numberOfGames = 10000000     // How many separate games to run
let defaultLosses = 5           // Default number of losses a player
                                // can suffer before they are 'out'.

enum CoinValue {
    case heads
    case tails
}

enum Strategy {
    case random
    case alternating
    case holdOnWinSwitchOnLoss
    case holdOnLossSwitchOnWin
    case alwaysHeads
    case alwaysTails
//    case LastCoinToss  // This is the same as HoldOnWinSwitchOnLoss
//    case ReverseLastCoinToss // This is the same as HoldOnLossSwitchOnWin
}

enum PlayerStatus {
    case lost
    case out
    case stillIn
}


struct Player {
    fileprivate var originalGuess: CoinValue
    var currentGuess: CoinValue
    fileprivate var strategy: Strategy
    var lossesLeft: Int
    var additionalLosses: Int
    fileprivate var wins: Int
    var playerStatus: PlayerStatus = .stillIn

    init (playerStategy: Strategy, initalGuess: CoinValue, additionalLosses: Int = 0) {
        self.originalGuess = initalGuess
        self.currentGuess = initalGuess
        self.strategy = playerStategy
        self.lossesLeft = defaultLosses
        self.additionalLosses = 0   // Additional losses allowed the player (eg purchased more losses than average)
        self.wins = 0
    }
    
    fileprivate mutating func reset() {
        self.currentGuess = self.originalGuess
        self.playerStatus = .stillIn
        if (self.lossesLeft > 0) {
            self.wins = self.wins + 1
//            print("\(self.strategy) \(self.originalGuess) won")
        }
        self.lossesLeft = defaultLosses + self.additionalLosses
    }
    
    fileprivate mutating func retryToss() {
        self.lossesLeft = self.lossesLeft + 1
    }
    
    mutating func toggleGuess () {
        self.currentGuess = self.currentGuess == .heads ? .tails : .heads
    }
    
    mutating func strategize<T>(lost: Bool, using generator: inout T) where T : RandomNumberGenerator {
        switch self.strategy {
        case .random:
            self.currentGuess = Bool.random(using: &generator) ? .heads : .tails
        case .alternating:
            self.toggleGuess()
        case .holdOnWinSwitchOnLoss:
            if (lost) {
                self.toggleGuess()
            }
        case .holdOnLossSwitchOnWin:
            if (!lost) {
                self.toggleGuess()
            }
        case .alwaysHeads:
            break;
        case .alwaysTails:
            break;
        }
    }
    
    // Takes a coin toss result and evaluates if the player lost this round or not
    // Also strategizes for the next round based on this toss
    // returns if the player is still in the game
    mutating func evaluateCoinToss<T>(_ tossResult: CoinValue, using generator: inout T) where T : RandomNumberGenerator {

        var lost = false
        // Evaluate win/loss of this round
        if (self.currentGuess != tossResult) {
            self.lossesLeft = self.lossesLeft - 1
//            print("\(self.strategy) starting with \(self.originalGuess) has lost on coin toss \(tossResult) with guess \(self.currentGuess) and has \(self.lossesLeft) losses left")

            lost = true
        }
        
        playerStatus = self.lossesLeft > 0 ? .stillIn : .lost

        // stragegize
        self.strategize(lost: lost, using: &generator);
    }
}

//func randomAdditionalLosses() -> Int {
//    return Int(arc4random_uniform(7)) - 3
//}

func signupPlayers() -> [Player] {
    
    var players = [Player]()
    
    players.append(Player(playerStategy: .alternating, initalGuess: .heads))
    players.append(Player(playerStategy: .alternating, initalGuess: .tails))
    players.append(Player(playerStategy: .holdOnWinSwitchOnLoss, initalGuess: .heads))
    players.append(Player(playerStategy: .holdOnWinSwitchOnLoss, initalGuess: .tails))
    players.append(Player(playerStategy: .holdOnLossSwitchOnWin, initalGuess: .heads))
    players.append(Player(playerStategy: .holdOnLossSwitchOnWin, initalGuess: .tails))
    players.append(Player(playerStategy: .alwaysHeads, initalGuess: .heads))
    players.append(Player(playerStategy: .alwaysTails, initalGuess: .tails))

    return players
}

func runGames(_ numberOfGames: Int) -> [Player] {
    
    var players = signupPlayers()
    var randomNumberGenerator = XorshiftGenerator(x: arc4random(), y: arc4random(), z: arc4random(), w: arc4random())
    let playersCount = players.count
    for _ in 1...numberOfGames {

        var stillPlayingCount = playersCount
        while stillPlayingCount > 1 {

            let coinToss: CoinValue = Bool.random(using: &randomNumberGenerator) ? .heads : .tails

            for index in players.indices {
                if players[index].playerStatus == .stillIn {
                    players[index].evaluateCoinToss(coinToss, using: &randomNumberGenerator)
                }
            }

            stillPlayingCount = players.reduce(into: 0) { partialResult, player in
                if player.playerStatus == .stillIn {
                    partialResult += 1
                }
            }
            if (stillPlayingCount > 0) {
                for index in players.indices {
                    if players[index].playerStatus == .lost {
                        players[index].playerStatus = .out
                    }
                }
            } else {    // All players lost simultaneously
                for index in players.indices {
                    if players[index].playerStatus == .lost {
                        players[index].playerStatus = .stillIn
                        players[index].retryToss()
                        stillPlayingCount += 1
                    }
                }
            }
        }

        for index in players.indices {
            players[index].reset()
        }
//        players.forEach({
//            $0.reset()
//        })
    }
    
    DispatchQueue.main.async {
        print("Finished \(numberOfGames) games")
    }
    
    return players
}

func collectResults(_ gameResults: [Player]) {
    
    if (!Thread.isMainThread) {
        DispatchQueue.main.async {
            collectResults(gameResults)
        }
    }
    
    for player in gameResults {
        let key = "Strategy: \(player.strategy) Original Guess: \(player.originalGuess)"
        let wins: Int = (simulatorResults[key] != nil) ? simulatorResults[key]! : 0
        simulatorResults[key] = wins + player.wins
    }
}

var simulatorResults = [String:Int]()


let numberOfCPUs = ProcessInfo.processInfo.activeProcessorCount
let numberOfGamesPerCPU = numberOfGames / numberOfCPUs
let numberOfGamesPerCPURemainder = numberOfGames % numberOfCPUs

var gameGroup = DispatchGroup()

let gameQueue = DispatchQueue(label: "headsTailsGameQueue", attributes: DispatchQueue.Attributes.concurrent)
let resultsLock = NSLock()

let start = Date()
print("Start time: \(start)")
print("Playing \(numberOfGames) games")

// Run threaded games
for _ in 1...numberOfCPUs {
    gameGroup.enter()
    gameQueue.async {
        
        let results = runGames(numberOfGamesPerCPU)
        
        resultsLock.lock()
        
        collectResults(results)
        
        resultsLock.unlock()
        
        gameGroup.leave()
    }
}

let timeoutResult = gameGroup.wait(timeout: DispatchTime.distantFuture)

if timeoutResult == .timedOut {
    print("Game Timeout!");
}

// Couldn't divide evenly, run the remaining games
if (numberOfGamesPerCPURemainder > 0) {
    let results = runGames(numberOfGamesPerCPURemainder)
    
    collectResults(results)
}

let end = Date()
print("End time: \(end)")
print("Seconds: \(end.timeIntervalSince1970 - start.timeIntervalSince1970)")

var gamesRun = 0

for (resultKey, wins) in simulatorResults {
    print("\(resultKey) Total wins: \(wins)")
    gamesRun = gamesRun + wins
}

print("Total games run: \(gamesRun)")
