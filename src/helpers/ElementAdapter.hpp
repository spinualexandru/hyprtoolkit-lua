#pragma once

#include "SmartPtrAdapter.hpp"

#include <hyprtoolkit/element/Button.hpp>
#include <hyprtoolkit/element/Checkbox.hpp>
#include <hyprtoolkit/element/ColumnLayout.hpp>
#include <hyprtoolkit/element/Combobox.hpp>
#include <hyprtoolkit/element/Element.hpp>
#include <hyprtoolkit/element/Image.hpp>
#include <hyprtoolkit/element/Line.hpp>
#include <hyprtoolkit/element/Null.hpp>
#include <hyprtoolkit/element/ProgressBar.hpp>
#include <hyprtoolkit/element/Rectangle.hpp>
#include <hyprtoolkit/element/RowLayout.hpp>
#include <hyprtoolkit/element/ScrollArea.hpp>
#include <hyprtoolkit/element/Slider.hpp>
#include <hyprtoolkit/element/Spinbox.hpp>
#include <hyprtoolkit/element/Text.hpp>
#include <hyprtoolkit/element/Textbox.hpp>

namespace Hyprtoolkit::Lua {

inline Hyprutils::Memory::CSharedPointer<IElement> luaToElement(const sol::object& object) {
    using namespace Hyprutils::Memory;

    if (object.is<CSharedPointer<IElement>>())
        return object.as<CSharedPointer<IElement>>();

#define TRY_ELEMENT_TYPE(type)                                      \
    if (object.is<CSharedPointer<type>>()) {                         \
        const auto pointer = object.as<CSharedPointer<type>>();      \
        return CSharedPointer<IElement>(pointer);                    \
    }

    TRY_ELEMENT_TYPE(CTextElement)
    TRY_ELEMENT_TYPE(CButtonElement)
    TRY_ELEMENT_TYPE(CTextboxElement)
    TRY_ELEMENT_TYPE(CCheckboxElement)
    TRY_ELEMENT_TYPE(CSliderElement)
    TRY_ELEMENT_TYPE(CComboboxElement)
    TRY_ELEMENT_TYPE(CSpinboxElement)
    TRY_ELEMENT_TYPE(CRectangleElement)
    TRY_ELEMENT_TYPE(CColumnLayoutElement)
    TRY_ELEMENT_TYPE(CRowLayoutElement)
    TRY_ELEMENT_TYPE(CScrollAreaElement)
    TRY_ELEMENT_TYPE(CImageElement)
    TRY_ELEMENT_TYPE(CNullElement)
    TRY_ELEMENT_TYPE(CLineElement)
    TRY_ELEMENT_TYPE(CProgressBarElement)

#undef TRY_ELEMENT_TYPE

    throw sol::error("expected a Hyprtoolkit Element");
}

} // namespace Hyprtoolkit::Lua
