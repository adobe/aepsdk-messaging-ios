//
//  WidgetMessagingDemoAppSwiftUIBundle.swift
//  WidgetMessagingDemoAppSwiftUI
//
//  Created by Pravin Prakash Kumar on 4/7/25.
//

import WidgetKit
import SwiftUI

@main
struct WidgetMessagingDemoAppSwiftUIBundle: WidgetBundle {
    var body: some Widget {
        GameScoreLiveActivity()
        FoodDeliveryLiveActivity()
        AirplaneLiveActivity()
    }
}
