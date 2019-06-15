//
//  ViewController.swift
//  Demo
//
//  Created by Kevin Sum on 30/5/2019.
//  Copyright © 2019 Kevin Sum. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var clock1: KSClockView!
    @IBOutlet weak var clock2: KSClockView!
    @IBOutlet weak var clock3: KSClockView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clock1.clockViewDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm";
        if let date = formatter.date(from: "09:00") {
            clock2.setTime(date)
        }
    }


}

extension ViewController: KSClockViewDelegate {
    
    func ksClockView(clockView: KSClockView, didUpdate hour: Int, minute: Int) {
        NSLog("did update hour: %d minute: %d", hour, minute)
    }
    
    func ksClockView(clockView: KSClockView, updating hour: Int, minute: Int) {
        NSLog("updating hour: %d minute: %d", hour, minute)
    }
    
}
