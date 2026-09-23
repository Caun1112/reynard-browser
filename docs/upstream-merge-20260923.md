# 上游合并审查（2026-09-23）

## 当前状态与归属

工作区起初干净。目标为 codex/right-hand-ui（c7561ef），不是缺少右手布局的 main。
上游 main 固定为 83d4acd1404a4f30e62af0351b62651fbc499026，共同祖先 d9f2dc9。
上游独有 51 个提交、226 个文件；fork 独有 12 个提交、70 个差异文件。
上游新增阅读模式、打印、播放标签管理，更新 Firefox 156.0.1，修复工具栏和标签展示。
Fork 包含右手布局、44 点控件、单行工具栏、右下标签排列、双向滑动关闭、资料库与设置导航，以及构建缓存和 UI harness。

## 可审查、可回滚方案

已创建备份和独立合并分支，采用 merge 保留双方历史。验证通过后将原功能分支快进；不强推。

```sh
git branch backup/right-hand-ui-before-upstream-20260923 c7561ef
git switch -c codex/merge-upstream-20260923 c7561ef
git merge --no-ff --no-commit 83d4acd1404a4f30e62af0351b62651fbc499026
# 未提交时取消：git merge --abort
# 查看整个合并：
git diff backup/right-hand-ui-before-upstream-20260923..codex/merge-upstream-20260923
# 已共享时回滚，替换 MERGE_SHA 为本次双亲合并提交：
git revert -m 1 MERGE_SHA
```

## 重叠文件

- `.github/workflows/build.yml`
- `browser/Reynard/Client/Interface/Addons/AddonCoordinator.swift`
- `browser/Reynard/Client/Interface/BrowserViewController.swift`
- `browser/Reynard/Client/Interface/Chrome/ActionBar/ActionBar.swift`
- `browser/Reynard/Client/Interface/Chrome/ActionBar/FindInPage/FindInPageActionBar.swift`
- `browser/Reynard/Client/Interface/Chrome/ActionBar/PageZoom/PageZoomActionBar.swift`
- `browser/Reynard/Client/Interface/Chrome/AddressBar/AddressBar.swift`
- `browser/Reynard/Client/Interface/Chrome/AddressBar/AddressBarButton.swift`
- `browser/Reynard/Client/Interface/Homepage/Sections/Recommendations/PerformanceRecommendationViewController.swift`
- `browser/Reynard/Client/Interface/Library/Settings/Sections/General/Browsing/Sections/PageZoom/PageZoomPreferencesViewController.swift`
- `browser/Reynard/Client/Interface/Library/Settings/SettingsTableViewCell.swift`
- `browser/Reynard/Client/Interface/SiteSettings/SiteSettingsViewController.swift`
- `browser/Reynard/Client/Interface/TabOverview/TabOverviewCard.swift`
- `browser/Reynard/Client/Interface/TabOverview/TabOverviewCollection+UICollectionView.swift`
- `browser/Reynard/Client/Interface/TabOverview/TabOverviewCollection.swift`
- `browser/Reynard/Client/Interface/TabOverview/TabOverviewPresentation.swift`

## 冲突处理

1. FindInPageActionBar.swift：双方修改控件尺寸；保留新系统玻璃样式、48 点高度和 8 点间距，旧系统使用 fork 的 44 点高度、65 点右侧留白；新系统箭头宽度至少 44 点。
2. PageZoomActionBar.swift：双方修改尺寸；保留新系统 222 点宽度，旧系统 168 点宽度、48 点按钮和 44 点高度，并保留右侧定位。
3. AddressBarButton.swift：点击范围计算冲突；显式横向扩展优先，默认补足 44 点，避免扩大已足够大的 fork 按钮。
4. SettingsTableViewCell.swift：fork 空行与上游新增方法位置重叠；完整保留上游长按复制浏览器信息的方法。
5. TabOverviewCollection+UICollectionView.swift：两个独立委托方法插入同一位置；保留右下排列和开始拖动时结束展示动画两者。

自动合并审查另发现 AddressBar.swift 右手分支未给新增播放按钮激活横向约束，并可能与阅读按钮重叠。
新增 menuToSecondaryConstraint，排列为文本、阅读按钮、播放按钮、刷新按钮；处理主页只有播放按钮、隐藏按钮和编辑状态；播放按钮宽度至少 44 点。
其余重叠文件保留双方独立修改；引擎和补丁完全接受上游。

### 最终代码片段


`Chrome/ActionBar/FindInPage/FindInPageActionBar.swift`

```swift
    private enum UX {
        static let contentLeadingInset: CGFloat = 12
        static let contentMaximumWidth: CGFloat = 650
        static var searchBarToControlsSpacing: CGFloat {
            if #available(iOS 26.0, *) { return 8 }
            return 12
        }
        static var controlsHeight: CGFloat {
            if #available(iOS 26.0, *) { return 48 }
            return 44
        }
        static let searchContentInset: CGFloat = 12
        static let resultLabelWidth: CGFloat = 52
        static let resultLabelSpacing: CGFloat = 10
        static var controlsWidth: CGFloat { return controlButtonWidth * 2 + separatorWidth }
        static var controlButtonWidth: CGFloat {
            if #available(iOS 26.0, *) { return 44 }
            return 55
        }
        static let separatorWidth: CGFloat = 1
        static var controlsCornerRadius: CGFloat { return controlsHeight / 2 }
        static let controlSymbolPointSize: CGFloat = 14
        static var contentTrailingInset: CGFloat {
            if #available(iOS 26.0, *) { return 12 }
            return 65
        }
```

`Chrome/ActionBar/PageZoom/PageZoomActionBar.swift`

```swift
    private enum UX {
        static var controlsHeight: CGFloat {
            if #available(iOS 26.0, *) { return 48 }
            return 44
        }
        static var controlsWidth: CGFloat {
            if #available(iOS 26.0, *) { return 222 }
            return 168
        }
        static var controlButtonWidth: CGFloat {
            if #available(iOS 26.0, *) { return (controlsWidth - separatorWidth * 2) / 3 }
            return 48
        }
        static let separatorWidth: CGFloat = 1
        static var controlsCornerRadius: CGFloat { return controlsHeight / 2 }
        static let percentFontSize: CGFloat = 16
        static let controlSymbolPointSize: CGFloat = 14
        static let animationDuration: TimeInterval = 0.12
        static let bounceScale: CGFloat = 1.3
        static let bounceReturnDuration: TimeInterval = 0.75
        static let bounceDamping: CGFloat = 0.5
        static let backgroundAlpha: CGFloat = 0.34
        static let disabledAlpha: CGFloat = 0.32
        static let shadowOpacity: Float = 0.14
        static let shadowRadius: CGFloat = 8
        static let shadowOffset = CGSize(width: 0, height: 3)
```

`Chrome/AddressBar/AddressBarButton.swift`

```swift
        let bounds = self.bounds
        let widthIncrease = horizontalTouchTargetExpansion ?? max(0, (44 - bounds.width) / 2)
        let heightIncrease = max(0, (44 - bounds.height) / 2)
        let hitFrame = bounds.insetBy(dx: -widthIncrease, dy: -heightIncrease)
        
        return hitFrame.contains(point)
```

`Library/Settings/SettingsTableViewCell.swift`

```swift
    
    override var canBecomeFirstResponder: Bool {
        detailTextLabel?.isUserInteractionEnabled == true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        canBecomeFirstResponder && action == #selector(copy(_:)) && detailTextLabel?.text?.isEmpty == false
    }
    
    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = detailTextLabel?.text
    }
    
    func configureDetailTextCopying() {
        detailTextLabel?.isUserInteractionEnabled = true
        detailTextLabel?.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(handleDetailTextLongPress(_:)))
        )
    }
    
    @objc private func handleDetailTextLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began,
              let sourceView = gestureRecognizer.view,
              becomeFirstResponder() else {
            return
        }
        
        UIMenuController.shared.showMenu(from: sourceView, rect: sourceView.bounds)
    }
}
```

`TabOverview/TabOverviewCollection+UICollectionView.swift`

```swift
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard RightHandLayout.isEnabled,
              let layout = collectionViewLayout as? UICollectionViewFlowLayout,
              let presentation = tabOverview?.presentation else { return .zero }
        let cardSize = presentation.cardSize(in: collectionView)
        let count = collectionView.numberOfItems(inSection: section)
        let inset = collectionView.adjustedContentInset
        let availableWidth = collectionView.bounds.width - inset.left - inset.right
        let availableHeight = collectionView.bounds.height - inset.top - inset.bottom
        let contentHeight = CGFloat(count) * cardSize.height
            + CGFloat(max(0, count - 1)) * layout.minimumLineSpacing
        // Short lists sit above the toolbar; longer lists remain vertically scrollable.
        return UIEdgeInsets(top: max(0, availableHeight - contentHeight),
                            left: max(0, availableWidth - cardSize.width), bottom: 0, right: 0)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let collectionView = scrollView as? UICollectionView else { return }
        tabOverview?.presentation.finishPresentationForScrolling(in: collectionView)
    }
    

```

## 验证步骤与边界

1. 检查无未合并索引和冲突标记；Swift parser 验证六个冲突/手工融合文件。
2. GitHub Actions 按合并提交构建 Gecko、应用补丁、编译 idevice、Release arm64 归档，再使用 create-ipa.sh --trollstore 打包，不能把普通 IPA 改名充当 TIPA。
3. Actions 执行现有 iPhone 15 Pro Max UI harness，覆盖右手工具栏、导航、键盘、旋转等。harness 使用部分真实控件与替身，未覆盖完整 Gecko/地址栏/阅读模式。
4. 下载 TIPA，验证 ZIP CRC、版本和构建号、主程序及扩展、ts_ptrace_jit、TrollStore 权限并计算 SHA-256。
5. 真机安装后回归启动/JIT、网页、历史、阅读模式、打印、音频标签及静音、工具栏伸缩、横竖屏、右手点击区域、双向滑动关闭、设置复制、输入及键盘、iPad 布局。无真机执行证据时不能宣称通过。

普通 git diff --check 报出上游自带空行尾空格及 patch 上下文空格；保留这些上游内容，避免破坏补丁。冲突与语法检查单独执行。

## 提交清单

### 上游

```
83d4acd Fix selected tab snapshot staying on screen when scrolling the tab overview right after presentation animation
13aa0d6 Remove redundant smooth qualifiers from GLSL ES output to avoid shader compilation failures on iOS
a303633 Allow using the history swipe gesture to go back to the opener tab
526ec2f Revert global serif font override in 7acc71e, use New York font only for serif in Reader Mode
1fa785f Allow the playing tabs button to show independently on homepage & add fade in/out animation for visibility change
86e4845 Update firefox to FIREFOX_156_0_1_RELEASE; sync patches
7ba202c Fix address bar and tab overview card shadow aren't in sync with the object on layout changes
c1ee71c Clear recently opened tabs when browsing history is selected in clear browsing data setting
794932b Increase the number of saved recently closed tabs limit
54e5951 Activate the adjacent tab if using Cmd-W on a physical keyboard to remove tab (#431)
5a35439 Allow internal extension URL in new tab settings (#430)
e5e29e2 Standardize site settings store to use host strings instead of URL
45e6478 Add per-host and global setting to activate Reader Mode automatically
d3dd175 Enable dynamic toolbar when page is loading
32fffe6 Fix tab bar unable to scroll on sidebar open or layout changes
c19b59a Fix disrupted tab overview dismissal animation when selected tab is no longer visible, and automatically scroll to bottom on mode change
06c2453 Automatically fully reveal selected tab on tab bar after tab bar updates
1950c12 Fix disrupted action bar fly out animation on iOS 26+
f7c3146 Prevent default selected tab from activating automatically when closing a tab in tab overview
b066636 Allow returning to the opener tab using back button when opening links in a new tab (#405)
663e909 Add an address bar menu for showing playing tabs and allow muting individual tabs (#402)
6ed32ba Add bookmarks and find in page activities to the share sheet
8180bf6 Move build option from build script to build config file
96cdc8d Add website / PDF printing support
9d27b3d Bump version to 0.14.1
76011a9 Fix media playback not resuming after resumable interruptions (#429)
7acc71e Use SF for sans serif and New York for serif font in reader mode & add serif font lookup
ff02372 Allow links in updates release note to be opened inside the browser
20caa53 Allow copying browser info in settings (#421)
fbd172d Fix JIT enablement banner showing for jailbroken builds on iOS 17.4+ (#426)
025b079 Remove corner radius for the reader mode's non-glass modal sheet view
b8b3ff9 Fix app crash when opening reader mode settings pane on older iOS versions (#427)
1bb31ea Clean up patches for system font lookup
0019395 Bump version to 0.14.0
1a2b5c6 Update new translations from Crowdin
9593607 More fixes for fixed/sticky elements, menus, pickers, viewport sizing, anchor jumps, snapping and scroll restoration being offset by the toolbar
613ba8b Fix screen orientation changes not reaching Gecko specifically on iPad
29c0c84 Fix an issue where touch would be misplaced (offsetting by the notch amount) in full screen
d764b85 Fix desktop-viewport pages growing incorrectly offscreen after a view resize
c6215cd Fix RemoteIO self-join crash when audio playback drains
62c3cac Pin Xcode version as 26.6 for build workflow
1498894 Add shadow path for address bar & tab overview card, improve border during tab overview animation
22ac831 Fix webpages open with a wrong appearance on startup if we've chosen one manually in settings
7cc3843 Add preliminary support for Apple Pencil
2e383ee Update firefox to FIREFOX_156_0_RELEASE; sync patches
5d08f38 Improve toolbar inset handling for fixed and sticky hit targets / carets placement
fc15855 Fix toolbar inset hit testing for top- and bottom-fixed panels, sticky containers, and nested scrollers (#410)
6e863d7 Fix toolbar compensation pushing fixed/sticky menus offscreen (#415)
4fc7f2f Add support for reader mode (#321)
84eee59 Change the find in page address bar menu icon
40e3d88 Update action bar design so they look better on iOS 26+
```

### Fork

```
c7561ef Document successful merged IPA build and verification
f40493b Merge upstream 0.13.1 updates while preserving right-hand UI
544bcd9 Account for keyboard assistant and boot simulator before UI checks
d15b14e Anchor opaque right-hand settings bar to the screen edge
0f414d8 Wait for rotation to finish before checking toolbar reachability
a2c5bec Verify toolbar icons and synchronize library menu UI checks
d4fe122 Fit browser controls in a single right-aligned row
21fdfd7 Simplify library navigation and remove overlapping settings title
f032616 Make tab cards reachable and allow swiping closed in either direction
a8b8c08 Use full-size live action controls and right-side editing accessories
490018c Adapt iPhone controls and navigation for right-hand reachability
ea2c577 Allow fork builds and cache Gecko SDK for UI iteration
```
