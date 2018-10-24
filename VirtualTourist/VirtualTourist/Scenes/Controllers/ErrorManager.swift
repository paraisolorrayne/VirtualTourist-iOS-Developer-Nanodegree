//
//  ErrorManager.swift
//  VirtualTourist
//
//  Created by Lorrayne Paraiso  on 21/10/18.
//  Copyright © 2018 Lorrayne Paraiso. All rights reserved.
//

import Foundation
import UIKit

protocol ErrorControllerProtocol {
    func dismissActivityControl()
    func presentError(alertController: UIAlertController)
    func fetchData()
}

struct ErrorManager {
    
    var delegate: ErrorControllerProtocol?
    
    func displayError(errorTitle: String, errorMsg: String?){
        let alert = UIAlertController(title: errorTitle, message: errorMsg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Constants.UIViews.ErrorView.dismissButton, style: UIAlertAction.Style.cancel, handler: {UIAlertAction in
            self.delegate?.dismissActivityControl()
        } ))
        alert.addAction(UIAlertAction(title: Constants.UIViews.ErrorView.reloadButton, style: UIAlertAction.Style.default, handler: {UIAlertAction in
            self.delegate?.fetchData()
        } ))
        
        DispatchQueue.main.async {
            self.delegate?.presentError(alertController: alert)
        }
    }
}
