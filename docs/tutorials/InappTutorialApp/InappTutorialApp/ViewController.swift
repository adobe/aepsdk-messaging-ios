/*
 Copyright 2022 Adobe
 All Rights Reserved.
 
 NOTICE: Adobe permits you to use, modify, and distribute this file in
 accordance with the terms of the Adobe license agreement accompanying
 it.
 */

import UIKit
import AEPCore
import AEPAssurance

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func triggerInappMessage(_ : Any) {
        MobileCore.track(action: "50off", data: nil)
    }
    
    @IBAction func startQuickConnectSession() {
        Assurance.startSession()
    }
}

