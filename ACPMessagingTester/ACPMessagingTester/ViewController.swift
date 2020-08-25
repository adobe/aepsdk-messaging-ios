//
//  ViewController.swift
//  ACPMessagingTester
//
//  Created by steve benedick on 6/22/20.
//  Copyright © 2020 adobe. All rights reserved.
//

import UIKit
import ACPMessaging
import ACPCore

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func collectMessageInfo(_ sender: Any) {
        let dict = ["eventType":"track.applicationOpened", "id":"31369", "applicationOpened":true] as [String : Any]
        ACPCore.collectMessageInfo(dict)
    }
}

