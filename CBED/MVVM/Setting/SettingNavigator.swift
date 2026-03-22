import UIKit

protocol SettingNavigatorType {
    func presentRestorePurchaseSuccessAlert()
    func presentUpdateProfileVC()
    func presentUpdateCountSuccessAlert()
}

struct SettingNavigator: SettingNavigatorType {
    unowned let navigationController: UINavigationController
    
    func presentRestorePurchaseSuccessAlert() {
        let alert = UIAlertHelper.showAlertController(title: "Success",
                                          message: "Previous purchase restored.",
                                          cancel: "OK",
                                          others: nil,
                                          handleAction: nil)
        
        navigationController.presentingViewController?.present(alert, animated: true)
    }
    
    func presentUpdateProfileVC() {
        let updateProfileVC: UpdateProfileViewController = StoryboardManager.getVCFromSettingSB()
        updateProfileVC.viewModel = .init(useCase: UpdateProfileUseCase(), navigator: UpdateProfileNavigator(navigationController: navigationController))
        navigationController.pushViewController(updateProfileVC, animated: true)
    }
    
    func presentUpdateCountSuccessAlert() {
        let vc = UIAlertController(title: "Update success!", message: "", preferredStyle: .alert)
        vc.addAction(.init(title: "OK", style: .cancel))
        
        navigationController.present(vc, animated: true)
    }
}
