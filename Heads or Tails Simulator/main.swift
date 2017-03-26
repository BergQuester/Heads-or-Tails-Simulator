//
//  main.swift
//  Heads or Tails Simulator
//
//  Created by Daniel Bergquist on 4/17/16.
//  Copyright © 2016 Daniel Bergquist. All rights reserved.
//

import Foundation

//: Playground - noun: a place where people can play

import Cocoa

enum CoinValue {
    case heads
    case tails
}

enum Strategy {
    case random
    case alternating
    case holdOnWinSwitchOnLoss
    case holdOnLossSwitchOnWin
//    case LastCoinToss  // This is the same as HoldOnWinSwitchOnLoss
//    case ReverseLastCoinToss // This is the same as HoldOnLossSwitchOnWin
}

enum LostGame {
    case lost
    case stillIn
}


open class Player {
    fileprivate var originalGuess: CoinValue
    var currentGuess: CoinValue
    fileprivate var strategy: Strategy
    var lossesLeft: Int
    fileprivate var wins: Int
    
    init (playerStategy: Strategy, initalGuess: CoinValue) {
        self.originalGuess = initalGuess
        self.currentGuess = initalGuess
        self.strategy = playerStategy
        self.lossesLeft = 20
        self.wins = 0
    }
    
    fileprivate func reset() {
        self.currentGuess = self.originalGuess
        if (self.lossesLeft > 0) {
            self.wins = self.wins + 1
//            print("\(self.strategy) \(self.originalGuess) won")
        }
        self.lossesLeft = 20
    }
    
    fileprivate func retryToss() {
        self.lossesLeft = self.lossesLeft + 1
    }
    
    func toggleGuess () {
        self.currentGuess = self.currentGuess == .heads ? .tails : .heads
    }
    
    func evaluateCoinToss(_ tossResult: CoinValue) -> LostGame {
        
        var lost = false
        // Evaluate win/loss of this round
        if (self.currentGuess != tossResult) {
            self.lossesLeft = self.lossesLeft - 1
//            print("\(self.strategy) starting with \(self.originalGuess) has lost on coin toss \(tossResult) with guess \(self.currentGuess) and has \(self.lossesLeft) losses left")

            lost = true
        }
        
        
        // stragegize
        switch self.strategy {
        case .random:
            self.currentGuess = arc4random_uniform(2) == 0 ? .heads : .tails
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
//        case .LastCoinToss:
//            self.currentGuess = tossResult
//        case .ReverseLastCoinToss:
//            self.currentGuess = tossResult == .Heads ? .Tails : .Heads
        }
        
        return self.lossesLeft > 0 ? .stillIn : .lost
        
    }
}

func runGames(_ numberOfGames: Int) -> [Player] {
    
    let strategies = [Strategy.random, Strategy.alternating, Strategy.holdOnWinSwitchOnLoss, Strategy.holdOnLossSwitchOnWin, ]
    var players = [Player]()
    var playingPlayers = [Player]()


    for strategy in strategies {
        
        
        switch strategy {
        case Strategy.random:
            players.append(Player(playerStategy: strategy, initalGuess: .heads))
        case Strategy.alternating:
            players.append(Player(playerStategy: strategy, initalGuess: .heads))
            players.append(Player(playerStategy: strategy, initalGuess: .tails))
        case Strategy.holdOnWinSwitchOnLoss:
            players.append(Player(playerStategy: strategy, initalGuess: .heads))
    //        players.append(Player(playerStategy: strategy, initalGuess: .Tails))
        case Strategy.holdOnLossSwitchOnWin:
            players.append(Player(playerStategy: strategy, initalGuess: .heads))
    //        players.append(Player(playerStategy: strategy, initalGuess: .Tails))
    //    case Strategy.LastCoinToss:
    //        players.append(Player(playerStategy: strategy, initalGuess: .Heads))
    //    case Strategy.ReverseLastCoinToss:
    //        players.append(Player(playerStategy: strategy, initalGuess: .Heads))
        }
    }

    for _ in 1...numberOfGames {
        
    //    print("Game \(game):")
        
        playingPlayers = players
        
    //    print("Starting players: \(playingPlayers.count)")
        while playingPlayers.count > 1 {
            
            let coinToss = arc4random_uniform(2) == 0 ? CoinValue.heads : CoinValue.tails
            
            let stillplayingPlayers = playingPlayers.filter({
                let playerResult = $0.evaluateCoinToss(coinToss)
                
                return playerResult == .stillIn
            })
            
            if (stillplayingPlayers.count > 0) {
                playingPlayers = stillplayingPlayers
            } else {    // All players lost simultaneously
                for player in playingPlayers {
                    player.retryToss()
                }
            }
        }

        players.forEach({
            $0.reset()
        })
    }
    
    return players
}

func collectResults(_ gameResults: [Player]) {
    for player in gameResults {
        let key = "Strategy: \(player.strategy) Original Guess: \(player.originalGuess)"
        let wins: Int = (simulatorResults[key] != nil) ? simulatorResults[key]! : 0
        simulatorResults[key] = wins + player.wins
    }
}

var simulatorResults = [String:Int]()


let numberOfGames = 1000000
let numberOfCPUs = ProcessInfo.processInfo.activeProcessorCount
let numberOfGamesPerCPU = numberOfGames / numberOfCPUs
let numberOfGamesPerCPURemainder = numberOfGames % numberOfCPUs

var gameGroup = DispatchGroup()

let gameQueue = DispatchQueue(label: "headsTailsGameQueue", attributes: DispatchQueue.Attributes.concurrent)
let resultsLock = NSLock()

print("\(Date())")

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

if (numberOfGamesPerCPURemainder > 0) {
    let results = runGames(numberOfGamesPerCPURemainder)
    
    collectResults(results)
}

print("\(Date())")

var gamesRun = 0

for (resultKey, wins) in simulatorResults {
    print("\(resultKey) Total wins: \(wins)")
    gamesRun = gamesRun + wins
}

print("Total games run: \(gamesRun)")
