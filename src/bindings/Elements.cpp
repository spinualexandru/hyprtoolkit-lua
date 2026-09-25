#include <hyprtoolkit/core/Input.hpp>
#include <hyprtoolkit/element/Element.hpp>
#include <hyprtoolkit/types/PointerShape.hpp>
#include <sol/sol.hpp>

#include "../helpers/AnimationAdapter.hpp"
#include "../helpers/CallbackAdapter.hpp"
#include "../helpers/ElementAdapter.hpp"
#include "../helpers/SmartPtrAdapter.hpp"

using namespace Hyprutils::Math;

namespace Hyprtoolkit::Lua {

void registerElement(sol::table& module) {
    module.new_enum<IElement::ePositionMode>(
        "PositionMode", {{"ABSOLUTE", IElement::HT_POSITION_ABSOLUTE}, {"AUTO", IElement::HT_POSITION_AUTO}});
    module.new_enum<IElement::ePositionFlag>(
        "PositionFlag",
        {{"HCENTER", IElement::HT_POSITION_FLAG_HCENTER}, {"VCENTER", IElement::HT_POSITION_FLAG_VCENTER}, {"CENTER", IElement::HT_POSITION_FLAG_CENTER},
         {"LEFT", IElement::HT_POSITION_FLAG_LEFT}, {"RIGHT", IElement::HT_POSITION_FLAG_RIGHT}, {"TOP", IElement::HT_POSITION_FLAG_TOP},
         {"BOTTOM", IElement::HT_POSITION_FLAG_BOTTOM}, {"ALL", IElement::HT_POSITION_FLAG_ALL}});
    module.new_enum<ePointerShape>(
        "PointerShape",
        {{"ARROW", HT_POINTER_ARROW}, {"POINTER", HT_POINTER_POINTER}, {"TEXT", HT_POINTER_TEXT}, {"RESIZE_NS", HT_POINTER_RESIZE_NS}, {"RESIZE_EW", HT_POINTER_RESIZE_EW},
         {"RESIZE_NESW", HT_POINTER_RESIZE_NESW}, {"RESIZE_NWSE", HT_POINTER_RESIZE_NWSE}});

    module.new_usertype<IElement>(
        "Element", sol::no_constructor, "size", &IElement::size, "posFromParent", &IElement::posFromParent, "reposition",
        sol::overload([](IElement& self, const CBox& box) { self.reposition(box); },
                      [](IElement& self, const CBox& box, const Vector2D& maxSize) { self.reposition(box, maxSize); }),
        "forceReposition", &IElement::forceReposition, "setPositionMode", &IElement::setPositionMode, "setPositionFlag", &IElement::setPositionFlag, "setAbsolutePosition",
        &IElement::setAbsolutePosition, "addChild",
        [](IElement& self, const sol::object& child) {
            self.addChild(luaToElement(child));
        },
        "removeChild",
        [](IElement& self, const sol::object& child) {
            self.removeChild(luaToElement(child));
        },
        "clearChildren", &IElement::clearChildren, "setMargin", &IElement::setMargin, "setGrouped", &IElement::setGrouped, "setTooltip",
        [](IElement& self, const std::string& tooltip) {
            self.setTooltip(std::string{tooltip});
        },
        "setGrow",
        sol::overload(static_cast<void (IElement::*)(bool)>(&IElement::setGrow), static_cast<void (IElement::*)(bool, bool)>(&IElement::setGrow)), "setReceivesMouse",
        &IElement::setReceivesMouse, "setMouseEnter",
        [](IElement& self, sol::protected_function callback) {
            self.setMouseEnter([callback = CLuaCallback{std::move(callback)}](const Vector2D& position) {
                invokeLuaCallback(callback, "Element.setMouseEnter", position);
            });
        },
        "setMouseLeave",
        [](IElement& self, sol::protected_function callback) {
            self.setMouseLeave([callback = CLuaCallback{std::move(callback)}]() {
                invokeLuaCallback(callback, "Element.setMouseLeave");
            });
        },
        "setMouseMove",
        [](IElement& self, sol::protected_function callback) {
            self.setMouseMove([callback = CLuaCallback{std::move(callback)}](const Vector2D& position) {
                invokeLuaCallback(callback, "Element.setMouseMove", position);
            });
        },
        "setMouseButton",
        [](IElement& self, sol::protected_function callback) {
            self.setMouseButton([callback = CLuaCallback{std::move(callback)}](Input::eMouseButton button, bool pressed) {
                invokeLuaCallback(callback, "Element.setMouseButton", button, pressed);
            });
        },
        "setMouseAxis",
        [](IElement& self, sol::protected_function callback) {
            self.setMouseAxis([callback = CLuaCallback{std::move(callback)}](Input::eAxisAxis axis, float delta) {
                invokeLuaCallback(callback, "Element.setMouseAxis", axis, delta);
            });
        },
        "setReceivesTouch", &IElement::setReceivesTouch, "setTouchDown",
        [](IElement& self, sol::protected_function callback) {
            self.setTouchDown([callback = CLuaCallback{std::move(callback)}](const Input::STouchEvent& event) {
                invokeLuaCallback(callback, "Element.setTouchDown", event);
            });
        },
        "setTouchMotion",
        [](IElement& self, sol::protected_function callback) {
            self.setTouchMotion([callback = CLuaCallback{std::move(callback)}](const Input::STouchEvent& event) {
                invokeLuaCallback(callback, "Element.setTouchMotion", event);
            });
        },
        "setTouchUp",
        [](IElement& self, sol::protected_function callback) {
            self.setTouchUp([callback = CLuaCallback{std::move(callback)}](const Input::STouchEvent& event) {
                invokeLuaCallback(callback, "Element.setTouchUp", event);
            });
        },
        "setTouchCancel",
        [](IElement& self, sol::protected_function callback) {
            self.setTouchCancel([callback = CLuaCallback{std::move(callback)}](const Input::STouchEvent& event) {
                invokeLuaCallback(callback, "Element.setTouchCancel", event);
            });
        },
        "setRepositioned",
        [](IElement& self, sol::protected_function callback) {
            self.setRepositioned([callback = CLuaCallback{std::move(callback)}]() {
                invokeLuaCallback(callback, "Element.setRepositioned");
            });
        },
        "setOpacity", &IElement::setOpacity, "animateOpacity",
        [](IElement& self, const sol::object& animation) { self.animateOpacity(luaToAnimation(animation, "Element.animateOpacity")); }, "animateGeometry",
        [](IElement& self, const sol::object& animation) { self.animateGeometry(luaToAnimation(animation, "Element.animateGeometry")); });
}

} // namespace Hyprtoolkit::Lua
