//
//  GeneralSettingsSection.swift
//  Reynard
//
//  Created by Minh Ton on 18/6/26.
//

import UIKit

struct GeneralSettingsSection {
    enum Row: CaseIterable {
        case addons
        case browsing
        case language
        case search
        case newTab
        case homepage
        case appearance
        case compatibility
    }

    var rowCount: Int {
        return Row.allCases.count
    }

    func cell(at index: Int) -> UITableViewCell {
        guard Row.allCases.indices.contains(index) else {
            return UITableViewCell()
        }

        switch Row.allCases[index] {
        case .addons:
            return SettingsViewUtils.disclosureCell(title: AppText.text("Add-ons"))
        case .browsing:
            return SettingsViewUtils.disclosureCell(title: AppText.text("Browsing"))
        case .language:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = AppText.text("Language")
            cell.detailTextLabel?.text = Prefs.BrowsingSettings.language.title
            cell.accessoryType = .disclosureIndicator
            return cell
        case .search:
            return SettingsViewUtils.disclosureCell(title: AppText.text("Search"))
        case .newTab:
            return SettingsViewUtils.disclosureCell(title: AppText.text("New Tab"))
        case .homepage:
            return SettingsViewUtils.disclosureCell(title: AppText.text("Homepage"))
        case .appearance:
            return SettingsViewUtils.disclosureCell(title: AppText.text("Appearance"))
        case .compatibility:
            return SettingsViewUtils.disclosureCell(title: AppText.text("Compatibility"))
        }
    }

    func selectRow(at index: Int, from viewController: UIViewController) {
        guard Row.allCases.indices.contains(index) else {
            return
        }

        let destination: UIViewController
        switch Row.allCases[index] {
        case .addons:
            destination = AddonsPreferencesViewController()
        case .browsing:
            destination = BrowsingPreferencesViewController()
        case .language:
            destination = LanguagePreferencesViewController()
        case .search:
            destination = SearchPreferencesViewController()
        case .newTab:
            destination = NewTabPreferencesViewController()
        case .homepage:
            destination = HomepagePreferencesViewController()
        case .appearance:
            destination = AppearancePreferencesViewController()
        case .compatibility:
            destination = CompatibilityPreferencesViewController()
        }
        viewController.navigationController?.pushViewController(destination, animated: true)
    }
}

final class LanguagePreferencesViewController: SettingsTableViewController {
    private enum Section: CaseIterable {
        case language

        var text: SettingsSectionText {
            return SettingsSectionText(
                headerTitle: AppText.text("Language"),
                footerTitle: AppText.text("Websites that support multiple languages will prefer the selected language. Open pages may need to be reloaded.")
            )
        }
    }

    init() {
        super.init(style: .insetGrouped)
        title = AppText.text("Language")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = AppText.text("Language")
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard Section.allCases.indices.contains(section) else {
            return 0
        }
        return BrowserLanguage.allCases.count
    }

    override func sectionText(for section: Int) -> SettingsSectionText {
        guard Section.allCases.indices.contains(section) else {
            return SettingsSectionText()
        }
        return Section.allCases[section].text
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard Section.allCases.indices.contains(indexPath.section),
              BrowserLanguage.allCases.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }

        let language = BrowserLanguage.allCases[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = language.title
        cell.accessoryType = Prefs.BrowsingSettings.language == language ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard Section.allCases.indices.contains(indexPath.section),
              BrowserLanguage.allCases.indices.contains(indexPath.row) else {
            return
        }

        Prefs.BrowsingSettings.language = BrowserLanguage.allCases[indexPath.row]
        title = AppText.text("Language")
        tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
    }
}
