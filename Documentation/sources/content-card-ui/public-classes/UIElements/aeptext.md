# Class - AEPText

The `AEPText` class is a fundamental UI component in the AEPSwiftUI framework. It is used to display text for content cards. 

This class allows you to customize the text element with properties like font, color, and modifier. 

`AEPText` class conforms to `ObservableObject`, allowing it to be used reactively in SwiftUI views.

## Properties

| Property | Type | Description | Default Value |
| --- | --- | --- | --- |
| content | String | The actual text content to be displayed. | N/A |
| font | [Font](https://developer.apple.com/documentation/swiftui/font) | The font to be used for the text. |  Depends on the type of text: <br> &bull; **Title**:  system font, size 15, medium weight <br> &bull;  **Body** - system font, size 13, regular weight <br> &bull; **ButtonText**  - system font, size 13, regular weight |
| color | [Color](https://developer.apple.com/documentation/swiftui/color) | The color of the text. | Depends on the type of text: <br> &bull; **Title**: [primary](https://developer.apple.com/documentation/swiftui/color/primary) <br> &bull; **Body**: [secondary](https://developer.apple.com/documentation/swiftui/color/primary) <br> &bull; **Button**: [blue](https://developer.apple.com/documentation/swiftui/color/blue) |
| modifier | AEPViewModifier | A custom view modifer that can be applied to the text view for additional styling | N/A  |

> **Note**: All properties are marked with [@Published](https://developer.apple.com/documentation/combine/published). Any changes will trigger updates to your UI.

## Customization

Below is an example of how to customize the `AEPText` properties when working with a `SmallImageTemplate`:

```swift
class MyCustomizer : ContentCardCustomizing {
    
    func customize(template: SmallImageTemplate) {        
        // Customize the title text element
        template.title.font = .subheadline
        template.title.textColor = .green        
        template.title.modifier = AEPViewModifier(MyTitleModifier())
        
        // Customize the body text element, if available
        template.body?.font = .caption        
    }
    
    struct MyTitleModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(Color.yellow)
                .cornerRadius(5)
        }
    }
}
```