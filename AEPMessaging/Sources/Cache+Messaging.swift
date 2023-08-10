//
//  Cache+Messaging.swift
//  AEPMessaging
//
//  Created by steve benedick on 8/9/23.
//

import AEPServices
import Foundation

extension Cache {
    // MARK: - getters
    
    var propositions: [Surface: [Proposition]] {
        [:]
    }
    
    var propositionInfo: [String: PropositionInfo] {
        [:]
    }
    
    var inboundMessages: [Surface: [Inbound]] {
        [:]
    }
    
    // MARK: setters
    
    func setPropositions(_ propositions: [Surface: [Proposition]]) {
        
    }
    
    func setPropositionInfo(_ propositionInfo: [String: PropositionInfo]) {
        
    }
    
    func setInboundMessages(_ inboundMessages: [Surface: [Inbound]]) {
        
    }
}
