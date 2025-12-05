#include <hyprtoolkit-lua/LuaBindings.hpp>
#include <iostream>

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <script.lua> [args...]" << std::endl;
        return 1;
    }

    auto luaState = Hyprtoolkit::Lua::createLuaState();

    // Set up the arg table (Lua standard: arg[0] = script, arg[1..n] = arguments)
    sol::table argTable = luaState->lua().create_table();
    argTable[0] = argv[1];  // Script name
    for (int i = 2; i < argc; ++i) {
        argTable[i - 1] = argv[i];  // Additional arguments
    }
    luaState->lua()["arg"] = argTable;

    auto result = luaState->doFile(argv[1]);
    if (!result.valid()) {
        sol::error err = result;
        std::cerr << "Lua error: " << err.what() << std::endl;
        return 1;
    }

    return 0;
}
