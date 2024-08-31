//
//  ItemAPI.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation
import Moya
import Core

public struct RequestItemDTO {
    public let folderId: Int?
    public let photo: Data?
    public let itemName: String?
    public let itemPrice: String?
    public let itemURL: String?
    public let itemMemo: String?
    public let itemNotificationType: String?
    public let itemNotificationDate: String?
    
    public init(folderId: Int?, 
                photo: Data?,
                itemName: String?,
                itemPrice: String?,
                itemURL: String?,
                itemMemo: String?,
                itemNotificationType: String?, itemNotificationDate: String?) {
        self.folderId = folderId
        self.photo = photo
        self.itemName = itemName
        self.itemPrice = itemPrice
        self.itemURL = itemURL
        self.itemMemo = itemMemo
        self.itemNotificationType = itemNotificationType
        self.itemNotificationDate = itemNotificationDate
    }
}

public enum ItemAPI {
    /// 위시리스트 조회
    case getWishItems
    /// 위시아이템 삭제
    case deleteItem(id: Int)
    /// 아이템 디테일 조회
    case getItemDetail(id: Int)
    /// 아이템의 폴더 지정
    case modifyItemFolder(itemId: Int, folderId: Int)
    /// 아이템 파싱
    case parseItemUrl(link: String)
    /// 아이템 추가
    case addItem(item: RequestItemDTO)
}

extension ItemAPI: TargetType, AccessTokenAuthorizable {
    
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/item")!
    }
    
    public var path: String {
        switch self {
        case .getWishItems:
            return ""
        case .deleteItem(let id):
            return "/\(id)"
        case .getItemDetail(let id):
            return "/\(id)"
        case .modifyItemFolder(let itemId, let folderId):
            return "/\(itemId)/folder/\(folderId)"
        case .parseItemUrl:
            return "/parse"
        case .addItem:
            return ""
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getWishItems, .getItemDetail, .parseItemUrl:
            return .get
        case .modifyItemFolder:
            return .put
        case .deleteItem:
            return .delete
        case .addItem:
            return .post
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        
        switch self {
        case .getWishItems:
            parameters = [:]
        case .parseItemUrl(let link):
            parameters = ["site": link]
        case .addItem(let item):
            let data = makeMultipartFormData(param: item)
            return .uploadMultipart(data)
        default:
            parameters = [:]
        }
        
        let encoding: ParameterEncoding = self.method == .post ? JSONEncoding.default : URLEncoding.default
        return .requestParameters(parameters: parameters, encoding: encoding)
    }

    public var headers: [String : String]? {
        return NetworkMacro.AgentHeader
    }
    
    public var authorizationType: Moya.AuthorizationType? {
        return .bearer
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
    
    func makeMultipartFormData(param: RequestItemDTO) -> [Moya.MultipartFormData] {
       let itemNameData = MultipartFormData(provider: .data(param.itemName?.data(using: String.Encoding.utf8) ?? Data()), name: "item_name")
        let itemPriceData = MultipartFormData(provider: .data(param.itemPrice?.data(using: String.Encoding.utf8) ?? Data()), name: "item_price")
       let itemURLData = MultipartFormData(provider: .data(param.itemURL?.data(using: String.Encoding.utf8) ?? Data()), name: "item_url")
       let itemMemoData = MultipartFormData(provider: .data(param.itemMemo?.data(using: String.Encoding.utf8) ?? Data()), name: "item_memo")
       
       var folderIdData: MultipartFormData?
       var itemNotificationTypeData: MultipartFormData?
       var itemNotificationDateData: MultipartFormData?
       
       if let folderId = param.folderId {
           folderIdData = MultipartFormData(provider: .data(String(folderId).data(using: String.Encoding.utf8) ?? Data()), name: "folder_id")
       }
       if let notificationType = param.itemNotificationType {
           itemNotificationTypeData = MultipartFormData(provider: .data(notificationType.data(using: String.Encoding.utf8) ?? Data()), name: "item_notification_type")
       }
       if let notificationDate = param.itemNotificationDate {
           let itemNotificationDate = notificationDate + ":00"
           itemNotificationDateData = MultipartFormData(provider: .data(itemNotificationDate.data(using: String.Encoding.utf8) ?? Data()), name: "item_notification_date")
       }

       let imageData = param.photo ?? Data()
       let imageMultipartFormData = MultipartFormData(provider: .data(imageData), name: "item_img", fileName: "item.jpeg", mimeType: "image/jpeg")
       
       var formData: [Moya.MultipartFormData] = [imageMultipartFormData]
       formData.append(itemNameData)
       formData.append(itemPriceData)
       formData.append(itemURLData)
       formData.append(itemMemoData)
       if let folderIdData = folderIdData {
           formData.append(folderIdData)
       }
       if let itemNotificationTypeData = itemNotificationTypeData {
           formData.append(itemNotificationTypeData)
       }
       if let itemNotificationDateData = itemNotificationDateData {
           formData.append(itemNotificationDateData)
       }
       
       return formData
   }
}
