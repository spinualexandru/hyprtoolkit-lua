#pragma once

#include <cstdio>
#include <functional>
#include <sol/sol.hpp>
#include <string>
#include <string_view>
#include <type_traits>
#include <utility>

namespace Hyprtoolkit::Lua {

inline void reportLuaCallbackError(std::string_view context, const char* message) {
    fprintf(stderr, "[hyprtoolkit-lua] %.*s: %s\n", static_cast<int>(context.size()), context.data(), message);
}

template <typename... Args>
void invokeLuaCallback(const sol::protected_function& fn, std::string_view context, Args&&... args) {
    sol::protected_function_result result = fn(std::forward<Args>(args)...);
    if (result.valid())
        return;

    const sol::error error = result;
    reportLuaCallbackError(context, error.what());
}

template <typename Ret, typename... Args>
std::function<Ret(Args...)> luaToCallback(sol::protected_function fn, std::string context) {
    return [fn = std::move(fn), context = std::move(context)](Args... args) -> Ret {
        sol::protected_function_result result = fn(args...);
        if (!result.valid()) {
            const sol::error error = result;
            reportLuaCallbackError(context, error.what());
            if constexpr (!std::is_void_v<Ret>) {
                return Ret{};
            }
        } else {
            if constexpr (!std::is_void_v<Ret>) {
                return result.get<Ret>();
            }
        }
    };
}

template <typename... Args>
std::function<void(Args...)> luaToVoidCallback(sol::protected_function fn, std::string context) {
    return [fn = std::move(fn), context = std::move(context)](Args... args) {
        invokeLuaCallback(fn, context, args...);
    };
}

} // namespace Hyprtoolkit::Lua
