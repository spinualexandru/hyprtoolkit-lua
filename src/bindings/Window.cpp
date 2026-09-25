#include <hyprtoolkit/core/Output.hpp>
#include <hyprtoolkit/element/Element.hpp>
#include <hyprtoolkit/window/Window.hpp>
#include <sol/sol.hpp>

#include "../helpers/CallbackAdapter.hpp"
#include "../helpers/ElementAdapter.hpp"
#include "../helpers/SignalConnection.hpp"
#include "../helpers/SmartPtrAdapter.hpp"

using namespace Hyprutils::Math;
using namespace Hyprutils::Memory;

namespace Hyprtoolkit::Lua {

void registerLayerConstants(sol::table& module) {
    sol::state_view lua(module.lua_state());
    module["Layer"] = lua.create_table_with("BACKGROUND", 0, "BOTTOM", 1, "TOP", 2, "OVERLAY", 3);
    module["LayerAnchor"] = lua.create_table_with("NONE", 0, "TOP", 1, "BOTTOM", 2, "LEFT", 4, "RIGHT", 8);
    module["KeyboardInteractivity"] = lua.create_table_with("NONE", 0, "EXCLUSIVE", 1, "ON_DEMAND", 2);
}

void registerWindow(sol::table& module) {
    module.new_enum<eWindowType>(
        "WindowType", {{"TOPLEVEL", HT_WINDOW_TOPLEVEL}, {"POPUP", HT_WINDOW_POPUP}, {"LAYER", HT_WINDOW_LAYER}, {"LOCK_SURFACE", HT_WINDOW_LOCK_SURFACE}});
    module.new_enum<eResizeEdge>(
        "ResizeEdge",
        {{"NONE", HT_RESIZE_EDGE_NONE}, {"TOP", HT_RESIZE_EDGE_TOP}, {"BOTTOM", HT_RESIZE_EDGE_BOTTOM}, {"LEFT", HT_RESIZE_EDGE_LEFT},
         {"TOP_LEFT", HT_RESIZE_EDGE_TOP_LEFT}, {"BOTTOM_LEFT", HT_RESIZE_EDGE_BOTTOM_LEFT}, {"RIGHT", HT_RESIZE_EDGE_RIGHT},
         {"TOP_RIGHT", HT_RESIZE_EDGE_TOP_RIGHT}, {"BOTTOM_RIGHT", HT_RESIZE_EDGE_BOTTOM_RIGHT}});
    registerLayerConstants(module);

    module.new_usertype<CWindowBuilder>(
        "WindowBuilder", sol::no_constructor, "begin", &CWindowBuilder::begin, "type", &CWindowBuilder::type, "appTitle",
        [](CSharedPointer<CWindowBuilder> self, const std::string& title) { return self->appTitle(std::string{title}); }, "appClass",
        [](CSharedPointer<CWindowBuilder> self, const std::string& appClass) { return self->appClass(std::string{appClass}); }, "preferredSize",
        &CWindowBuilder::preferredSize, "minSize", &CWindowBuilder::minSize, "maxSize", &CWindowBuilder::maxSize, "resizable", &CWindowBuilder::resizable, "autosize",
        &CWindowBuilder::autosize, "preferredOutput",
        [](CSharedPointer<CWindowBuilder> self, const CSharedPointer<IOutput>& output) { return self->prefferedOutput(output); }, "marginTopLeft",
        &CWindowBuilder::marginTopLeft, "marginBottomRight", &CWindowBuilder::marginBottomRight, "layer", &CWindowBuilder::layer, "anchor", &CWindowBuilder::anchor,
        "exclusiveEdge", &CWindowBuilder::exclusiveEdge, "exclusiveZone", &CWindowBuilder::exclusiveZone, "kbInteractive", &CWindowBuilder::kbInteractive,
        "inhibitShortcuts", &CWindowBuilder::inhibitShortcuts, "parent", &CWindowBuilder::parent, "pos", &CWindowBuilder::pos, "commence", &CWindowBuilder::commence);

    module.new_usertype<IWindow>(
        "Window", sol::no_constructor, "pixelSize", &IWindow::pixelSize, "scale", &IWindow::scale, "close", &IWindow::close, "open", &IWindow::open, "cursorPos",
        &IWindow::cursorPos, "setSize", &IWindow::setSize, "startInteractiveResize", &IWindow::startInteractiveResize, "rootElement",
        sol::property([](IWindow& self) { return self.m_rootElement; },
                      [](IWindow& self, const sol::object& root) { self.m_rootElement = luaToElement(root); }),
        "onResized",
        [](IWindow& self, sol::protected_function callback) {
            auto listener = self.m_events.resized.listen([callback = CLuaCallback{std::move(callback)}](Vector2D size) {
                invokeLuaCallback(callback, "Window.onResized", size);
            });
            return makeShared<CSignalConnection>(std::move(listener));
        },
        "onCloseRequest",
        [](IWindow& self, sol::protected_function callback) {
            auto listener = self.m_events.closeRequest.listen([callback = CLuaCallback{std::move(callback)}]() {
                invokeLuaCallback(callback, "Window.onCloseRequest");
            });
            return makeShared<CSignalConnection>(std::move(listener));
        },
        "onPopupClosed",
        [](IWindow& self, sol::protected_function callback) {
            auto listener = self.m_events.popupClosed.listen([callback = CLuaCallback{std::move(callback)}]() {
                invokeLuaCallback(callback, "Window.onPopupClosed");
            });
            return makeShared<CSignalConnection>(std::move(listener));
        },
        "onLayerClosed",
        [](IWindow& self, sol::protected_function callback) {
            auto listener = self.m_events.layerClosed.listen([callback = CLuaCallback{std::move(callback)}]() {
                invokeLuaCallback(callback, "Window.onLayerClosed");
            });
            return makeShared<CSignalConnection>(std::move(listener));
        },
        "onKeyboardKey",
        [](IWindow& self, sol::protected_function callback) {
            auto listener = self.m_events.keyboardKey.listen([callback = CLuaCallback{std::move(callback)}](const Input::SKeyboardKeyEvent& event) {
                invokeLuaCallback(callback, "Window.onKeyboardKey", event);
            });
            return makeShared<CSignalConnection>(std::move(listener));
        });
}

} // namespace Hyprtoolkit::Lua
