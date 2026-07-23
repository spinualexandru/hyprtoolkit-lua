#pragma once

#include <hyprtoolkit/palette/Color.hpp>
#include <sol/sol.hpp>

#include <functional>
#include <optional>
#include <string>
#include <string_view>

#include "CallbackAdapter.hpp"

namespace Hyprtoolkit::Lua {

using colorFn = std::function<CHyprColor()>;

inline colorFn luaToColorFn(const sol::object& obj, std::string_view context = "color callback") {
    if (obj.is<CHyprColor>()) {
        const CHyprColor color = obj.as<CHyprColor>();
        return [color]() {
            return color;
        };
    }

    if (obj.is<sol::protected_function>()) {
        sol::protected_function function = obj.as<sol::protected_function>();
        return [function = std::move(function), context = std::string{context}]() -> CHyprColor {
            sol::protected_function_result result = function();
            if (!result.valid()) {
                const sol::error error = result;
                reportLuaCallbackError(context, error.what());
                return CHyprColor{0.F, 0.F, 0.F, 1.F};
            }

            try {
                return result.get<CHyprColor>();
            } catch (const std::exception& error) {
                reportLuaCallbackError(context, error.what());
                return CHyprColor{0.F, 0.F, 0.F, 1.F};
            }
        };
    }

    throw sol::error("expected a Color or function returning Color");
}

inline std::optional<colorFn> luaToOptionalColorFn(const sol::object& obj, std::string_view context = "color callback") {
    if (obj.is<sol::nil_t>() || !obj.valid())
        return std::nullopt;
    return luaToColorFn(obj, context);
}

} // namespace Hyprtoolkit::Lua
