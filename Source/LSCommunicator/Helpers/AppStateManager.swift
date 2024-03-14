//
//  AppStateManager.swift
//  
//
//  Created by Guru on 12/03/24.
//

import UIKit

class AppStateManager: NSObject {
    
    static let shared = AppStateManager()
    
    var didBecomeActiveHandler: (()->())?
    var didEnterBackgroundHandler: (()->())?
    
    private override init() {
        super.init()
        
        subscribeAppState()
    }
    
    func subscribeAppState() {
        // Did Become Active
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        // Did Enter Background
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }
    
    @objc func applicationDidBecomeActive() {
        self.didBecomeActiveHandler?()
    }
    
    @objc func applicationDidEnterBackground() {
        self.didEnterBackgroundHandler?()
    }
}
