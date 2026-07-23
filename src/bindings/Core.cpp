#include <hyprtoolkit/core/Backend.hpp>
#include <hyprtoolkit/core/LogTypes.hpp>
#include <hyprtoolkit/core/Output.hpp>
#include <hyprtoolkit/core/SessionLock.hpp>
#include <hyprtoolkit/core/Timer.hpp>
#include <hyprtoolkit/system/Icons.hpp>
#include <sol/sol.hpp>

#include "../helpers/CallbackAdapter.hpp"
#include "../helpers/SignalConnection.hpp"
#include "../helpers/SmartPtrAdapter.hpp"

using namespace Hyprutils::Memory;

namespace Hyprtoolkit::Lua {

void registerSignalConnection(sol::table& module) {
    module.new_usertype<CSignalConnection>("SignalConnection", sol::no_constructor, "connected", &CSignalConnection::connected, "disconnect", &CSignalConnection::disconnect);
}

void registerTimer(sol::table& module) {
    module.new_usertype<CTimer>(
        "Timer", sol::no_constructor, "cancel", &CTimer::cancel, "passed", &CTimer::passed, "canForceUpdate", &CTimer::canForceUpdate, "leftMs", &CTimer::leftMs, "cancelled",
        &CTimer::cancelled, "updateTimeout", [](CTimer& self, double timeoutMs) {
            self.updateTimeout(std::chrono::milliseconds{static_cast<int64_t>(timeoutMs)});
        });
}

void registerOutput(sol::table& module) {
    module.new_usertype<IOutput>(
        "Output", sol::no_constructor, "handle", &IOutput::handle, "port", &IOutput::port, "desc", &IOutput::desc, "fps", &IOutput::fps, "onRemoved",
        [](IOutput& self, sol::protected_function callback) {
            auto listener = self.m_events.removed.listen([callback = std::move(callback)]() {
                invokeLuaCallback(callback, "Output.onRemoved");
            });
            return makeShared<CSignalConnection>(std::move(listener));
        });
}

void registerSessionLock(sol::table& module) {
    module.new_enum<eSessionLockError>(
        "SessionLockError", {{"PLATFORM_UNINITIALIZED", LOCK_ERROR_PLATFORM_UNINITIALIZED}, {"DENIED", LOCK_ERROR_DENIED}});

    module.new_usertype<ISessionLockState>(
        "SessionLockState", sol::no_constructor, "unlock", &ISessionLockState::unlock, "onFinished",
        [](ISessionLockState& self, sol::protected_function callback) {
            auto listener = self.m_events.finished.listen([callback = std::move(callback)]() {
                invokeLuaCallback(callback, "SessionLockState.onFinished");
            });
            return makeShared<CSignalConnection>(std::move(listener));
        });
}

void registerSystemIcons(sol::table& module) {
    module.new_usertype<ISystemIconDescription>("SystemIconDescription", sol::no_constructor, "exists", &ISystemIconDescription::exists, "scalable",
                                                &ISystemIconDescription::scalable);
    module.new_usertype<ISystemIconFactory>("SystemIconFactory", sol::no_constructor, "lookupIcon", &ISystemIconFactory::lookupIcon);
}

void registerBackend(sol::table& module) {
    module.new_enum<eLogLevel>(
        "LogLevel", {{"TRACE", HT_LOG_TRACE}, {"DEBUG", HT_LOG_DEBUG}, {"WARNING", HT_LOG_WARNING}, {"ERROR", HT_LOG_ERROR}, {"CRITICAL", HT_LOG_CRITICAL}});

    module.new_usertype<IBackend>(
        "Backend", sol::no_constructor, "create", &IBackend::create, "destroy", &IBackend::destroy, "enterLoop", &IBackend::enterLoop, "getPalette", &IBackend::getPalette,
        "systemIcons", &IBackend::systemIcons, "getOutputs",
        [](IBackend& self, sol::this_state state) {
            sol::table outputs = sol::state_view(state).create_table();
            const auto values  = self.getOutputs();
            for (size_t index = 0; index < values.size(); ++index)
                outputs[index + 1] = values[index];
            return outputs;
        },
        "setLogCallback",
        [](IBackend& self, sol::protected_function callback) {
            self.setLogFn([callback = std::move(callback)](eLogLevel level, const std::string& message) {
                invokeLuaCallback(callback, "Backend.setLogCallback", level, message);
            });
        },
        "addTimer",
        [](CSharedPointer<IBackend> self, double timeoutMs, sol::protected_function callback, sol::optional<bool> force) {
            return self->addTimer(
                std::chrono::milliseconds{static_cast<int64_t>(timeoutMs)},
                [callback = std::move(callback)](CAtomicSharedPointer<CTimer> timer, void*) {
                    invokeLuaCallback(callback, "Backend.addTimer", timer);
                },
                nullptr, force.value_or(false));
        },
        "addIdle",
        [](IBackend& self, sol::protected_function callback) {
            self.addIdle([callback = std::move(callback)]() {
                invokeLuaCallback(callback, "Backend.addIdle");
            });
        },
        "addFd",
        [](IBackend& self, int fd, sol::protected_function callback) {
            self.addFd(fd, [callback = std::move(callback)]() {
                invokeLuaCallback(callback, "Backend.addFd");
            });
        },
        "removeFd", &IBackend::removeFd, "acquireSessionLock",
        [](IBackend& self, sol::this_state state) {
            sol::state_view lua(state);
            auto result = self.aquireSessionLock();
            if (result)
                return std::make_tuple(sol::make_object(lua, *result), sol::make_object(lua, sol::nil));
            return std::make_tuple(sol::make_object(lua, sol::nil), sol::make_object(lua, result.error()));
        },
        "onOutputAdded",
        [](IBackend& self, sol::protected_function callback) {
            auto listener = self.m_events.outputAdded.listen([callback = std::move(callback)](const CSharedPointer<IOutput>& output) {
                invokeLuaCallback(callback, "Backend.onOutputAdded", output);
            });
            return makeShared<CSignalConnection>(std::move(listener));
        });
}

void registerCore(sol::table& module) {
    registerSignalConnection(module);
    registerTimer(module);
    registerOutput(module);
    registerSessionLock(module);
    registerSystemIcons(module);
    registerBackend(module);
}

} // namespace Hyprtoolkit::Lua
