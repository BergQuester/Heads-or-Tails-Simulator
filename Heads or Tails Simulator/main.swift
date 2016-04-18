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
    case Heads
    case Tails
}

enum Strategy {
    case Random
    case Alternating
    case HoldOnWinSwitchOnLoss
    case HoldOnLossSwitchOnWin
//    case LastCoinToss  // This is the same as HoldOnWinSwitchOnLoss
//    case ReverseLastCoinToss // This is the same as HoldOnLossSwitchOnWin
}

enum LostGame {
    case Lost
    case StillIn
}


public class Player {
    private var originalGuess: CoinValue
    var currentGuess: CoinValue
    private var strategy: Strategy
    var lossesLeft: Int
    private var wins: Int
    
    init (playerStategy: Strategy, initalGuess: CoinValue) {
        self.originalGuess = initalGuess
        self.currentGuess = initalGuess
        self.strategy = playerStategy
        self.lossesLeft = 20
        self.wins = 0
    }
    
    private func reset() {
        self.currentGuess = self.originalGuess
        if (self.lossesLeft > 0) {
            self.wins = self.wins + 1
//            print("\(self.strategy) \(self.originalGuess) won")
        }
        self.lossesLeft = 20
    }
    
    private func retryToss() {
        self.lossesLeft = self.lossesLeft + 1
    }
    
    func toggleGuess () {
        self.currentGuess = self.currentGuess == .Heads ? .Tails : .Heads
    }
    
    func evaluateCoinToss(tossResult: CoinValue) -> LostGame {
        
        var lost = false
        // Evaluate win/loss of this round
        if (self.currentGuess != tossResult) {
            self.lossesLeft = self.lossesLeft - 1
//            print("\(self.strategy) starting with \(self.originalGuess) has lost on coin toss \(tossResult) with guess \(self.currentGuess) and has \(self.lossesLeft) losses left")

            lost = true
        }
        
        
        // stragegize
        switch self.strategy {
        case .Random:
            self.currentGuess = arc4random() % 2 == 0 ? .Heads : .Tails
        case .Alternating:
            self.toggleGuess()
        case .HoldOnWinSwitchOnLoss:
            if (lost) {
                self.toggleGuess()
            }
        case .HoldOnLossSwitchOnWin:
            if (!lost) {
                self.toggleGuess()
            }
//        case .LastCoinToss:
//            self.currentGuess = tossResult
//        case .ReverseLastCoinToss:
//            self.currentGuess = tossResult == .Heads ? .Tails : .Heads
        }
        
        return self.lossesLeft > 0 ? .StillIn : .Lost
        
    }
}


let strategies = [Strategy.Random, Strategy.Alternating, Strategy.HoldOnWinSwitchOnLoss, Strategy.HoldOnLossSwitchOnWin, ]
var players = [Player]()
var playingPlayers = [Player]()


for strategy in strategies {
    
    
    switch strategy {
    case Strategy.Random:
        players.append(Player(playerStategy: strategy, initalGuess: .Heads))
    case Strategy.Alternating:
        players.append(Player(playerStategy: strategy, initalGuess: .Heads))
        players.append(Player(playerStategy: strategy, initalGuess: .Tails))
    case Strategy.HoldOnWinSwitchOnLoss:
        players.append(Player(playerStategy: strategy, initalGuess: .Heads))
//        players.append(Player(playerStategy: strategy, initalGuess: .Tails))
    case Strategy.HoldOnLossSwitchOnWin:
        players.append(Player(playerStategy: strategy, initalGuess: .Heads))
//        players.append(Player(playerStategy: strategy, initalGuess: .Tails))
//    case Strategy.LastCoinToss:
//        players.append(Player(playerStategy: strategy, initalGuess: .Heads))
//    case Strategy.ReverseLastCoinToss:
//        players.append(Player(playerStategy: strategy, initalGuess: .Heads))
    }
}

for game in 1...1000000 {
    
//    print("Game \(game):")
    
    playingPlayers = players
    
//    print("Starting players: \(playingPlayers.count)")
    while playingPlayers.count > 1 {
        
        let coinToss = arc4random_uniform(2) == 0 ? CoinValue.Heads : CoinValue.Tails
        
        let stillplayingPlayers = playingPlayers.filter({
            let playerResult = $0.evaluateCoinToss(coinToss)
            
            return playerResult == .StillIn
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

var results = ""

for player in players {
    results = results + "Strategy: \(player.strategy) Original Guess: \(player.originalGuess) Total wins: \(player.wins)\n"
}

print(results)

