//
//  WebsiteModePolicy.swift
//  Reynard
//
//  Created by Minh Ton on 18/6/26.
//

import Foundation

// MARK: - Website Mode Action

enum WebsiteModeAction {
    case reload
    case load(String)
}

final class WebsiteModePolicy {
    // MARK: - Mode Resolution

    func prefersDesktopMode(for _: String, tabID _: UUID?) -> Bool {
        return Prefs.BrowsingSettings.requestDesktopWebsite
    }

    func isDesktopMode(for url: String, tabID _: UUID) -> Bool? {
        guard let host = DomainMatcher.host(from: url),
              !url.starts(with: "moz-extension://"),
              host != "addons.mozilla.org" else {
            return nil
        }

        return Prefs.BrowsingSettings.requestDesktopWebsite
    }

    // MARK: - Overrides

    func toggle(for url: String, tabID: UUID) -> WebsiteModeAction? {
        guard DomainMatcher.host(from: url) != nil,
              let isDesktop = isDesktopMode(for: url, tabID: tabID) else {
            return nil
        }

        let enablesDesktopMode = !isDesktop
        let desktopURL = enablesDesktopMode ? desktopURL(from: url) : nil
        Prefs.BrowsingSettings.requestDesktopWebsite = enablesDesktopMode

        return desktopURL.map(WebsiteModeAction.load) ?? .reload
    }

    // MARK: - URL Resolution

    private func desktopURL(from url: String) -> String? {
        guard var components = URLComponents(string: url),
              let host = components.host else {
            return nil
        }

        let normalizedHost = host.lowercased()
        let prefixes = ["m.", "mobile."]
        guard let prefix = prefixes.first(where: { normalizedHost.hasPrefix($0) }) else {
            return nil
        }

        components.host = String(normalizedHost.dropFirst(prefix.count))
        return components.url?.absoluteString
    }

}
