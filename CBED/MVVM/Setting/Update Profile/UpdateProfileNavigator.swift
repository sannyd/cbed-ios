//
//  UpdateProfileNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 8/29/21.
//

import UIKit
import RxSwift

protocol UpdateProfileNavigatorType {
    func showUpdateProfileSuccessAlert()
    func showImagePicker(index: Int) -> Observable<[UIImagePickerController.InfoKey: Any]>
}

struct UpdateProfileNavigator: UpdateProfileNavigatorType {
    unowned let navigationController: UINavigationController
    
    func showUpdateProfileSuccessAlert() {
        UIAlertHelper.showAlertController(title: "Congratulation", message: "You have successfully update your account", cancel: "OK", others: nil) { _, index in
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
