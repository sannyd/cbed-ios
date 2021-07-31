//
//  ScoreboardAPIUseCase.swift
//  ScoreboardAPIUseCase
//
//  Created by Jimmy Hoang on 28/07/2021.
//

import RxSwift

protocol ScoreboardAPIUseCase {
    func getScoreboard() -> Single<ScoreboardResponseM>
}

extension ScoreboardAPIUseCase {
    func getScoreboard() -> Single<ScoreboardResponseM> {
        return APIClient
            .shared
            .request(ScoreboardRouter.getScoreboard)
    }
}
