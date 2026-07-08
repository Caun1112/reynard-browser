//
//  HomepageOpeningScreen.swift
//  Reynard
//
//  Created by Minh Ton on 27/6/26.
//

enum HomepageOpeningScreen: String, CaseIterable {
    case homepage
    case lastTab

    var title: String {
        switch self {
        case .homepage:
            return AppText.text("Homepage")
        case .lastTab:
            return AppText.text("Last Tab")
        }
    }
}
