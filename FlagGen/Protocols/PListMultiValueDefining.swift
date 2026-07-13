//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

public protocol PListMultiValueDefining: CaseIterable & RawRepresentable & PListMultiValueElementDefining {
    /// Displayed as line item in Settings App
    static var pListTitle: String { get }

    static func pListValues(defaultValue: Self) -> [PListMultiValueElement<Self>]
    static func pListEnumEntry(key: String, defaultValue: Self) -> PListEnum<Self>
}

extension PListMultiValueDefining {
    public static func pListValues(defaultValue: Self) -> [PListMultiValueElement<Self>] {
        Self.allCases.map { PListMultiValueElement(
            value: $0.rawValue,
            isDefault: defaultValue.rawValue == $0.rawValue,
            title: $0.pListElementTitle,
            shortTitle: $0.pListElementShortTitle
        ) }
    }

    public static func pListEnumEntry(key: String, defaultValue: Self) -> PListEnum<Self> {
        PListEnum(key: key, title: Self.pListTitle, defaultValue: defaultValue)
    }

    public static func pListRadioGroupEntry(
        key: String,
        defaultValue: Self,
        footer: String?,
        sortByTitle: Bool
    ) -> PListRadioGroup<Self> {
        PListRadioGroup(
            key: key,
            title: Self.pListTitle,
            defaultValue: defaultValue,
            footer: footer,
            sortByTitle: sortByTitle
        )
    }
}
