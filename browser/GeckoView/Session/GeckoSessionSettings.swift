//
//  GeckoSessionSettings.swift
//  Reynard
//
//  Created by Minh Ton on 28/6/26.
//

import UIKit

public struct WebsiteModeSetting: Equatable {
    public static let mobile = WebsiteModeSetting(
        userAgentOverride: nil,
        userAgentMode: 0,
        viewportMode: 0
    )

    public let userAgentOverride: String?
    public let userAgentMode: Int
    public let viewportMode: Int

    public init(userAgentOverride: String?, userAgentMode: Int, viewportMode: Int) {
        self.userAgentOverride = userAgentOverride
        self.userAgentMode = userAgentMode
        self.viewportMode = viewportMode
    }
}

public struct PageZoomSetting: Equatable {
    public static let `default` = PageZoomSetting(level: 100)

    public let level: Int

    public var scale: CGFloat {
        return CGFloat(level) / 100
    }

    public init(level: Int) {
        self.level = level
    }
}

public struct LanguageSetting: Equatable {
    public static let simplifiedChinese = LanguageSetting(
        requestedLocales: ["zh-CN", "en-US"],
        acceptLanguages: "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7"
    )

    public let requestedLocales: [String]
    public let acceptLanguages: String

    public init(requestedLocales: [String], acceptLanguages: String) {
        self.requestedLocales = requestedLocales
        self.acceptLanguages = acceptLanguages
    }
}

public struct GeckoSessionSettings: Equatable {
    public static let `default` = GeckoSessionSettings(
        websiteMode: .mobile,
        pageZoom: .default,
        language: .simplifiedChinese
    )

    public let websiteMode: WebsiteModeSetting
    public let pageZoom: PageZoomSetting
    public let language: LanguageSetting

    public init(
        websiteMode: WebsiteModeSetting,
        pageZoom: PageZoomSetting,
        language: LanguageSetting
    ) {
        self.websiteMode = websiteMode
        self.pageZoom = pageZoom
        self.language = language
    }
}
