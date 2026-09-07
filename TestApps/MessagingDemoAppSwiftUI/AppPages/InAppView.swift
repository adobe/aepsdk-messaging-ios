/*
Copyright 2023 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import AEPCore
import AEPEdge
import AEPMessaging
import AEPServices
import Combine
import SwiftUI
import WebKit

struct InAppView: View {
    @State private var viewDidLoad = false
    @StateObject private var messageHandler = MessageHandler()
    @State private var shouldShowMessages = true
    @State private var headlessPaywallMode = false
    @State private var freeArticlesRead = 0
    @State private var customAction = ""

    /// Number of free articles before the paywall. In production this rule lives in the AJO campaign.
    private let freeArticleLimit = 3
    /// The track action the AJO paywall campaign is configured to trigger on. Reusing the demo's
    /// known IAM trigger ("fullscreen_ss") so the paywall qualifies without extra campaign setup.
    private let paywallTriggerAction = "fullscreen_ss"
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
        VStack {
            VStack {
                Text("In-app")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 10)
                    .padding(.bottom, -15)
                Divider().padding(.bottom, 5).padding(.top, 0)
            }
            Grid(alignment: .leading, horizontalSpacing: 70, verticalSpacing: 20) {
                GridRow {
                    Button("fullscreen") {
                        MobileCore.track(action: "fullscreen_ss", data: ["testFullscreen": "true"])
                    }
                    
                    Button("modal") {
                        MobileCore.track(action: "untilClicked", data: ["testModal": "true"])
                    }
                }
                GridRow {
                    Button("top banner") {
                        MobileCore.track(action: "triggerBannerTop", data: ["testBannerTop": "true"])
                    }
                    
                    Button("bottom banner") {
                        MobileCore.track(action: "surfaceTesting", data: nil)
                    }
                }
            }
            VStack {
                Text("Content card qualification")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 10)
                    .padding(.bottom, -15)
                Divider().padding(.bottom, 5).padding(.top, 0)
            }
            Grid(alignment: .leading, horizontalSpacing: 70, verticalSpacing: 20) {
                GridRow {
                    Button("qualify 1") {
                        MobileCore.track(action: "timestampz", data: nil)
                    }
                    Button("qualify 2") {
                        let experienceEvent = ExperienceEvent(xdm: ["player": "julio"])
                        Edge.sendEvent(experienceEvent: experienceEvent)
                    }
                }
                GridRow {
                    Button("qualify 3") {
                        MobileCore.track(action: "sticky", data: nil)
                    }
                    Button("request cards") {
                        let msContentCardsSurface = Surface(path: "cards/ms")
                        Messaging.updatePropositionsForSurfaces([msContentCardsSurface])
                    }
                }
                
            }
            VStack {
                Text("Messaging delegate")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 10)
                    .padding(.bottom, -15)
                Divider().padding(.bottom, 5).padding(.top, 0)
            }
            Grid(alignment: .center, horizontalSpacing: 30, verticalSpacing: 30) {
                GridRow {
                    Button("refresh messages") {
                        Messaging.refreshInAppMessages()
                    }
                    Button("show stored messages") {
                        messageHandler.currentMessage?.show()
                    }
                }
                GridRow {
                    Toggle("Show message when triggered", isOn: $shouldShowMessages)
                        .onChange(of: shouldShowMessages) { _ in
                            messageHandler.showMessages.toggle()
                        }
                }
                .gridCellColumns(2)
                .gridCellUnsizedAxes([.horizontal])
            }
            VStack {
                Text("Headless paywall demo")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 10)
                    .padding(.bottom, -15)
                Divider().padding(.bottom, 5).padding(.top, 0)
            }
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Headless paywall mode", isOn: $headlessPaywallMode)
                    .onChange(of: headlessPaywallMode) { newValue in
                        messageHandler.headlessPaywallMode = newValue
                    }
                Text("Simulates a news app: each \"Read a free article\" tap sends a track action. After "
                    + "\(freeArticleLimit) reads, the app fires the track action that the AJO paywall campaign "
                    + "matches — the SDK qualifies the IAM, the delegate suppresses it, shows this native paywall, "
                    + "and calls Message.recordDisplay() so the campaign frequency cap still applies (no custom IDs).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("Read a free article  (\(freeArticlesRead)/\(freeArticleLimit))") {
                    // Track every article read (analytics event on each tap).
                    freeArticlesRead += 1
                    MobileCore.track(action: "articleRead", data: ["articleNumber": "\(freeArticlesRead)"])

                    // Once the free limit is hit, fire the track action the paywall campaign triggers on.
                    // With "Headless paywall mode" ON, shouldShowMessage() intercepts it and shows PaywallView.
                    if freeArticlesRead >= freeArticleLimit {
                        MobileCore.track(action: paywallTriggerAction, data: ["reason": "freeArticleLimitReached"])
                        freeArticlesRead = 0 // reset so the demo can be repeated
                    }
                }
                // Direct one-tap trigger: fires the paywall campaign's track action immediately.
                Button("Trigger paywall now (track action)") {
                    MobileCore.track(action: paywallTriggerAction, data: ["reason": "manualTrigger"])
                }
                if messageHandler.paywallTriggerCount > 0 {
                    Text("Paywall presented \(messageHandler.paywallTriggerCount) time(s) this session")
                        .font(.caption).foregroundColor(.blue)
                }
                if !messageHandler.lastStatus.isEmpty {
                    Text(messageHandler.lastStatus)
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 25)
            VStack {
                Text("Custom action testing")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 10)
                    .padding(.bottom, -15)
                Divider().padding(.bottom, 5).padding(.top, 0)
            }
            Grid(alignment: .leading, horizontalSpacing: 70, verticalSpacing: 30) {
                GridRow {
                    TextField("Enter custom action...", text: $customAction).padding(.leading, 25)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                GridRow {
                    Button("track") {
                        guard !customAction.isEmpty else {
                            return
                        }
                        MobileCore.track(action: customAction, data: nil)
                    }.padding(.leading, 25)
                }
            }
        }
        .padding(.bottom, 20)
        } // ScrollView
        .onAppear {
            if viewDidLoad == false {
                viewDidLoad = true
                MobileCore.messagingDelegate = messageHandler
            }
        }
        .sheet(isPresented: $messageHandler.showPaywall) {
            PaywallView(activityId: messageHandler.paywallActivityId) {
                messageHandler.showPaywall = false
            }
        }
    }
}

/// Messaging delegate
private final class MessageHandler: ObservableObject, MessagingDelegate {
    var showMessages = true
    var currentMessage: Message?
    let autoDismiss = false

    // MARK: - Headless paywall demo state
    /// When true, triggered IAMs are suppressed and the app presents its own paywall instead,
    /// while still recording the display so AJO frequency capping applies.
    var headlessPaywallMode = false
    @Published var showPaywall = false
    @Published var paywallActivityId = ""
    @Published var paywallTriggerCount = 0
    @Published var lastStatus = ""

    func onShow(message: Showable) {
        let fullscreenMessage = message as? FullscreenMessage
        print("message was shown \(fullscreenMessage?.debugDescription ?? "undefined")")
    }

    func onDismiss(message: Showable) {
        let fullscreenMessage = message as? FullscreenMessage
        print("message was dismissed \(fullscreenMessage?.debugDescription ?? "undefined")")
    }

    func shouldShowMessage(message: Showable) -> Bool {

        // access to the whole message from the parent
        let fullscreenMessage = message as? FullscreenMessage
        let message = fullscreenMessage?.parent

        // MARK: - Headless paywall (customer scenario)
        // Suppress the SDK's own UI, present our own paywall, and still record the display so the
        // campaign's frequency-capping / show-once rules stop the paywall from re-triggering on every
        // launch. `recordDisplay()` writes to the device Event History using the message's OWN
        // `activityId` — no custom key-value identifiers required.
        if headlessPaywallMode, let iam = message {
            iam.recordDisplay()                          // on-device Event History → frequency capping works
            iam.track(withEdgeEventType: .display)       // (optional) AJO reporting / server-side impression
            DispatchQueue.main.async {
                self.currentMessage = iam
                self.paywallTriggerCount += 1
                // TODO: MOB-24075 — swap iam.id for iam.activityId once Message.activityId is re-enabled.
                // iam.id is propositionItem.itemId (changes per fetch); activityId is scopeDetails.activity.id (stable).
                self.paywallActivityId = iam.id
                self.lastStatus = "Suppressed SDK UI; recordDisplay() + track(.display) sent for id \(iam.id)"
                self.showPaywall = true                  // present the app's own paywall
            }
            return false                                 // do NOT let the SDK show its fullscreen message
        }

        // in-line handling of javascript calls
        // see Assets/nativeMethodCallingSample.html for an example of how to call this method
        message?.handleJavascriptMessage("buttonClicked") { content in
            print("magical handling of our content from js! content is: \(content ?? "empty")")
            message?.track(content as? String, withEdgeEventType: .interact)
        }

        // if using the webview for something, make sure to dispatch back to the main thread
        DispatchQueue.main.async {
            // access the WKWebView containing the message's UI
            let messageWebView = message?.view as? WKWebView
            // execute JavaScript inside of the message's WKWebView
            messageWebView?.evaluateJavaScript("startTimer();") { result, error in
                if error != nil {
                    // handle error
                }
                if result != nil {
                    // do something with the result
                }
            }
        }
        
        // if we're not showing the message now, we can save it for later
        if !showMessages {
            currentMessage = message
//            currentMessage?.track("message suppressed", withEdgeEventType: .trigger)
        } else if autoDismiss {
            currentMessage = message
            let _ = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
                timer.invalidate()
                self.currentMessage?.track("test for reporting", withEdgeEventType: .interact)
                self.currentMessage?.dismiss()
            }
        }

        return showMessages
    }

    func urlLoaded(_ url: URL) {
        print("fullscreen message loaded url: \(url)")
    }
}

/// A realistic, app-owned **news-app paywall** shown in place of the SDK's in-app message when
/// headless mode is on. Mimics the daily-life case: the reader has used their free articles, AJO
/// decides to show a paywall, and the app renders this native screen (with StoreKit-style plan
/// cards) instead of the SDK's web overlay.
struct PaywallView: View {
    let activityId: String
    var onClose: () -> Void

    @State private var selectedPlan: Plan = .annual

    enum Plan: String, CaseIterable, Identifiable {
        case monthly, annual
        var id: String { rawValue }
        var title: String { self == .monthly ? "Monthly" : "Annual" }
        var price: String { self == .monthly ? "$9.99" : "$79.99" }
        var period: String { self == .monthly ? "per month" : "per year" }
        var badge: String? { self == .annual ? "BEST VALUE · SAVE 33%" : nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding([.top, .trailing], 16)

            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.accentColor)
                    Text("You've read all 3 free articles this month")
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text("Subscribe to keep reading unlimited stories, exclusive analysis, and the daily briefing.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        benefit("Unlimited articles")
                        benefit("Ad-free reading")
                        benefit("Offline & audio articles")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        ForEach(Plan.allCases) { plan in
                            planCard(plan)
                        }
                    }
                    .padding(.horizontal)

                    Button(action: onClose) {
                        Text(selectedPlan == .annual ? "Start 7-day free trial" : "Subscribe")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)

                    Button("Restore purchase", action: onClose).font(.footnote)
                    Button("Not now", action: onClose).font(.footnote).foregroundColor(.secondary)

                    // Demo footprint — proves the paywall was driven by an AJO IAM, and that its
                    // display was recorded so the campaign's frequency cap is honored.
                    VStack(spacing: 4) {
                        if !activityId.isEmpty {
                            Text("Triggered by AJO campaign · activityId \(activityId)")
                                .font(.caption2.monospaced())
                        }
                        Text("Display recorded via Message.recordDisplay() — respects the campaign frequency cap.")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 6)
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
        }
    }

    private func benefit(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            Text(text).font(.subheadline)
        }
    }

    private func planCard(_ plan: Plan) -> some View {
        let selected = plan == selectedPlan
        return Button {
            selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let badge = plan.badge {
                        Text(badge).font(.caption2.weight(.bold)).foregroundColor(.orange)
                    }
                    Text(plan.title).font(.headline)
                    Text("\(plan.price) \(plan.period)").font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selected ? .accentColor : .secondary)
                    .font(.system(size: 22))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? Color.accentColor : Color.gray.opacity(0.3),
                            lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct InAppView_Previews: PreviewProvider {
    static var previews: some View {
        InAppView()
    }
}
