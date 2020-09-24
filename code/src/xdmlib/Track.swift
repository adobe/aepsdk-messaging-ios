/*
 Copyright 2020 Adobe. All rights reserved.

 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.

----
 XDM Property Swift Object Generated 2020-06-18 09:41:36.004194 -0700 PDT m=+2.658479325 by XDMTool

 Title			:	Track
 Description	:	
----
*/

import Foundation


struct Track {
	public init() {}

	public var applicationOpened: Bool?
	public var customAction: CustomAction?
	public var id: String?

	enum CodingKeys: String, CodingKey {
		case applicationOpened = "applicationOpened"
		case customAction = "customAction"
		case id = "id"
	}	
}

extension Track:Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = applicationOpened { try container.encode(unwrapped, forKey: .applicationOpened) }
		if let unwrapped = customAction { try container.encode(unwrapped, forKey: .customAction) }
		if let unwrapped = id { try container.encode(unwrapped, forKey: .id) }
	}
}
