# Class - LargeImageTemplate
 
 This class represents a `LargeImage` templated content card authored in Adobe Journey Optimizer. 
 
 A large image template content card includes a title, body, image, and a maximum of three buttons. The image is displayed prominently above the text content in a vertical layout. An optional dismiss button can be added to dismiss the content card. 
 
 Use the `LargeImageTemplate` class to customize the appearance of the large image templated content cards. 
 
 `LargeImageTemplate` conforms to `ObservableObject`, allowing it to be used reactively in SwiftUI views.

## Layout

<img src="../../../Assets/largeimagetemplate-layout.png" width="500" />

## Public properties

| Property      | Type                                           | Description                                                  |
| ------------- | ---------------------------------------------- | ------------------------------------------------------------ |
| title         | [AEPText](../UIElements/aeptext.md)            | The title text for the content card.                         |
| body          | [AEPText](../UIElements/aeptext.md)            | *Optional*<br>The body text of the content card.             |
| image         | [AEPImage](../UIElements/aepimage.md)          | *Optional*<br>The image to be shown on the content card.     |
| buttons       | [[AEPButton](../UIElements/aepbutton.md)]      | *Optional*<br>The list of buttons on the content card.       |
| buttonHStack  | [AEPHStack](../UIElements/aepstack.md)         | A horizontal stack for arranging buttons.                    |
| textVStack    | [AEPVStack](../UIElements/aepstack.md)         | A vertical stack for arranging the title, body, and buttons. |
| rootVStack    | [AEPVStack](../UIElements/aepstack.md)         | A vertical stack for arranging the image and text stack.     |
| dismissButton | [AEPDismissButton](../UIElements/aepdismissbutton.md) | *Optional*<br>The dismiss button for the content card.       |
