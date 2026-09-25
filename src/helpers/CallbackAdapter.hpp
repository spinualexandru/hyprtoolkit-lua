#pragma once

#include <cstdio>
#include <functional>
#include <memory>
#include <optional>
#include <sol/sol.hpp>
#include <string>
#include <string_view>
#include <type_traits>
#include <utility>

namespace Hyprtoolkit::Lua {

inline void reportLuaCallbackError(std::string_view context, const char* message) {
    fprintf(stderr, "[hyprtoolkit-lua] %.*s: %s\n", static_cast<int>(context.size()), context.data(), message);
}

// Hyprtoolkit keeps Lua callbacks in objects whose lifetime the Lua state does not control. The
// backend is a process-wide singleton that upstream tears down from an atexit handler, after the
// state has been closed, and its event loop destroys whatever idle, timer and fd callbacks are
// still pending. Each lua_State therefore carries a liveness flag that C++-held callbacks check
// before touching it.
struct SLuaStateLiveness {
    bool alive = true;
};

// Lives in the Lua registry, so lua_close finalizes it and marks the state dead before freeing it.
class CLuaStateLivenessToken {
  public:
    CLuaStateLivenessToken()                                         = default;
    CLuaStateLivenessToken(CLuaStateLivenessToken&&)                 = default;
    CLuaStateLivenessToken& operator=(CLuaStateLivenessToken&&)      = default;
    CLuaStateLivenessToken(const CLuaStateLivenessToken&)            = delete;
    CLuaStateLivenessToken& operator=(const CLuaStateLivenessToken&) = delete;

    ~CLuaStateLivenessToken() {
        if (m_liveness)
            m_liveness->alive = false;
    }

    std::shared_ptr<const SLuaStateLiveness> liveness() const {
        return m_liveness;
    }

  private:
    std::shared_ptr<SLuaStateLiveness> m_liveness = std::make_shared<SLuaStateLiveness>();
};

inline constexpr const char* LUA_STATE_LIVENESS_REGISTRY_KEY = "hyprtoolkit-lua.liveness";

inline std::shared_ptr<const SLuaStateLiveness> luaStateLiveness(lua_State* state) {
    sol::table  registry = sol::state_view(state).registry();
    sol::object token    = registry[LUA_STATE_LIVENESS_REGISTRY_KEY];
    if (!token.is<CLuaStateLivenessToken>()) {
        registry[LUA_STATE_LIVENESS_REGISTRY_KEY] = CLuaStateLivenessToken{};
        token                                     = registry[LUA_STATE_LIVENESS_REGISTRY_KEY];
    }
    return token.as<const CLuaStateLivenessToken&>().liveness();
}

// A Lua function stored by Hyprtoolkit. Never capture a sol::protected_function in an upstream
// callback directly; wrap it in this instead.
//  - Once the state is closed, call() returns std::nullopt without touching Lua, and the registry
//    reference is abandoned instead of released (lua_close has already freed the registry).
//  - Copies share one registry reference, so upstream copying a std::function never touches Lua.
//  - The reference is held on the main thread, so a callback registered from a coroutine does not
//    dangle once that coroutine is collected.
class CLuaCallback {
  public:
    explicit CLuaCallback(sol::protected_function function) {
        auto liveness = luaStateLiveness(function.lua_state());
        m_state       = std::make_shared<SState>(sol::main_protected_function{std::move(function)}, std::move(liveness));
    }

    bool alive() const {
        return m_state && m_state->liveness->alive;
    }

    template <typename... Args>
    std::optional<sol::protected_function_result> call(Args&&... args) const {
        if (!alive())
            return std::nullopt;
        return m_state->function(std::forward<Args>(args)...);
    }

  private:
    struct SState {
        SState(sol::main_protected_function function_, std::shared_ptr<const SLuaStateLiveness> liveness_) :
            function(std::move(function_)), liveness(std::move(liveness_)) {}
        SState(const SState&)            = delete;
        SState& operator=(const SState&) = delete;

        ~SState() {
            if (!liveness->alive)
                function.abandon();
        }

        sol::main_protected_function             function;
        std::shared_ptr<const SLuaStateLiveness> liveness;
    };

    std::shared_ptr<SState> m_state;
};

template <typename... Args>
void invokeLuaCallback(const CLuaCallback& callback, std::string_view context, Args&&... args) {
    std::optional<sol::protected_function_result> result = callback.call(std::forward<Args>(args)...);
    if (!result || result->valid())
        return;

    const sol::error error = *result;
    reportLuaCallbackError(context, error.what());
}

template <typename Ret, typename... Args>
std::function<Ret(Args...)> luaToCallback(sol::protected_function fn, std::string context) {
    return [callback = CLuaCallback{std::move(fn)}, context = std::move(context)](Args... args) -> Ret {
        std::optional<sol::protected_function_result> result = callback.call(args...);
        if (!result || !result->valid()) {
            if (result) {
                const sol::error error = *result;
                reportLuaCallbackError(context, error.what());
            }
            if constexpr (!std::is_void_v<Ret>) {
                return Ret{};
            }
        } else {
            if constexpr (!std::is_void_v<Ret>) {
                return result->template get<Ret>();
            }
        }
    };
}

template <typename... Args>
std::function<void(Args...)> luaToVoidCallback(sol::protected_function fn, std::string context) {
    return [callback = CLuaCallback{std::move(fn)}, context = std::move(context)](Args... args) {
        invokeLuaCallback(callback, context, args...);
    };
}

} // namespace Hyprtoolkit::Lua
