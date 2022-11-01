# Configuration keys

To update the SDK configuration programmatically, use the following information to change the Optimize extension configuration values. 

> [!NOTE]
> If the override dataset is used for proposition tracking, make sure the corresponding schema definition contains the `Experience Event - Proposition Interaction` field group. For more information, see the setup [schemas](https://experienceleague.adobe.com/docs/experience-platform/xdm/ui/overview.html?lang=en) and [datasets](https://experienceleague.adobe.com/docs/experience-platform/catalog/datasets/user-guide.html?lang=en) guides.

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| optimize.datasetId | String | No | Override dataset's Identifier which can be obtained from the Experience Platform UI. For more details see, [Datasets UI guide](https://experienceleague.adobe.com/docs/experience-platform/catalog/datasets/user-guide.html?lang=en) |
