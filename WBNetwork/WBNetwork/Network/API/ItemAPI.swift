//
//  ItemAPI.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation
import Moya
import Core

public enum AddItemType: String {
    case parsing = "PARSING"        // 파싱 PARSING
    case manual = "MANUAL"          // 수동 MANUAL
}

public struct RequestItemDTO {
    public let folderId: Int?
    public let photos: [Data]?
    public let itemName: String
    public let itemPrice: String
    public let itemURL: String?
    public let itemMemo: String?
    public let itemNotificationType: String?
    public var itemNotificationDate: String?
    
    public init(folderId: Int?, 
                photos: [Data]?,
                itemName: String,
                itemPrice: String,
                itemURL: String?,
                itemMemo: String?,
                itemNotificationType: String?, itemNotificationDate: String?) {
        self.folderId = folderId
        self.photos = photos
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
    case addItem(type: AddItemType, item: RequestItemDTO)
    /// 아이템 수정
    case modifyItem(idx: Int, item: RequestItemDTO)
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
        case .modifyItem(let idx, _):
            return "/\(idx)"
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
        case .modifyItem:
            return .put
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        
        switch self {
        case .getWishItems:
            parameters = [:]
        case .parseItemUrl(let link):
            parameters = ["site": link]
        case .addItem(let type, let item):
            let data = makeMultipartFormData(param: item)
            return .uploadCompositeMultipart(data, urlParameters: ["type": type.rawValue])
        case .modifyItem(_, let item):
            let data = makeMultipartFormData(param: item)
            return .uploadMultipart(data)
        default:
            parameters = [:]
        }
        
        let encoding: ParameterEncoding = self.method == .post ? JSONEncoding.default : URLEncoding.default
        return .requestParameters(parameters: parameters, encoding: encoding)
    }

    public var headers: [String : String]? {
        return NetworkMacro.DefaultHeader
    }
    
    public var authorizationType: Moya.AuthorizationType? {
        return .bearer
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
    
    func makeMultipartFormData(param: RequestItemDTO) -> [Moya.MultipartFormData] {
        
        var formData: [Moya.MultipartFormData] = []
        
        // Required Datas - itemName, itemPrice
        
        let itemNameData = MultipartFormData(provider: .data(param.itemName.data(using: String.Encoding.utf8) ?? Data()), name: "itemName")
        let itemPriceData = MultipartFormData(provider: .data(param.itemPrice.data(using: String.Encoding.utf8) ?? Data()), name: "itemPrice")

        formData.append(itemNameData)
        formData.append(itemPriceData)
        
        // MANUAL - itemImages required
        // PARSING - itemImages optional
        
        if let photos = param.photos {
            // 이미지 데이터가 있다면 폼데이터에 추가
            for photo in photos {
                let imageMultipartFormData = MultipartFormData(provider: .data(photo), name: "itemImages", fileName: "item.jpeg", mimeType: "image/jpeg")
                formData.append(imageMultipartFormData)
            }
        }
        
        // Optional Datas

        if let folderId = param.folderId {
           let folderIdData = MultipartFormData(provider: .data(String(folderId).data(using: String.Encoding.utf8) ?? Data()), name: "folderId")
            formData.append(folderIdData)
        }
        if let itemURL = param.itemURL {
            let itemURLData = MultipartFormData(provider: .data(itemURL.data(using: String.Encoding.utf8) ?? Data()), name: "itemUrl")
            formData.append(itemURLData)
        }
        if let itemMemo = param.itemMemo {
            let itemMemoData = MultipartFormData(provider: .data(itemMemo.data(using: String.Encoding.utf8) ?? Data()), name: "itemMemo")
            formData.append(itemMemoData)
        }
        if let notificationType = param.itemNotificationType {
            let itemNotificationTypeData = MultipartFormData(provider: .data(notificationType.data(using: String.Encoding.utf8) ?? Data()), name: "itemNotificationType")
            formData.append(itemNotificationTypeData)
        }
        if let notificationDate = param.itemNotificationDate {
            let itemNotificationDate = notificationDate /*+ ":00"*/
            let itemNotificationDateData = MultipartFormData(provider: .data(itemNotificationDate.data(using: String.Encoding.utf8) ?? Data()), name: "itemNotificationDate")
            formData.append(itemNotificationDateData)
        }

        return formData
   }
}
