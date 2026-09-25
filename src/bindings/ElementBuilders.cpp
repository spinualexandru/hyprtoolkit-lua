#include <hyprtoolkit/element/Button.hpp>
#include <hyprtoolkit/element/Checkbox.hpp>
#include <hyprtoolkit/element/ColumnLayout.hpp>
#include <hyprtoolkit/element/Combobox.hpp>
#include <hyprtoolkit/element/Image.hpp>
#include <hyprtoolkit/element/Line.hpp>
#include <hyprtoolkit/element/Null.hpp>
#include <hyprtoolkit/element/ProgressBar.hpp>
#include <hyprtoolkit/element/RadioGroup.hpp>
#include <hyprtoolkit/element/Rectangle.hpp>
#include <hyprtoolkit/element/RowLayout.hpp>
#include <hyprtoolkit/element/ScrollArea.hpp>
#include <hyprtoolkit/element/Slider.hpp>
#include <hyprtoolkit/element/Spinbox.hpp>
#include <hyprtoolkit/element/Text.hpp>
#include <hyprtoolkit/element/Textbox.hpp>
#include <hyprtoolkit/types/ImageTypes.hpp>
#include <sol/sol.hpp>

#include "../helpers/AnimationAdapter.hpp"
#include "../helpers/ByteDataAdapter.hpp"
#include "../helpers/CallbackAdapter.hpp"
#include "../helpers/ColorFnAdapter.hpp"
#include "../helpers/GradientFnAdapter.hpp"
#include "../helpers/SmartPtrAdapter.hpp"

using namespace Hyprutils::Math;
using namespace Hyprutils::Memory;

namespace Hyprtoolkit::Lua {

static std::vector<std::string> luaToStrings(const sol::table& table, std::string_view context) {
    std::vector<std::string> values;
    values.reserve(table.size());
    for (size_t index = 1; index <= table.size(); ++index) {
        const sol::object value = table[index];
        if (!value.is<std::string>())
            throw sol::error(std::string{context} + " expects a dense array of strings");
        values.push_back(value.as<std::string>());
    }
    return values;
}

static size_t luaIndexToCpp(lua_Integer index, std::string_view context) {
    if (index <= 0)
        throw sol::error(std::string{context} + " uses 1-based indices");
    return static_cast<size_t>(index - 1);
}

void registerTextElement(sol::table& module) {
    module.new_usertype<CTextBuilder>(
        "TextBuilder", sol::no_constructor, "begin", &CTextBuilder::begin, "text",
        [](CSharedPointer<CTextBuilder> self, const std::string& text) { return self->text(std::string{text}); }, "color",
        [](CSharedPointer<CTextBuilder> self, const sol::object& color) { return self->color(luaToColorFn(color, "TextBuilder.color")); }, "a", &CTextBuilder::a, "fontSize",
        [](CSharedPointer<CTextBuilder> self, CFontSize size) { return self->fontSize(std::move(size)); }, "align", &CTextBuilder::align, "fontFamily",
        [](CSharedPointer<CTextBuilder> self, const std::string& family) { return self->fontFamily(std::string{family}); }, "clampSize",
        [](CSharedPointer<CTextBuilder> self, const Vector2D& size) { return self->clampSize(Vector2D{size}); }, "callback",
        [](CSharedPointer<CTextBuilder> self, sol::protected_function callback) {
            return self->callback([callback = CLuaCallback{std::move(callback)}]() { invokeLuaCallback(callback, "TextBuilder.callback"); });
        },
        "noEllipsize", &CTextBuilder::noEllipsize, "size",
        [](CSharedPointer<CTextBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "async", &CTextBuilder::async, "interactable",
        &CTextBuilder::interactable, "commence", &CTextBuilder::commence);

    module.new_usertype<CTextElement>(
        "TextElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CTextElement::rebuild, "size", &CTextElement::size, "setText",
        &CTextElement::setText, "animateColor",
        [](CTextElement& self, const sol::object& animation) { self.animateColor(luaToAnimation(animation, "TextElement.animateColor")); });
}

void registerButtonElement(sol::table& module) {
    module.new_usertype<CButtonBuilder>(
        "ButtonBuilder", sol::no_constructor, "begin", &CButtonBuilder::begin, "label",
        [](CSharedPointer<CButtonBuilder> self, const std::string& label) { return self->label(std::string{label}); }, "noBorder", &CButtonBuilder::noBorder, "noBg",
        &CButtonBuilder::noBg, "accent", &CButtonBuilder::accent, "ellipsize", &CButtonBuilder::ellipsize, "enabled", &CButtonBuilder::enabled, "alignText",
        &CButtonBuilder::alignText, "fontFamily",
        [](CSharedPointer<CButtonBuilder> self, const std::string& family) { return self->fontFamily(std::string{family}); }, "fontSize",
        [](CSharedPointer<CButtonBuilder> self, CFontSize size) { return self->fontSize(std::move(size)); }, "onMainClick",
        [](CSharedPointer<CButtonBuilder> self, sol::protected_function callback) {
            return self->onMainClick([callback = CLuaCallback{std::move(callback)}](CSharedPointer<CButtonElement> element) {
                invokeLuaCallback(callback, "ButtonBuilder.onMainClick", element);
            });
        },
        "onRightClick",
        [](CSharedPointer<CButtonBuilder> self, sol::protected_function callback) {
            return self->onRightClick([callback = CLuaCallback{std::move(callback)}](CSharedPointer<CButtonElement> element) {
                invokeLuaCallback(callback, "ButtonBuilder.onRightClick", element);
            });
        },
        "size", [](CSharedPointer<CButtonBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CButtonBuilder::commence);

    module.new_usertype<CButtonElement>("ButtonElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CButtonElement::rebuild, "size",
                                        &CButtonElement::size, "setLabel", &CButtonElement::setLabel, "setEnabled", &CButtonElement::setEnabled);
}

void registerTextboxElement(sol::table& module) {
    module.new_usertype<CTextboxBuilder>(
        "TextboxBuilder", sol::no_constructor, "begin", &CTextboxBuilder::begin, "placeholder",
        [](CSharedPointer<CTextboxBuilder> self, const std::string& placeholder) { return self->placeholder(std::string{placeholder}); }, "defaultText",
        [](CSharedPointer<CTextboxBuilder> self, const std::string& text) { return self->defaultText(std::string{text}); }, "onTextEdited",
        [](CSharedPointer<CTextboxBuilder> self, sol::protected_function callback) {
            return self->onTextEdited([callback = CLuaCallback{std::move(callback)}](CSharedPointer<CTextboxElement> element, const std::string& text) {
                invokeLuaCallback(callback, "TextboxBuilder.onTextEdited", element, text);
            });
        },
        "multiline", &CTextboxBuilder::multiline, "password", &CTextboxBuilder::password, "eyeIcon", &CTextboxBuilder::eyeIcon, "size",
        [](CSharedPointer<CTextboxBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CTextboxBuilder::commence);

    module.new_usertype<CTextboxElement>(
        "TextboxElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CTextboxElement::rebuild, "size", &CTextboxElement::size, "focus",
        [](CTextboxElement& self, sol::optional<bool> focus) { self.focus(focus.value_or(true)); }, "currentText",
        [](CTextboxElement& self) { return std::string{self.currentText()}; }, "cursorPos", &CTextboxElement::cursorPos, "selection",
        [](const CTextboxElement& self) { return self.selection(); }, "setText", &CTextboxElement::setText, "setPassword", &CTextboxElement::setPassword);
}

void registerCheckboxElement(sol::table& module) {
    module.new_enum<eCheckboxStyle>(
        "CheckboxStyle", {{"CHECKMARK", HT_CHECKBOX_STYLE_CHECKMARK}, {"RADIO", HT_CHECKBOX_STYLE_RADIO}});

    module.new_usertype<CCheckboxBuilder>(
        "CheckboxBuilder", sol::no_constructor, "begin", &CCheckboxBuilder::begin, "toggled", &CCheckboxBuilder::toggled, "style", &CCheckboxBuilder::style, "onToggled",
        [](CSharedPointer<CCheckboxBuilder> self, sol::protected_function callback) {
            return self->onToggled([callback = CLuaCallback{std::move(callback)}](CSharedPointer<CCheckboxElement> element, bool state) {
                invokeLuaCallback(callback, "CheckboxBuilder.onToggled", element, state);
            });
        },
        "size", [](CSharedPointer<CCheckboxBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CCheckboxBuilder::commence);

    module.new_usertype<CCheckboxElement>("CheckboxElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CCheckboxElement::rebuild, "size",
                                          &CCheckboxElement::size, "state", &CCheckboxElement::state, "setState", &CCheckboxElement::setState);
}

void registerRadioGroup(sol::table& module) {
    module.new_usertype<CRadioGroup>(
        "RadioGroup", sol::no_constructor, "create", &CRadioGroup::create, "add", &CRadioGroup::add, "selected", &CRadioGroup::selected, "setSelected", &CRadioGroup::setSelected,
        "onSelected",
        [](CRadioGroup& self, sol::protected_function callback) {
            self.onSelected([callback = CLuaCallback{std::move(callback)}](CSharedPointer<CCheckboxElement> selected) {
                invokeLuaCallback(callback, "RadioGroup.onSelected", selected);
            });
        });
}

void registerSliderElement(sol::table& module) {
    module.new_usertype<CSliderBuilder>(
        "SliderBuilder", sol::no_constructor, "begin", &CSliderBuilder::begin, "min", &CSliderBuilder::min, "max", &CSliderBuilder::max, "val", &CSliderBuilder::val, "snapInt",
        &CSliderBuilder::snapInt, "showLabel", &CSliderBuilder::showLabel, "onChanged",
        [](CSharedPointer<CSliderBuilder> self, sol::protected_function callback) {
            return self->onChanged([callback = CLuaCallback{std::move(callback)}](CSharedPointer<CSliderElement> element, float value) {
                invokeLuaCallback(callback, "SliderBuilder.onChanged", element, value);
            });
        },
        "size", [](CSharedPointer<CSliderBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CSliderBuilder::commence);

    module.new_usertype<CSliderElement>("SliderElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CSliderElement::rebuild, "size",
                                        &CSliderElement::size, "sliding", &CSliderElement::sliding);
}

void registerComboboxElement(sol::table& module) {
    module.new_usertype<CComboboxBuilder>(
        "ComboboxBuilder", sol::no_constructor, "begin", &CComboboxBuilder::begin, "items",
        [](CSharedPointer<CComboboxBuilder> self, const sol::table& items) { return self->items(luaToStrings(items, "ComboboxBuilder.items")); }, "currentItem",
        [](CSharedPointer<CComboboxBuilder> self, lua_Integer index) { return self->currentItem(luaIndexToCpp(index, "ComboboxBuilder.currentItem")); }, "onChanged",
        [](CSharedPointer<CComboboxBuilder> self, sol::protected_function callback) {
            return self->onChanged([callback = CLuaCallback{std::move(callback)}](CSharedPointer<CComboboxElement> element, size_t index) {
                invokeLuaCallback(callback, "ComboboxBuilder.onChanged", element, index + 1);
            });
        },
        "size", [](CSharedPointer<CComboboxBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CComboboxBuilder::commence);

    module.new_usertype<CComboboxElement>(
        "ComboboxElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CComboboxElement::rebuild, "size", &CComboboxElement::size, "current",
        [](CComboboxElement& self) { return self.current() + 1; }, "setCurrent",
        [](CComboboxElement& self, lua_Integer index) { self.setCurrent(luaIndexToCpp(index, "ComboboxElement.setCurrent")); });
}

void registerSpinboxElement(sol::table& module) {
    module.new_usertype<CSpinboxBuilder>(
        "SpinboxBuilder", sol::no_constructor, "begin", &CSpinboxBuilder::begin, "label",
        [](CSharedPointer<CSpinboxBuilder> self, const std::string& label) { return self->label(std::string{label}); }, "items",
        [](CSharedPointer<CSpinboxBuilder> self, const sol::table& items) { return self->items(luaToStrings(items, "SpinboxBuilder.items")); }, "currentItem",
        [](CSharedPointer<CSpinboxBuilder> self, lua_Integer index) { return self->currentItem(luaIndexToCpp(index, "SpinboxBuilder.currentItem")); }, "onChanged",
        [](CSharedPointer<CSpinboxBuilder> self, sol::protected_function callback) {
            return self->onChanged([callback = CLuaCallback{std::move(callback)}](CSharedPointer<CSpinboxElement> element, size_t index) {
                invokeLuaCallback(callback, "SpinboxBuilder.onChanged", element, index + 1);
            });
        },
        "fill", &CSpinboxBuilder::fill, "size", [](CSharedPointer<CSpinboxBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence",
        &CSpinboxBuilder::commence);

    module.new_usertype<CSpinboxElement>(
        "SpinboxElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CSpinboxElement::rebuild, "size", &CSpinboxElement::size, "current",
        [](CSpinboxElement& self) { return self.current() + 1; }, "setCurrent",
        [](CSpinboxElement& self, lua_Integer index) { self.setCurrent(luaIndexToCpp(index, "SpinboxElement.setCurrent")); });
}

void registerRectangleElement(sol::table& module) {
    module.new_usertype<CRectangleBuilder>(
        "RectangleBuilder", sol::no_constructor, "begin", &CRectangleBuilder::begin, "color",
        [](CSharedPointer<CRectangleBuilder> self, const sol::object& color) { return self->color(luaToColorFn(color, "RectangleBuilder.color")); }, "borderColor",
        [](CSharedPointer<CRectangleBuilder> self, const sol::object& color) { return self->borderColor(luaToColorFn(color, "RectangleBuilder.borderColor")); }, "borderGradient",
        [](CSharedPointer<CRectangleBuilder> self, const sol::object& gradient) { return self->borderGradient(luaToGradientFn(gradient)); }, "rounding",
        &CRectangleBuilder::rounding, "borderThickness", &CRectangleBuilder::borderThickness, "size",
        [](CSharedPointer<CRectangleBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CRectangleBuilder::commence);

    module.new_usertype<CRectangleElement>(
        "RectangleElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CRectangleElement::rebuild, "size", &CRectangleElement::size,
        "animateColor", [](CRectangleElement& self, const sol::object& animation) { self.animateColor(luaToAnimation(animation, "RectangleElement.animateColor")); },
        "animateBorderColor",
        [](CRectangleElement& self, const sol::object& animation) { self.animateBorderColor(luaToAnimation(animation, "RectangleElement.animateBorderColor")); });
}

void registerColumnLayoutElement(sol::table& module) {
    module.new_usertype<CColumnLayoutBuilder>(
        "ColumnLayoutBuilder", sol::no_constructor, "begin", &CColumnLayoutBuilder::begin, "gap", &CColumnLayoutBuilder::gap, "size",
        [](CSharedPointer<CColumnLayoutBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CColumnLayoutBuilder::commence);
    module.new_usertype<CColumnLayoutElement>("ColumnLayoutElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CColumnLayoutElement::rebuild,
                                              "size", &CColumnLayoutElement::size);
}

void registerRowLayoutElement(sol::table& module) {
    module.new_usertype<CRowLayoutBuilder>(
        "RowLayoutBuilder", sol::no_constructor, "begin", &CRowLayoutBuilder::begin, "gap", &CRowLayoutBuilder::gap, "size",
        [](CSharedPointer<CRowLayoutBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CRowLayoutBuilder::commence);
    module.new_usertype<CRowLayoutElement>("RowLayoutElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CRowLayoutElement::rebuild,
                                           "size", &CRowLayoutElement::size);
}

void registerScrollAreaElement(sol::table& module) {
    module.new_usertype<CScrollAreaBuilder>(
        "ScrollAreaBuilder", sol::no_constructor, "begin", &CScrollAreaBuilder::begin, "scrollX", &CScrollAreaBuilder::scrollX, "scrollY", &CScrollAreaBuilder::scrollY,
        "blockUserScroll", &CScrollAreaBuilder::blockUserScroll, "showScrollbar", &CScrollAreaBuilder::showScrollbar, "size",
        [](CSharedPointer<CScrollAreaBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CScrollAreaBuilder::commence);
    module.new_usertype<CScrollAreaElement>(
        "ScrollAreaElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CScrollAreaElement::rebuild, "size", &CScrollAreaElement::size,
        "getCurrentScroll", &CScrollAreaElement::getCurrentScroll, "setScroll", &CScrollAreaElement::setScroll);
}

void registerImageElement(sol::table& module) {
    module.new_enum<eImageFitMode>(
        "ImageFitMode", {{"STRETCH", IMAGE_FIT_MODE_STRETCH}, {"COVER", IMAGE_FIT_MODE_COVER}, {"CONTAIN", IMAGE_FIT_MODE_CONTAIN}, {"TILE", IMAGE_FIT_MODE_TILE}});

    module.new_usertype<CImageBuilder>(
        "ImageBuilder", sol::no_constructor, "begin", &CImageBuilder::begin, "path",
        [](CSharedPointer<CImageBuilder> self, const std::string& path) { return self->path(std::string{path}); }, "icon", &CImageBuilder::icon, "data",
        [](CSharedPointer<CImageBuilder> self, const sol::object& data) { return self->data(luaToBytes(data)); }, "a", &CImageBuilder::a, "fitMode", &CImageBuilder::fitMode,
        "sync", &CImageBuilder::sync, "rounding", &CImageBuilder::rounding, "size",
        [](CSharedPointer<CImageBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CImageBuilder::commence);
    module.new_usertype<CImageElement>("ImageElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CImageElement::rebuild, "size",
                                       &CImageElement::size);
}

void registerNullElement(sol::table& module) {
    module.new_usertype<CNullBuilder>(
        "NullBuilder", sol::no_constructor, "begin", &CNullBuilder::begin, "size",
        [](CSharedPointer<CNullBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CNullBuilder::commence);
    module.new_usertype<CNullElement>("NullElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CNullElement::rebuild, "size",
                                      &CNullElement::size);
}

void registerLineElement(sol::table& module) {
    module.new_usertype<CLineBuilder>(
        "LineBuilder", sol::no_constructor, "begin", &CLineBuilder::begin, "color",
        [](CSharedPointer<CLineBuilder> self, const sol::object& color) { return self->color(luaToColorFn(color, "LineBuilder.color")); }, "thick", &CLineBuilder::thick, "points",
        [](CSharedPointer<CLineBuilder> self, const sol::table& points) {
            std::vector<Vector2D> converted;
            converted.reserve(points.size());
            for (size_t index = 1; index <= points.size(); ++index) {
                const sol::object point = points[index];
                if (point.is<Vector2D>()) {
                    converted.push_back(point.as<Vector2D>());
                    continue;
                }
                if (point.is<sol::table>()) {
                    const sol::table coordinates = point.as<sol::table>();
                    converted.emplace_back(coordinates[1].get<double>(), coordinates[2].get<double>());
                    continue;
                }
                throw sol::error("LineBuilder.points expects Vector2D values or {x, y} arrays");
            }
            return self->points(std::move(converted));
        },
        "size", [](CSharedPointer<CLineBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CLineBuilder::commence);
    module.new_usertype<CLineElement>("LineElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CLineElement::rebuild, "size",
                                      &CLineElement::size);
}

void registerProgressBarElement(sol::table& module) {
    module.new_usertype<CProgressBarBuilder>(
        "ProgressBarBuilder", sol::no_constructor, "begin", &CProgressBarBuilder::begin, "value", &CProgressBarBuilder::value, "indeterminate",
        &CProgressBarBuilder::indeterminate, "size",
        [](CSharedPointer<CProgressBarBuilder> self, CDynamicSize size) { return self->size(std::move(size)); }, "commence", &CProgressBarBuilder::commence);
    module.new_usertype<CProgressBarElement>("ProgressBarElement", sol::no_constructor, sol::base_classes, sol::bases<IElement>(), "rebuild", &CProgressBarElement::rebuild,
                                             "size", &CProgressBarElement::size, "value", &CProgressBarElement::value, "setValue", &CProgressBarElement::setValue);
}

void registerElementBuilders(sol::table& module) {
    registerTextElement(module);
    registerButtonElement(module);
    registerTextboxElement(module);
    registerCheckboxElement(module);
    registerRadioGroup(module);
    registerSliderElement(module);
    registerComboboxElement(module);
    registerSpinboxElement(module);
    registerRectangleElement(module);
    registerColumnLayoutElement(module);
    registerRowLayoutElement(module);
    registerScrollAreaElement(module);
    registerImageElement(module);
    registerNullElement(module);
    registerLineElement(module);
    registerProgressBarElement(module);
}

} // namespace Hyprtoolkit::Lua
