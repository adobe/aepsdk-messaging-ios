# Terminology

`Datastream` : A datastream is a server-side configuration on Platform Edge Network that controls where data goes. Datastreams ensure that incoming data is routed to the Adobe Experience Platform application and services (like Target) appropriatel. For more information, see the [datastreams documentation](https://experienceleague.adobe.com/docs/experience-platform/edge/datastreams/overview.html?lang=en) or this [video](https://experienceleague.adobe.com/docs/platform-learn/data-collection/edge-network/configure-datastreams.html?lang=en).

`Decision` (or `Activity`): A decision contains the logic that informs the selection of an offer.

`Decision Scope`: An Adobe Target mbox location name or a base64 encoded JSON, containing Offer Decisioning activityId, placementId and an optional itemCount, serialized to UTF-8 string. It specifies the context in which an offer appears to the user and is usually associated with a decision activity.

`Field group` : A schema is made up of building blocks called field groups. Think of field groups as blueprints for specific groups of data; the data properties describing things like: the current device in use, products and contents/state of carts, information about the users themselves, etc. 

For example, the `Commerce Details` field group has properties for common commerce-related data like: 
- Product information (SKU, name, quantity)
- Cart state (abandons, product add sources, etc.). 

This logical grouping helps organize individual data properties into easily understandable sections. They are even reusable! Once you define a field group, you can use it in any schema that has a compatible class (some field groups only make sense with the capabilities of certain schema classes). There are two types of field groups available:

1. Adobe defined - standardized templates of common use-cases and datasets created and updated by Adobe
    - Note that Adobe Experience Platform services implicitly understand standard field groups and can provide additional functionality on top of just reading and writing data. That's why it is strongly recommended that you use standard field groups wherever possible.
2. Custom defined - any field group outside of the Adobe defined ones that users can use to create their own custom collections of data properties  

See the [Field Groups section in the Basics of schema composition](https://experienceleague.adobe.com/docs/experience-platform/xdm/schema/composition.html?lang=en#field-group) for an in depth look at how field groups work in the context of XDM schemas.

`Offer`: An offer is a marketing message that may have rules associated with it that specify who is eligible to see the offer.

`Proposition`: It encapsulates the offers proposed for a given scope based on certain eligibility rules and constraints.

