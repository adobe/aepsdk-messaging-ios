# ContentCardCustomizing

Protocol defining methodology for customizing content cards based on the template type.

## Protocol Definition

```swift
protocol ContentCardCustomizing {
    func customize(template: SmallImageTemplate)
}
```

## Methods

### customize 

Customize content cards with [SmallImageTemplate](../public-classes/Template/smallimage-template.md).

#### Parameters

- _template_ - The `SmallImageTemplate` instance to be customized.

``` swift
func customize(template: SmallImageTemplate)
```