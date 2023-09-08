//
//  RegisterNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 10/07/2021.
//

import UIKit
import RxSwift

protocol RegisterNavigatorType {
    func showRegisterSuccessAlert()
    func showImagePicker(index: Int) -> Observable<[UIImagePickerController.InfoKey: Any]>
}

struct RegisterNavigator: RegisterNavigatorType {
    unowned let navigationController: UINavigationController
    
    func showRegisterSuccessAlert() {
        UIAlertHelper.showAlertController(title: "Congratulations", message: "Successful account creation", cancel: "OK", others: nil) { _, index in
            navigationController.popViewController(animated: true)
        }
    }
    
    func showImagePicker(index: Int) -> Observable<[UIImagePickerController.InfoKey: Any]> {
        if index == 0 {
            return UIImagePickerController.rx.createAndPresent(from: navigationController, animated: true) { (picker) in
                picker.sourceType = .camera
                picker.allowsEditing = true
            }
        } else {
            return UIImagePickerController.rx.createAndPresent(from: navigationController, animated: true) { (picker) in
                picker.sourceType = .photoLibrary
                picker.allowsEditing = true
            }
        }
    }
}
