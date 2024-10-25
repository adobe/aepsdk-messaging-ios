# Class - SmallImageTemplate
 
 This class represents a `SmallImage` templated content card authored in Adobe Journey Optimizer. 
 
 A small image template content card includes a title, body, image, and a maximum of three buttons. The image is displayed in line with the text content.  An optional dismiss button can be added to dismiss the content card. 
 
 Use the `SmallImageTemplate` class to customize the appearance of the small image templated content cards. 
 
 `SmallImageTemplate` conforms to `ObservableObject`, allowing it to be used reactively in SwiftUI views.

## Layout

<img src="../../../Assets/smallimagetemplate-layout.png" width="500" />

## Public properties

| Property      | Type                                           | Description                                                  |
| ------------- | ---------------------------------------------- | ------------------------------------------------------------ |
| title         | [AEPText](../UIElements/aeptext.md)            | The title text for the content card.                         |
| body          | [AEPText](../UIElements/aeptext.md)            | *Optional*<br>The body text of the content card.             |
| image         | [AEPImage](../UIElements/aepimage.md)          | *Optional*<br>The image to be shown on the content card.     |
| buttons       | [[AEPButton](../UIElements/aepbutton.md)]      | *Optional*<br>The list of buttons on the content card.       |
| buttonHStack  | [AEPHStack](../UIElements/aepstack.md)         | A horizontal stack for arranging buttons.                    |
| textVStack    | [AEPVStack](../UIElements/aepstack.md)         | A vertical stack for arranging the title, body, and buttons. |
| rootHStack    | [AEPHStack](../UIElements/aepstack.md)         | A horizontal stack for arranging the image and text stack.   |
| dismissButton | [AEPButton](../UIElements/aepdismissbutton.md) | *Optional*<br>The dismiss button for the content card.       |