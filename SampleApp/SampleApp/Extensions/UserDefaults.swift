//
//  UserDefaults.swift
//  SampleApp
//
//  Created by Federico Zanetello on 10/29/18.
//  Copyright © 2018 David Zhang. All rights reserved.
//

extension UserDefaults {
    typealias ChannelId = String

    var filter: AmityChannelQueryFilter {
        get { return AmityChannelQueryFilter(rawValue: filterInt) ?? .all }
        set { filterInt = newValue.rawValue }
    }
    
    var channelTypeFilter: AmityChannelType {
        get { return AmityChannelType(rawValue: channelTypeFilterInt) ?? .standard }
        set { channelTypeFilterInt = newValue.rawValue }
    }
    
    private var channelTypeFilterInt: UInt {
        get { return UInt(integer(forKey: #function)) }
        set { set(newValue, forKey: #function) }
    }
    
    private var filterInt: Int {
        // If the value is absent or can't be converted to an integer, 0 will be returned.
        get { return integer(forKey: #function) }
        set { set(newValue, forKey: #function)}
    }

    var excludingTags: [String] {
        get { return stringArray(forKey: #function) ?? [] }
        set { set(newValue, forKey: #function) }
    }

    var includingTags: [String] {
        get { return stringArray(forKey: #function) ?? [] }
        set { set(newValue, forKey: #function) }
    }

    var userId: String? {
        get { return string(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var deviceToken: String? {
        get { return string(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var apiKeys: [String] {
        get { return array(forKey: #function) as? [String] ?? [] }
        set { set(newValue, forKey: #function) }
    }

    var currentApiKey: String? {
        get { return string(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var parentId: String? {
        get { return string(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var channelReversePreference: [ChannelId: Bool] {
        get { return dictionary(forKey: #function) as? [ChannelId: Bool] ?? [:] }
        set { set(newValue, forKey: #function) }
    }

    var channelPreferenceIncludingTags: [ChannelId: [String]] {
        get { return dictionary(forKey: #function) as? [ChannelId: [String]] ?? [:] }
        set { set(newValue, forKey: #function) }
    }

    var channelPreferenceExcludingTags: [ChannelId: [String]] {
        get { return dictionary(forKey: #function) as? [ChannelId: [String]] ?? [:] }
        set { set(newValue, forKey: #function) }
    }

    var channelPreferenceFilterByParentIdActive: [ChannelId: Bool] {
        get { return dictionary(forKey: #function) as? [ChannelId: Bool] ?? [:] }
        set { set(newValue, forKey: #function) }
    }

    var channelPreferenceFilterByParentId: [ChannelId: String] {
        get { return dictionary(forKey: #function) as? [ChannelId: String] ?? [:] }
        set { set(newValue, forKey: #function) }
    }
    
    var isStagingEnvironment: Bool {
        get { return value(forKey: #function) as? Bool ?? true }
        set { set(newValue, forKey: #function) }
    }
    
    var customHttpEndpoint: String? {
        get { return string(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }
    
    var customSocketEndpoint: String? {
        get { return string(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }
    
    var isRegisterdForPushNotification: Bool? {
        get { return bool(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }
}
