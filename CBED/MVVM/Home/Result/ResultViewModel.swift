//
//  ResultViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 24/06/2021.
//

import RxSwift
import RxCocoa

enum ResultType {
    case pass(SaveResultResponseM)
    case fail(SaveResultResponseM)
    
    var image: UIImage {
        switch self {
        case .pass:
            return #imageLiteral(resourceName: "img_passed")
        case .fail:
            return #imageLiteral(resourceName: "img_fail")
        }
    }
    
    var title: String {
        switch self {
        case .pass:
            return "Congratulations!"
        case .fail:
            return "Opps!"
        }
    }
    
    var score: NSMutableAttributedString {
        switch self {
        case .pass(let result):
            let string1Attributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: Constants.Font.LatoBold, size: 64)!,
                                                                    .foregroundColor: Constants.PrimaryBlue]
            let string2Attributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: Constants.Font.LatoBold, size: 64)!,
                                                                    .foregroundColor: Constants.PrimaryTextColor]
            let string1 = NSMutableAttributedString.init(string: "\(result.correct ?? 0) ", attributes: string1Attributes)
            let string2 = NSMutableAttributedString.init(string: "/ \(result.total ?? 0)", attributes: string2Attributes)
            let combination = NSMutableAttributedString()
            combination.append(string1)
            combination.append(string2)
            
            return combination
        case .fail(let result):
            let string1Attributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: Constants.Font.LatoBold, size: 64)!,
                                                                    .foregroundColor: Constants.ColorE0293F]
            let string2Attributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: Constants.Font.LatoBold, size: 64)!,
                                                                    .foregroundColor: Constants.PrimaryTextColor]
            let string1 = NSMutableAttributedString.init(string: "\(result.correct ?? 0) ", attributes: string1Attributes)
            let string2 = NSMutableAttributedString.init(string: "/ \(result.total ?? 0)", attributes: string2Attributes)
            let combination = NSMutableAttributedString()
            combination.append(string1)
            combination.append(string2)
            
            return combination
        }
    }
}

// MARK: Input + Output
extension ResultViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
    }
    
    struct Output {
        let result: Observable<ResultType>
    }
}

struct ResultViewModel: ViewModel {
    let useCase: ResultUseCaseType
    let navigator: ResultNavigatorType
    let result: SaveResultResponseM
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let result = input
            .firstLoadTrigger
            .map { _ -> ResultType in
                let correctAnswers = self.result.correct ?? 0
                let total = self.result.total ?? 0
                
                let correctPercentage = correctAnswers / total * 100
                return correctPercentage > 90 ? .pass(self.result) : .fail(self.result)
                
            }
        
        return Output(result: result)
    }
}
