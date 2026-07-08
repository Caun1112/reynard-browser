//
//  AppText.swift
//  Reynard
//
//  Created by Codex on 8/7/26.
//

import Foundation

enum AppText {
    static func text(_ english: String) -> String {
        guard Prefs.BrowsingSettings.language == .chinese else {
            return english
        }
        return simplifiedChinese[english] ?? english
    }

    static func onOff(_ value: Bool) -> String {
        return text(value ? "On" : "Off")
    }

    private static let simplifiedChinese: [String: String] = [
        "About": "关于",
        "Add-ons": "扩展",
        "Address Bar": "地址栏",
        "All Website": "所有网站",
        "Appearance": "外观",
        "Autoplay": "自动播放",
        "Blank Page": "空白页",
        "Bottom": "底部",
        "Browsing": "浏览",
        "Cancel": "取消",
        "Choose what to see when you open Reynard.": "选择打开 Reynard 时显示的内容。",
        "Choose what to show on the homepage.": "选择主页上显示的内容。",
        "Clear Browsing Data": "清除浏览数据",
        "Compatibility": "兼容性",
        "Custom URL": "自定义 URL",
        "Day": "日间",
        "Default": "默认",
        "Engine Version": "引擎版本",
        "Favorites": "收藏",
        "Frequently Visited": "经常访问",
        "General": "通用",
        "Homepage": "主页",
        "If you encounter issues such as sign-in failures, human verification challenges, or other incorrect site behavior, adding the site's URL to this user agent override list may help resolve the problem.": "如果遇到登录失败、人机验证异常或其它网站行为不正确的问题，把该网站 URL 加入用户代理覆盖列表可能有助于解决。",
        "JIT": "JIT",
        "Landscape Tab Bar": "横屏标签栏",
        "Language": "语言",
        "Last Tab": "上次标签页",
        "Links": "链接",
        "Media": "媒体",
        "New Tab": "新标签页",
        "Night": "夜间",
        "Off": "关闭",
        "On": "开启",
        "Opening Screen": "启动页面",
        "Page Zoom": "页面缩放",
        "Privacy": "隐私",
        "Reynard Browser": "Reynard 浏览器",
        "Recently Closed Tabs": "最近关闭的标签页",
        "Request Desktop Website On": "请求桌面网站",
        "Search": "搜索",
        "Search Bookmarks": "搜索书签",
        "Search Browsing History": "搜索浏览历史",
        "Search Engine": "搜索引擎",
        "Search Opened Tabs": "搜索已打开标签页",
        "Search Suggestion Provider": "搜索建议提供方",
        "Search Suggestions": "搜索建议",
        "Settings": "设置",
        "Show Full Website Address": "显示完整网站地址",
        "Show Image Previews": "显示图片预览",
        "Show in Private Browsing": "在无痕浏览中显示",
        "Show Link Previews": "显示链接预览",
        "Show on Homepage": "在主页显示",
        "Show on New Tab": "在新标签页显示",
        "Show Search Suggestions": "显示搜索建议",
        "Site Permissions": "网站权限",
        "Specific Site Settings": "特定网站设置",
        "Support The Project": "支持项目",
        "System": "跟随系统",
        "Tabs": "标签页",
        "The browser will use a desktop Firefox user agent for navigating the web.": "浏览器会使用桌面版 Firefox 用户代理访问网页。",
        "To maximize compatibility, the browser will use the Firefox for Android user agent for navigating the web. As a result, websites may identify your device as an Android device.": "为了提高兼容性，浏览器会使用 Android 版 Firefox 用户代理访问网页。因此，网站可能会把你的设备识别为 Android 设备。",
        "Top": "顶部",
        "Update Available": "有可用更新",
        "Use Android User Agent": "使用 Android 用户代理",
        "User Agent Overrides": "用户代理覆盖",
        "View Source Code": "查看源代码",
        "Websites that support multiple languages will prefer the selected language. Open pages may need to be reloaded.": "支持多语言的网站会优先使用所选语言。已打开的页面可能需要重新加载。",
        "When long-pressing images": "长按图片时",
        "When long-pressing links": "长按链接时",
        "Zoom Settings": "缩放设置",
    ]
}
