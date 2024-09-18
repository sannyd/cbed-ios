import UIKit

protocol NestedLevelNavigatorType {
    func pushToSectionsVC(level: LevelM)
}

struct NestedLevelNavigator: NestedLevelNavigatorType {
    unowned let navigationController: UINavigationController
    
    func pushToSectionsVC(level: LevelM) {
        let sectionsVC = StoryboardManager.instanceSectionsVC()
        sectionsVC.viewModel = .init(useCase: SectionsUseCase(),
                                     navigator: SectionsNavigator(navigationController: navigationController),
                                     level: level)
        navigationController.pushViewController(sectionsVC, animated: true)
    }
}


