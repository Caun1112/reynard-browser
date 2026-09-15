# 上游合并审查（2026-09-15）

## 状态与方案

- Fork: Caun1112/reynard-browser，目标 codex/right-hand-ui，原提交 544bcd9。
- 上游: minh-ton/reynard-browser main，d9f2dc9。
- 共同祖先: 0c6aca5；fork 独有 10 个提交，上游独有 45 个提交。
- 初始工作区干净。main 没有右手布局改动，因此以当前功能分支合并。
- 保留 backup/right-hand-ui-before-upstream-20260915；在 codex/merge-upstream-20260915 做非快进合并，保留双方历史。

## 变更归属

上游：0.13.1、动态工具栏最小化、光标/键盘与视口修复、导航历史、远程调试、翻译及可复用发布工作流。
Fork：右手可达布局、44 点操作目标、右下角导航和弹窗、标签双向滑动关闭、UI 回归测试、Gecko SDK 缓存及 fork 手动构建。

### 同路径重叠文件

- `.github/workflows/build.yml`
- `.gitignore`
- `browser/Reynard/Client/Interface/Addons/AddonPopupViewController.swift`
- `browser/Reynard/Client/Interface/BrowserViewController.swift`
- `browser/Reynard/Client/Interface/Chrome/ActionBar/ActionBar.swift`
- `browser/Reynard/Client/Interface/Chrome/ActionBar/FindInPage/FindInPageActionBar.swift`
- `browser/Reynard/Client/Interface/Chrome/ActionBar/PageZoom/PageZoomActionBar.swift`
- `browser/Reynard/Client/Interface/Chrome/AddressBar/AddressBar.swift`
- `browser/Reynard/Client/Interface/ContentView/WebContent/SelectPicker/MultiSelectViewController.swift`
- `browser/Reynard/Client/Interface/ContentView/WebContent/SelectPicker/SelectPicker.swift`
- `browser/Reynard/Client/Interface/TabOverview/TabOverviewCard.swift`

此外，上游将 Compatibility 设置移动到 Advanced 下；Git 已将 fork 的 UserAgentOverrides 右侧删除按钮改动带入新路径。

## 冲突处理及最终代码

### .github/workflows/build.yml

上游改用 workflow_call、checkout_ref 与 nightly 参数；fork 需要手动运行、UI 检查及依赖缓存。保留双方功能，增加 workflow_dispatch；两个构建任务检出同一 ref。按 inputs 选择产物，避免可复用调用忽略选择。

```yaml
# prepare job
if: ${{ github.event_name == 'workflow_dispatch' || github.repository_owner == 'minh-ton' }}
# Both checkout steps
ref: ${{ inputs.checkout_ref || github.sha }}
# App build
if: ${{ !inputs.prepare_dependencies_only }}
run: ./tools/release/build-app.sh --no-signing ${{ inputs.nightly && '--nightly' || '' }}
# Normal IPA creation/upload
if: ${{ !inputs.prepare_dependencies_only && matrix.variant == 'standard' && inputs.build_normal_ipa }}
```

### PageZoomActionBar.swift

双方修改同一尺寸常量。保留 fork 的触摸尺寸及右侧定位，采用上游背景/阴影实现，移除上游已删除且不再使用的 backgroundHeight。

```swift
static let controlsHeight: CGFloat = 44
static let controlsWidth: CGFloat = 168
static let controlButtonWidth: CGFloat = 48
```

```swift
if RightHandLayout.isEnabled {
    controlsShadowView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -65).isActive = true
} else {
    controlsShadowView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
}
```

### 自动合并审查

- AddressBar：保留右侧菜单/刷新与 44 点目标，采用上游最小化标题更新。
- BrowserViewController：保留 iPhone 横屏底部布局，采用上游键盘及视口逻辑。
- ActionBar、FindInPage：保留 44 点操作目标，采用上游深色外观与新键盘操作栏。
- AddonPopup：保留底部关闭按钮，采用上游较窄弹窗。
- SelectPicker/MultiSelect：保留 ReachableNavigationController 与可达按钮，采用上游响应性修复。
- TabOverviewCard：保留 44 点关闭按钮及元数据区，采用上游卡片边框。
- .gitignore：合并双方忽略项。

## 验证步骤

1. 检查未解决索引项、冲突标记、工作流语法、shell 脚本语法。上游原有空白行带尾随空格，保持原样以免污染补丁。
2. GitHub Actions：应用最新 Gecko 补丁、编译 Gecko 和 idevice、执行 Release arm64 archive，关闭证书签名，打包 Reynard.ipa。
3. 同一提交运行 iPhone 15 Pro Max UI harness 的 6 项测试：按钮位置及动作、导航与键盘、深色、资料库标题、单行工具栏、设置底栏滚动。
4. 下载产物，验证 ZIP 完整性、版本/提交号、主程序/扩展、签名状态，并记录 SHA-256。
5. 真机安装后人工回归：启动/JIT、网页前进后退与重启恢复、标签双向关闭、横竖屏、最小化/展开工具栏、缩放、网页输入与收键盘、设置保存、书签编辑、插件弹窗、选择器、深浅色及 iPad 分屏。

UI harness 使用真实部分 UIKit 控件，但替代 Gecko 与地址栏依赖；不能替代真机网页/JIT 回归。没有连接真机时，不将这部分标记为通过。
普通 IPA 无开发者/分发证书签名；上游打包脚本会对 libswift_Concurrency.dylib 使用 ad-hoc 签名以支持旧系统，这不等同于可直接安装的证书签名。

## 审查与回滚

```sh
git diff backup/right-hand-ui-before-upstream-20260915..codex/merge-upstream-20260915
git log --graph --oneline --all
# 合并未提交时可执行：git merge --abort
# 合并进入共享分支后，以实际 merge commit 替换 MERGE_SHA：
git revert -m 1 MERGE_SHA
```

## 上游新增提交

d9f2dc9 Use the app's navigation history store instead of session state restoration history since synchronization with the latter is buggy
2dbc75e Bump version to 0.13.1
980f8bc Fix caret placement would have the toolbar inset applied twice on phone layout
9bb2af9 Improve toolbar inset handling for zoom, floating elements, caret placement, and minimized-toolbar viewport sizing
1a90f21 Improve focused text input relocation reliability
182a287 Bump version to 0.13.0
1a983dd Update new translations from Crowdin
5626582 Prevent minimized toolbar from being reset during same tab navigation or history swipe gestures
a2374a1 Select the previously selected tab when closing the currently selected tab, instead of using the adjacent tab
7ed5595 Cap toolbar minimize text centering duration no more than 0.2s since shorter text could make toolbar collapse to take longer
a8b4c07 Update the minimized toolbar text dynamically
ff81146 Allow the toolbar to be minimized manually (#347)
14d6e1b Add bottom scroll space so web content bottom is above the minified toolbar, fix stale sticky/margin top gap on orientation change
9f4b07d Toolbar is now minimized on collapse instead of hiding completely (#403)
fc05d5f Reset toolbar state on scroll to hide pref change so we don't end up with a stale appearance
0c003e6 Increase the dynamic toolbar expand/hide animation speed
e2d7fd4 Improve top dynamic toolbar behavior so content flows underneath toolbar while sticky menus are always positioned at the bottom
04bf6da Improve responsiveness for some form control elements (#401), and improve positioning for webpage text selection menu
4aab6c5 Remove white shadows, make action bar elements easier to see in dark mode, and add border to tab overview card
d5070fe Disable mobile viewport on iPad by default & disable dynamic toolbar on .compact layout during slide over / split view
3215fa1 Revert 9585c7a since it's bad UX; the webview is now shifted with caret still visible on the part not obscured by the keyboard
ad55a36 Change status bar text color adaptively based on underlying content on iOS 18 and older
fc7bf34 Fix tab bar selection highlight would sometimes follow the wrong tab after reordering
701d1f2 Update installation instruction notice, and add translation & support links
6a7de8d Add new workflow for build & create release on tag push
f7a2bcb Fix address bar shadow would lag behind the bar's animated size on layout changes
117d387 Reduce the width of addon popup so some addon pages can render properly
667efe1 Fix webpage content would briefly jump upward when switched from a homepage tab with dynamic toolbar disabled
19cb03c Fix colored page background would be visible on full screen manual orientation change
473989a Fix address bar's present tab overview gesture would trigger during full screen mode
d7b4a9b Fix homepage content being shifted down briefly after first presentation
204aa00 Fix views in the sidebar primary column being extended offscreen
c3da6f0 Add new files to .gitignore
3e973ad Fix top address bar having no horizontal padding on iOS 18 and older
633eef5 Only show the keyboard dismissal bar on iPhone
4323b65 Add keyboard dismiss button for webpage text editing (#330)
4ad84e8 Add new open link in new tab disposition setting & clean up context menus (#393)
a1ef3c9 Open links in settings inside the browser instead of external ones
ebc78fd Remove user data migration on startup added in 0.4.0
8d0000b Add remote debugging support (#394)
e348c3f Fix a crash when non-webpage text input field, e.g. settings, is focused after 9585c7a
95c743b Move Compatibility setting to a new Advanced section
9585c7a Use the caret position to dock text input above keyboard instead of the whole editable element, which fixes (#384)
b9bde76 Restore the webview upward relocation cap at the keyboard overlap to prevent the view from flying out of screen on text editing (#399)
220c838 Update README with new screenshots, installation instructions, and acknowledgements

## Fork 独有提交

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
