import XCTest

final class ArchiveToyboxUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testManualAcceptanceFlows() throws {
        let app = XCUIApplication()
        app.launch()

        if app.buttons["privacyAcceptButton"].waitForExistence(timeout: 3) {
            app.buttons["privacyAcceptButton"].tap()
        }

        XCTAssertTrue(app.staticTexts["玩具盒"].waitForExistence(timeout: 5))

        try exerciseWoodenFish(app)
        try exerciseLuckyCat(app)
        try exerciseArgumentPractice(app)
        try exerciseArgumentAnalysis(app)
        try exerciseMeditation(app)
        try exerciseFriends(app)
        try exerciseProfile(app)
    }

    private func exerciseWoodenFish(_ app: XCUIApplication) throws {
        app.staticTexts["电子木鱼"].tap()
        XCTAssertTrue(app.buttons["woodenFishButton"].waitForExistence(timeout: 3))
        app.buttons["woodenFishButton"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '今日功德'")).firstMatch.waitForExistence(timeout: 3))
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    private func exerciseLuckyCat(_ app: XCUIApplication) throws {
        app.staticTexts["招财猫"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '不承诺改变现实'")).firstMatch.waitForExistence(timeout: 3))
        app.buttons["luckyCatButton"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '今日招财值'")).firstMatch.waitForExistence(timeout: 3))
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    private func exerciseArgumentPractice(_ app: XCUIApplication) throws {
        app.staticTexts["好好吵架"].tap()
        app.staticTexts["模拟练习"].tap()
        app.buttons["开始模拟"].tap()
        XCTAssertTrue(app.navigationBars["模拟中"].waitForExistence(timeout: 10))
        let field = app.textFields["输入你的回应"]
        field.tap()
        field.typeText("我想把分工说清楚")
        app.buttons["发送"].tap()
        app.buttons["结束并生成复盘"].tap()
        XCTAssertTrue(app.staticTexts["本局吵架复盘"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["情绪稳定力"].waitForExistence(timeout: 3))
        app.buttons["生成分享海报"].tap()
        XCTAssertTrue(app.navigationBars["分享海报"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    private func exerciseArgumentAnalysis(_ app: XCUIApplication) throws {
        app.staticTexts["好好吵架"].tap()
        app.staticTexts["吵架分析"].tap()
        let chatField = app.textFields["请粘贴聊天记录"]
        chatField.tap()
        chatField.typeText("A: 你怎么又这样\nB: 你才是")
        app.buttons["开始分析"].tap()
        if app.buttons["我已处理隐私信息，开始分析"].waitForExistence(timeout: 2) {
            app.buttons["我已处理隐私信息，开始分析"].tap()
        }
        XCTAssertTrue(app.navigationBars["分析报告"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["一句话总结"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    private func exerciseMeditation(_ app: XCUIApplication) throws {
        app.staticTexts["静心弹幕"].tap()
        XCTAssertTrue(app.staticTexts["曲目"].waitForExistence(timeout: 5))
        app.staticTexts["大悲咒静心版"].tap()
        XCTAssertTrue(app.navigationBars["播放中"].waitForExistence(timeout: 5))
        app.buttons["再来一条"].tap()
        app.buttons["结束"].tap()
        XCTAssertTrue(app.staticTexts["静心弹幕"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    private func exerciseFriends(_ app: XCUIApplication) throws {
        app.tabBars.buttons["好友"].tap()
        XCTAssertTrue(app.navigationBars["好友"].waitForExistence(timeout: 3))
        let searchField = app.textFields["输入短 ID"]
        searchField.tap()
        searchField.typeText("TOYBOX002")
        app.buttons["搜索"].tap()
        XCTAssertTrue(app.staticTexts["测试好友"].waitForExistence(timeout: 5))
    }

    private func exerciseProfile(_ app: XCUIApplication) throws {
        app.tabBars.buttons["我的"].tap()
        XCTAssertTrue(app.navigationBars["我的"].waitForExistence(timeout: 3))
        app.staticTexts["隐私政策"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '最少信息'")).firstMatch.waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.staticTexts["用户协议"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '情绪表达'")).firstMatch.waitForExistence(timeout: 5))
    }
}
