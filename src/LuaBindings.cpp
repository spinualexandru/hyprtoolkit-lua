#include <hyprtoolkit-lua/LuaBindings.hpp>

#include "bindings/Bindings.hpp"
#include "helpers/SmartPtrAdapter.hpp"

using namespace Hyprutils::Memory;

namespace Hyprtoolkit::Lua {

#ifndef HYPRTOOLKIT_LUA_VERSION
#define HYPRTOOLKIT_LUA_VERSION "0.2.0"
#endif

#ifndef HYPRTOOLKIT_LUA_UPSTREAM_COMMIT
#define HYPRTOOLKIT_LUA_UPSTREAM_COMMIT "67d9012d7d3a902a6a37e313fbfaf56ce7d3c53e"
#endif

static constexpr const char* MODULE_NAME         = "hyprtoolkit";
static constexpr const char* MODULE_REGISTRY_KEY = "hyprtoolkit-lua.module";

void registerAllBindings(sol::state& lua) {
    sol::table registry = lua.registry();
    sol::object cached  = registry[MODULE_REGISTRY_KEY];

    sol::table module;
    if (cached.valid() && cached.get_type() == sol::type::table) {
        module = cached.as<sol::table>();
    } else {
        module                        = lua.create_table();
        module["VERSION"]             = HYPRTOOLKIT_LUA_VERSION;
        module["UPSTREAM_API_COMMIT"] = HYPRTOOLKIT_LUA_UPSTREAM_COMMIT;

        registerTypes(module);
        registerCore(module);
        registerElement(module);
        registerElementBuilders(module);
        registerWindow(module);

        registry[MODULE_REGISTRY_KEY] = module;
    }

    sol::object packageObject = lua["package"];
    if (!packageObject.valid() || packageObject.get_type() != sol::type::table)
        throw std::runtime_error("registerAllBindings requires Lua's package library");

    sol::table package = packageObject.as<sol::table>();
    sol::table preload = package["preload"];
    preload[MODULE_NAME] = [module]() {
        return module;
    };
}

CSharedPointer<CLuaState> createLuaState() {
    auto state = makeShared<CLuaState>();
    state->openLibs();
    registerAllBindings(state->lua());
    return state;
}

} // namespace Hyprtoolkit::Lua
