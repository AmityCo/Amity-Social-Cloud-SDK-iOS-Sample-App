//
//  AmityErrorCode.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/11/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import AmitySDK

extension AmityErrorCode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .business: return "BusinessError"
        case .badRequest: return "BadRequestError"
        case .unauthorized: return "UnauthorizedError"
        case .itemNotFound: return "ItemNotFound"
        case .forbiddenError: return "ForbiddenError"
        case .permissionDenied: return "PermissionDenied"
        case .userIsMuted: return "UserIsMuted"
        case .channelIsMuted: return "ChannelIsMuted"
        case .userIsBanned: return "UserIsBanned"
        case .numberOfMemberExceed: return "NumberOfMemberExceed"
        case .exemptFromBan: return "ExemptFromBan"
        case .maxRepetitionExceed: return "MaxRepetitionExceed"
        case .banWordFound: return "BanWordFound"
        case .linkNotAllowed: return "LinkNotAllowed"
        case .tooManyMember: return "TooManyMemberError"
        case .rateLimit: return "RateLimitError"
        case .globalBan: return "GlobalBanError"
        case .conflict: return "Conflict"
        case .unknown: return "Unknown"
        case .invalidParameter: return "InvalidParameter"
        case .malformedData: return "MalformedData"
        case .queryInProgress: return "ErrorQueryInProgress"
        case .connectionError: return "ConnectionError"
        case .uploadFailed: return "Upload Failed"
        @unknown default: return "unknown"
        }
    }
}
