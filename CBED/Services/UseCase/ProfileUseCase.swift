//
//  UserUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/07/2021.
//

import RxSwift
import Alamofire

protocol ProfileUseCase {
    func getProfileInfo() -> Single<ProfileInfoM>
    func updateProfileInfo(request: UpdateProfileRequestM,
                           imageData: Data?) -> Single<ProfileInfoM>
}

extension ProfileUseCase {
    func getProfileInfo() -> Single<ProfileInfoM> {
        return APIClient
            .shared
            .request(ProfileRouter.getProfileInfo)
    }
    
    func updateProfileInfo(request: UpdateProfileRequestM,
                           imageData: Data?) -> Single<ProfileInfoM> {
        guard let params = request.toParams() else {
            return .error(CustomError.CannotGetParams)
        }
        
        let multipartFormData = MultipartFormData()
        
        if let imageData = imageData {
            multipartFormData.append(imageData, withName: "avatar", fileName: "avatar.jpg", mimeType: "image/jpg")
        }
        
        for (key, value) in params {
            multipartFormData.append((value as! String).data(using: .utf8)!, withName: key)
        }
        
        return APIClient
            .shared
            .upload(multipartFormData: multipartFormData,
                    urlConvertible: ProfileRouter.updateProfileInfo)
    }
}
