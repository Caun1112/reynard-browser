# 上游合并审查（2026-10-02）

## 1. 当前状态、分支与提交历史

- Fork： https://github.com/Caun1112/reynard-browser ，origin。
- 上游： https://github.com/minh-ton/reynard-browser ，upstream/main。
- 起始工作区干净；当前功能分支 codex/right-hand-ui 和 origin/codex/right-hand-ui 均为 `678b44df45b46998a29e1186142e02410fd1a1a6`。
- Fork main 为 ea2c577，缺少后续右手布局；本次目标为 codex/right-hand-ui。
- 共同祖先：`83d4acd1404a4f30e62af0351b62651fbc499026`（上次已合并的上游）。
- 固定上游：`86793782beed4f2667fac08325bdb9987b843bbb`。本次仅合并此快照，不在构建过程中追逐新的提交。
- Fork 独有 15 个提交，70 个差异文件；上游独有 18 个提交，142 个差异文件；交集 3 文件。
- git merge-tree 三方预演无文本冲突；预演 tree 为 4cc30ba286d2abc8b441907a8d308068950242a5。
- 两个子模块当前未在本机初始化；构建使用 Actions 按 gitlink 初始化对应版本。

## 2. 修改归属

上游更新应用至 0.15.0、Firefox FIREFOX_157_0_RELEASE、idevice v0.1.68；提供 Cryptex DDI JIT、摄像头内存修复、内容进程崩溃修复、立即启动加载、扩展弹窗及阅读/查找工具栏修复、键盘快捷键和越南语翻译。上游引擎、补丁、JIT、翻译及打包修改均完整接收。

Fork 保留 iPhone 右手布局、44 点触控范围、单行工具栏、右下标签排列、双向滑动关闭、资料库及设置可达导航、键盘避让、UI harness 和 Actions 构建缓存。

| 重叠文件 | 上游修改 | Fork 修改 | 合并建议 |
|---|---|---|---|
| browser/Reynard/Client/Interface/Addons/AddonCoordinator.swift | iOS 26 使用原生 pageSheet，旧系统保留 overFullScreen | 权限提示使用 ReachableNavigationController | 独立代码段，保留双方 |
| browser/Reynard/Client/Interface/Addons/AddonPopupViewController.swift | 新系统现代 sheet、外部点击关闭、旋转关闭、清理手势 | 44 点右下关闭按钮、键盘避让 | 自动合并存在行为冲突，手动融合 |
| browser/Reynard/Client/Interface/BrowserViewController.swift | createInitialTab() 新签名，立即加载页面 | iPhone 横竖屏底部右手布局 | 独立代码段，保留双方 |

## 3. 最安全的合并及回滚操作

已创建并推送备份分支，使用独立合并分支和双亲 merge，保留全部双方历史。验证通过后才快进功能分支；不强推，不重写已有提交。

```sh
git fetch origin --prune
git fetch upstream --prune --tags
git branch backup/right-hand-ui-before-upstream-20261002 678b44df45b46998a29e1186142e02410fd1a1a6
git push origin backup/right-hand-ui-before-upstream-20261002
git switch -c codex/merge-upstream-20261002 678b44df45b46998a29e1186142e02410fd1a1a6
git merge --no-ff --no-commit 86793782beed4f2667fac08325bdb9987b843bbb
# 检查并融合现代弹窗，提交、推送合并分支。
# 未提交时取消：
git merge --abort
# 审查完整差异：
git diff backup/right-hand-ui-before-upstream-20261002..codex/merge-upstream-20261002
# 验证通过后更新功能分支：
git switch codex/right-hand-ui
git merge --ff-only codex/merge-upstream-20261002
git push origin codex/right-hand-ui
# 已共享时回滚上游及本次融合，保留历史：
git revert -m 1 MERGE_SHA
git push origin codex/right-hand-ui
```

## 4. 逐文件冲突说明及合并片段

### AddonCoordinator.swift

无文本或语义冲突；权限提示与弹窗展示修改位于不同方法。保留 fork 的导航控制器，并完整接收上游系统版本分支。

```swift
let navigationController = ReachableNavigationController(rootViewController: promptViewController)
navigationController.modalPresentationStyle = .pageSheet
// 展示 addon popup 时：
if !isPopover {
    if #unavailable(iOS 26.0) {
        popupViewController.modalPresentationStyle = .overFullScreen
    }
    popupViewController.isModalInPresentation = true
}
```

### BrowserViewController.swift

无文本或语义冲突；启动方法与布局解析独立。保留上游新签名及 fork 横竖屏参数。

```swift
tabManager.createInitialTab()
// iPhone 布局解析中：
if RightHandLayout.isEnabled {
    return resolvePhoneLayout(orientation: orientation)
}
```

### AddonPopupViewController.swift

无文本冲突，但上游 configureModernSheetView() 只添加 GeckoView，绕过 fork 的关闭按钮及约束。自动合并会使 iOS 26 右手模式丢失右下关闭按钮。

融合保留上游 pageSheet、detent、8 点外边距、40 点圆角、外部点击、旋转关闭及会话幂等清理。在右手模式中加入 sheet 容器，复用 fork 44 点按钮和键盘避让约束；非右手路径使用上游实现。外部点击按整个内容容器判定，避免按钮区域被误识别为外部。

```swift
    @available(iOS 26.0, *)
    private func configureModernSheetView() {
        if RightHandLayout.isEnabled {
            let sheetView = makeSheetView()
            sheetView.layer.cornerCurve = .continuous
            sheetView.layer.cornerRadius = UX.modernSheetCornerRadius
            sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            let closeButton = makeCloseButton()
            view.addSubview(sheetView)
            sheetView.addSubview(closeButton)
            sheetView.addSubview(geckoView)
            modernSheetContentView = sheetView

            NSLayoutConstraint.activate([
                sheetView.topAnchor.constraint(equalTo: view.topAnchor),
                sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.modernSheetInset),
                sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.modernSheetInset),
                sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UX.modernSheetInset)
            ])
            constrainCloseButton(closeButton, in: sheetView)
            constrainGeckoView(in: sheetView, below: closeButton)
            return
        }

        geckoView.translatesAutoresizingMaskIntoConstraints = false
        geckoView.backgroundColor = .systemBackground
        geckoView.layer.cornerCurve = .continuous
        geckoView.layer.cornerRadius = UX.modernSheetCornerRadius
        geckoView.clipsToBounds = true
        view.addSubview(geckoView)

        NSLayoutConstraint.activate([
            geckoView.topAnchor.constraint(equalTo: view.topAnchor),
            geckoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.modernSheetInset),
            geckoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.modernSheetInset),
            geckoView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UX.modernSheetInset)
        ])
    }
```

同时新增 `private weak var modernSheetContentView: UIView?`；手势过滤的最终语句为：

```swift
let contentView = modernSheetContentView ?? geckoView
return !contentView.bounds.contains(touch.location(in: contentView))
```

## 5. 验证步骤、构建及回归

本机仅有 CommandLineTools，没有 Xcode/iOS SDK，不能运行 iOS 编译或模拟器。遵循仓库指示，通过 GitHub Actions 构建 TIPA 并执行现有 UI 测试。

1. 祖先与文件保留审计：确认合并的两个父提交；67 个 fork 非重叠文件逐字保持；139 个上游非重叠文件逐字接收；三个重叠文件逐一审查。
2. 未合并索引、冲突标记、手动修改 whitespace、Swift 语法和 shell 语法检查。
3. Actions RightHandUI：iPhone 15 Pro Max 现有六项测试，包含横竖屏工具栏、导航、键盘、深色模式、紧凑屏幕与设置 sheet；上传 xcresult 和截图。
4. Actions 实际编译：按固定 SHA 初始化 Firefox/idevice；应用全部 Gecko 补丁；编译 Gecko 和 idevice；arm64 Release archive；--no-signing 和 --trollstore 打包。
5. 下载并核验 artifact SHA-256、TIPA ZIP CRC、主程序与两个扩展的版本/构建号、arm64、ts_ptrace_jit 及 TrollStore entitlements。
6. 真机回归清单：安装/升级并检查书签与设置；冷启动和网页；JIT；摄像头权限及长时间采集内存；扩展弹窗滚动/输入/右下关闭/外部点击/旋转重开；横竖屏和键盘避让；返回/前进、标签关闭与恢复、资料库、阅读/查找/打印、音频和深色模式。

UI harness 使用部分替身且不覆盖真实扩展弹窗、Gecko、JIT及摄像头；编译/测试成功不能声称上述真机项目已通过。

```sh
gh workflow run build.yml --repo Caun1112/reynard-browser \
  --ref codex/merge-upstream-20261002 \
  -f checkout_ref=MERGE_SHA -f nightly=false \
  -f build_normal_ipa=false -f build_trollstore_tipa=true \
  -f build_jailbroken_ipa=false -f prepare_dependencies_only=false
```

Gecko SDK key 包含引擎版本、补丁、构建脚本和 Rust/Xcode 版本，本次更新将重新编译；idevice 缓存恢复后仍执行 Cargo 编译。上游 Swift concurrency bitcode 去除完整移至 unsigned archive 阶段，打包阶段不再重复执行。

构建成功并核验后，将 TIPA 上传 fork 的独立 Release，Release 标签固定到实际构建 SHA。当前 fork 没有 Release 或 RELEASE_TOKEN，不依赖上游的 tag 自动发布流程。

## 提交记录

### 上游新增

```text
8679378 Fix a crash caused by crash reporter initialization in the content process (even when crash reporting is already disabled)
d316b6e Update firefox to FIREFOX_157_0_RELEASE; sync patches
a3315eb Bump version to 0.15.0
d97f369 Add Vietnamese localization, update existing translations
13c62a7 Migrate to Cryptex DDI for JIT enablement
31a9a26 Update idevice submodule to v0.1.68
f343cd0 Fix an issue where using the camera would cause content process memory usage to grow significantly
dfa1f2a Revise installation instructions notes in README
a5128d1 Load webpage immediately on startup instead of waiting for blank session to done loading
0ea5b95 Dismiss addon popup sheet / popover on layout changes to avoid showing the incorrect one
f555798 Refresh addon popup sheet appearance for iOS 26+
c6a0899 Remove toolbar reveal delay when dismissing find in page, and restore full toolbar on this occasion
3e3a969 Remove toolbar reveal delay when using find on page from reader mode settings
8801c3b Use system material for reader mode settings popover on iOS 26+
0d3d84e Unhide toolbar as reader mode settings starts dismissing instead of after finishes
3a8d6ef Add keyboard shortcut for page print, reader mode, and settings
e0b7bc2 Move bitcode stripping of swift concurrency dylib to build ipa script when used with signing disabled & slightly reduce app binary size
9128c99 Fix tab bar having weird expanding animation on resize when it's not scrollable
```

### Fork 独有

```text
678b44d Document successful TrollStore build and artifact verification
d86e2c9 Record merge review and successful right-hand UI checks
7c2d5f7 Merge upstream 0.14.1 updates while preserving right-hand controls
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

## 实际验证结果

- 67/67 fork 非重叠文件与合并前 git blob 相同；139/139 上游非重叠文件与固定上游相同。
- 未合并索引为空，源文件无冲突标记，三个重叠 Swift 文件语法检查通过，两个 release shell 脚本 sh -n 通过。
- 手动融合相对于自动三方合并树的 git diff --check 通过；上游空行/patch context 本身的空白未全仓清理。
- 独立代理复审通过；实际 app/Gecko 编译与产物验证待 Actions 完成后补充。

## Actions UI 验证（2026-10-02）

- 双亲合并提交：`ae7523f5b34cac926ca1b696910dcac02858d5c9`，父提交为 678b44d 和 8679378。
- 构建与测试源码固定为 ae7523f；后续文档提交不改变已测试应用源码。
- Actions：https://github.com/Caun1112/reynard-browser/actions/runs/36980832918 。
- UI job 110754747097 成功，iPhone 15 Pro Max：6 项测试、0 失败，执行 164.696 秒，日志明确包含 TEST SUCCEEDED。
- xcresult 与 11 张截图已下载至 `dist/merged-20261002/verification/ui-results/`；日志为 `dist/merged-20261002/verification/ui-checks.log`。
- 已抽查 browser-landscape 和 editor-keyboard 截图，工具栏靠右、编辑操作栏位于键盘上方。
- Gecko 补丁应用成功；引擎编译仍在运行，尚无本次 TIPA。真实扩展弹窗及完整真机回归未执行。
